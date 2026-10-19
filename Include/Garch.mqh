//+------------------------------------------------------------------+
//| Garch.mqh                                                        |
//| GARCH(p,q): variancia condicional dos residuos do ARIMA.         |
//|                                                                  |
//|   sigma2(t) = omega + soma alfa_i e2(t-i) + soma beta_j sigma2(t-j)
//|                                                                  |
//| Maxima verossimilhanca pelo MinBLEIC da ALGLIB, com as restricoes|
//| omega > 0, alfa e beta >= 0 e soma(alfa) + soma(beta) < 1 dentro |
//| do otimizador. O otimizador ve omega / variancia amostral, que   |
//| tem a mesma ordem de grandeza de alfa e beta.                    |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_GARCH_MQH
#define ALGOTRADINGLAB_GARCH_MQH

#include <Math\Alglib\alglib.mqh>
#include "Estatistica.mqh"
#include "GarchDistribuicao.mqh"

//--- O que a funcao objetivo precisa ler (a ALGLIB a chama com um CObject)
class CDadosGarch : public CObject
  {
public:
   double            erros_quadrado[];
   int               tamanho;
   int               p;
   int               q;
   int               inicio;               // primeiro periodo avaliado
   double            variancia_amostral;
   int               distribuicao;         // ENUM_DISTRIBUICAO_GARCH

                     CDadosGarch(void) : tamanho(0), p(1), q(1), inicio(1), variancia_amostral(0.0),
                                         distribuicao(DISTRIBUICAO_NORMAL) {}
                    ~CDadosGarch(void) { ArrayFree(erros_quadrado); }
  };

//--- Menos a log-verossimilhanca. Parametros: omega relativo, alfas, betas e, com a t, eta = 1/nu.
double MenosLogVerossimilhancaGarch(CDadosGarch &dados, const double &parametros[])
  {
   int n = dados.tamanho;
   int p = dados.p;
   int q = dados.q;
   bool student = (dados.distribuicao == DISTRIBUICAO_STUDENT);

   if(n <= dados.inicio || ArraySize(parametros) < 1 + p + q + (student ? 1 : 0))
      return(1.0e10);

   double graus_liberdade = 0.0, constante_student = 0.0;
   if(student)
     {
      double eta = parametros[1 + p + q];
      if(eta < GARCH_ETA_MINIMO * 0.999 || eta > GARCH_ETA_MAXIMO * 1.001 || !MathIsValidNumber(eta))
         return(1.0e10);
      graus_liberdade = 1.0 / eta;
      constante_student = ConstanteStudent(graus_liberdade);
     }

   double omega = parametros[0] * dados.variancia_amostral;
   if(omega <= 0.0 || !MathIsValidNumber(omega))
      return(1.0e10);

   double persistencia = 0.0;
   for(int i = 1; i <= p + q; i++)
     {
      if(parametros[i] < 0.0 || !MathIsValidNumber(parametros[i]))
         return(1.0e10);
      persistencia += parametros[i];
     }
   //--- O otimizador pode avaliar pontos um pouco fora da restricao linear
   if(persistencia >= 1.0)
      return(1.0e10);

   double sigma2[];
   ArrayResize(sigma2, n);
   for(int t = 0; t < dados.inicio; t++)
      sigma2[t] = dados.variancia_amostral;

   double resultado = 0.0;
   for(int t = dados.inicio; t < n; t++)
     {
      double variancia = omega;
      for(int i = 1; i <= p; i++)
         variancia += parametros[i] * dados.erros_quadrado[t - i];
      for(int j = 1; j <= q; j++)
         variancia += parametros[p + j] * sigma2[t - j];

      if(variancia <= 0.0 || !MathIsValidNumber(variancia))
         return(1.0e10);
      sigma2[t] = variancia;

      if(student)
         resultado -= LogDensidadeStudent(dados.erros_quadrado[t], variancia, graus_liberdade, constante_student);
      else
         resultado -= LogDensidadeNormal(dados.erros_quadrado[t], variancia);
     }

   return(MathIsValidNumber(resultado) ? resultado : 1.0e10);
  }

class CObjetivoGarch : public CNDimensional_Func
  {
public:
   virtual void      Func(CRowDouble &x, double &func, CObject &obj);
  };

void CObjetivoGarch::Func(CRowDouble &x, double &func, CObject &obj)
  {
   CDadosGarch *dados = dynamic_cast<CDadosGarch *>(GetPointer(obj));
   if(dados == NULL)
     {
      func = 1.0e10;
      return;
     }

   int k = x.Size();
   double parametros[];
   ArrayResize(parametros, k);
   for(int i = 0; i < k; i++)
      parametros[i] = x[i];

   func = MenosLogVerossimilhancaGarch(dados, parametros);
  }

class CGarch
  {
private:
   int      m_p;
   int      m_q;
   double   m_omega;
   double   m_alfa[];
   double   m_beta[];
   ENUM_DISTRIBUICAO_GARCH m_distribuicao;
   double   m_graus_liberdade;           // so com a t de Student

   double   m_erros[];
   double   m_erros_quadrado[];
   double   m_sigma2[];                  // variancia condicional ajustada
   double   m_variancia_amostral;
   double   m_log_verossimilhanca;
   int      m_inicio;
   int      m_tamanho;
   bool     m_ajustado;
   string   m_erro;

   int      m_iteracoes_maximas;
   double   m_passo_diferencas;

   void     RecalcularVariancias(void);

public:
                     CGarch(void);
                    ~CGarch(void);

   void     Definir(const int p, const int q);
   void     DefinirOtimizador(const int iteracoes_maximas, const double passo_diferencas = 1.0e-6);
   void     DefinirDistribuicao(const ENUM_DISTRIBUICAO_GARCH distribuicao) { m_distribuicao = distribuicao; m_ajustado = false; }

   //--- residuos do ARIMA em ordem cronologica
   bool     Ajustar(const double &residuos[]);

   //--- Um passo a frente: todos os termos ja foram observados, inclusive o ultimo residuo
   double   VolatilidadeProximoPeriodo(void) const;
   double   VolatilidadeAtual(void) const;
   bool     ObterSerieVolatilidade(double &saida[]) const;
   //--- erro / sigma: o quadrado nao deve ter autocorrelacao se o GARCH capturou a heterocedasticidade
   bool     ObterResiduosPadronizados(double &saida[]) const;

   double   Omega(void) const { return(m_omega); }
   double   Alfa(const int i) const { return((i >= 0 && i < ArraySize(m_alfa)) ? m_alfa[i] : 0.0); }
   double   Beta(const int j) const { return((j >= 0 && j < ArraySize(m_beta)) ? m_beta[j] : 0.0); }
   double   GrausLiberdade(void) const { return((m_distribuicao == DISTRIBUICAO_STUDENT) ? m_graus_liberdade : 0.0); }
   double   Persistencia(void) const;          // soma(alfa) + soma(beta)
   double   VarianciaLongoPrazo(void) const;   // omega / (1 - persistencia)
   double   LogVerossimilhanca(void) const { return(m_log_verossimilhanca); }
   int      NumParametros(void) const { return(1 + m_p + m_q + ((m_distribuicao == DISTRIBUICAO_STUDENT) ? 1 : 0)); }
   double   AIC(void) const;
   double   BIC(void) const;
   bool     Ajustado(void) const { return(m_ajustado); }
   string   UltimoErro(void) const { return(m_erro); }
   string   Descricao(void) const;
  };

CGarch::CGarch(void) : m_p(1), m_q(1), m_omega(0.0), m_distribuicao(DISTRIBUICAO_NORMAL),
                       m_graus_liberdade(0.0), m_variancia_amostral(0.0), m_log_verossimilhanca(0.0),
                       m_inicio(1), m_tamanho(0), m_ajustado(false), m_erro(""),
                       m_iteracoes_maximas(200), m_passo_diferencas(1.0e-6)
  {
   ArrayResize(m_alfa, 1);
   ArrayResize(m_beta, 1);
   ArrayInitialize(m_alfa, 0.0);
   ArrayInitialize(m_beta, 0.0);
  }

CGarch::~CGarch(void)
  {
   ArrayFree(m_alfa);
   ArrayFree(m_beta);
   ArrayFree(m_erros);
   ArrayFree(m_erros_quadrado);
   ArrayFree(m_sigma2);
  }

void CGarch::Definir(const int p, const int q)
  {
   m_p = MathMax(1, p);
   m_q = MathMax(0, q);
   ArrayResize(m_alfa, m_p);
   ArrayResize(m_beta, MathMax(1, m_q));
   ArrayInitialize(m_alfa, 0.0);
   ArrayInitialize(m_beta, 0.0);
   m_ajustado = false;
  }

void CGarch::DefinirOtimizador(const int iteracoes_maximas, const double passo_diferencas)
  {
   m_iteracoes_maximas = MathMax(10, iteracoes_maximas);
   m_passo_diferencas = (passo_diferencas > 0.0) ? passo_diferencas : 1.0e-6;
  }

bool CGarch::Ajustar(const double &residuos[])
  {
   m_ajustado = false;
   m_erro = "";

   int n = ArraySize(residuos);
   int minimo = m_p + m_q + 30;
   if(n < minimo)
     {
      m_erro = StringFormat("Residuos: %d pontos; minimo %d", n, minimo);
      return(false);
     }

   ArrayResize(m_erros, n);
   ArrayResize(m_erros_quadrado, n);
   ArrayCopy(m_erros, residuos);
   for(int i = 0; i < n; i++)
      m_erros_quadrado[i] = residuos[i] * residuos[i];

   m_tamanho = n;
   m_inicio = MathMax(1, MathMax(m_p, m_q));

   double soma = 0.0;
   for(int i = 0; i < n; i++)
      soma += m_erros_quadrado[i];
   m_variancia_amostral = soma / (double)n;
   if(m_variancia_amostral <= 0.0 || !MathIsValidNumber(m_variancia_amostral))
     {
      m_erro = "Variancia amostral dos residuos nula ou invalida";
      return(false);
     }

   CDadosGarch dados;
   ArrayResize(dados.erros_quadrado, n);
   ArrayCopy(dados.erros_quadrado, m_erros_quadrado);
   dados.tamanho = n;
   dados.p = m_p;
   dados.q = m_q;
   dados.inicio = m_inicio;
   dados.variancia_amostral = m_variancia_amostral;
   dados.distribuicao = m_distribuicao;

   bool student = (m_distribuicao == DISTRIBUICAO_STUDENT);
   int parametros_garch = 1 + m_p + m_q;
   int k = parametros_garch + (student ? 1 : 0);

   //--- Partida tipica de serie diaria: alfa ~ 0,10 e beta ~ 0,85; com a t, nu ~ 6,7
   double x[];
   ArrayResize(x, k);
   x[0] = 0.05;
   for(int i = 1; i <= m_p; i++)
      x[i] = 0.10 / (double)m_p;
   for(int j = 1; j <= m_q; j++)
      x[m_p + j] = 0.85 / (double)m_q;
   if(student)
      x[parametros_garch] = 0.15;

   double limite_inferior[], limite_superior[];
   ArrayResize(limite_inferior, k);
   ArrayResize(limite_superior, k);
   limite_inferior[0] = 1.0e-8;
   limite_superior[0] = 10.0;
   for(int i = 1; i < parametros_garch; i++)
     {
      limite_inferior[i] = 0.0;
      limite_superior[i] = 1.0;
     }
   if(student)
     {
      limite_inferior[parametros_garch] = GARCH_ETA_MINIMO;
      limite_superior[parametros_garch] = GARCH_ETA_MAXIMO;
     }

   //--- soma(alfa) + soma(beta) <= 0,9999: estacionariedade da variancia
   CMatrixDouble restricao(1, k + 1);
   for(int i = 0; i <= k; i++)
      restricao.Set(0, i, 0.0);
   for(int i = 1; i < parametros_garch; i++)
      restricao.Set(0, i, 1.0);
   restricao.Set(0, k, 0.9999);
   int tipo_restricao[];
   ArrayResize(tipo_restricao, 1);
   tipo_restricao[0] = -1;   // menor ou igual

   //--- Gradiente por diferencas finitas (CreateF): sem derivada escrita a mao
   CMinBLEICStateShell estado;
   CMinBLEICReportShell relatorio;
   CObjetivoGarch objetivo;
   CNDimensional_Rep repositor;

   CAlglib::MinBLEICCreateF(k, x, m_passo_diferencas, estado);
   CAlglib::MinBLEICSetBC(estado, limite_inferior, limite_superior);
   CAlglib::MinBLEICSetLC(estado, restricao, tipo_restricao, 1);
   CAlglib::MinBLEICSetInnerCond(estado, 0.0, 0.0, 1.0e-8);
   CAlglib::MinBLEICSetOuterCond(estado, 1.0e-8, 1.0e-8);
   CAlglib::MinBLEICSetMaxIts(estado, m_iteracoes_maximas);
   CAlglib::MinBLEICOptimize(estado, objetivo, repositor, false, dados);

   double x_final[];
   CAlglib::MinBLEICResults(estado, x_final, relatorio);
   int codigo = relatorio.GetTerminationType();
   if(codigo <= 0 || ArraySize(x_final) < k)
     {
      m_erro = StringFormat("Otimizador falhou (codigo %d)", codigo);
      return(false);
     }

   m_omega = x_final[0] * m_variancia_amostral;
   ArrayResize(m_alfa, m_p);
   for(int i = 0; i < m_p; i++)
      m_alfa[i] = x_final[1 + i];
   ArrayResize(m_beta, MathMax(1, m_q));
   ArrayInitialize(m_beta, 0.0);
   for(int j = 0; j < m_q; j++)
      m_beta[j] = x_final[1 + m_p + j];

   if(m_omega <= 0.0 || !MathIsValidNumber(m_omega))
     {
      m_erro = "Omega estimado invalido";
      return(false);
     }

   m_graus_liberdade = 0.0;
   if(student)
     {
      double eta = x_final[parametros_garch];
      if(eta <= 0.0 || !MathIsValidNumber(eta))
        {
         m_erro = "Graus de liberdade estimados invalidos";
         return(false);
        }
      m_graus_liberdade = 1.0 / eta;
     }

   RecalcularVariancias();
   m_ajustado = true;
   return(true);
  }

void CGarch::RecalcularVariancias(void)
  {
   ArrayResize(m_sigma2, m_tamanho);
   for(int t = 0; t < m_inicio; t++)
      m_sigma2[t] = m_variancia_amostral;

   bool student = (m_distribuicao == DISTRIBUICAO_STUDENT && m_graus_liberdade > 2.0);
   double constante_student = student ? ConstanteStudent(m_graus_liberdade) : 0.0;
   double log_verossimilhanca = 0.0;

   for(int t = m_inicio; t < m_tamanho; t++)
     {
      double variancia = m_omega;
      for(int i = 1; i <= m_p; i++)
         variancia += m_alfa[i - 1] * m_erros_quadrado[t - i];
      for(int j = 1; j <= m_q; j++)
         variancia += m_beta[j - 1] * m_sigma2[t - j];
      m_sigma2[t] = MathMax(variancia, 1.0e-300);

      if(student)
         log_verossimilhanca += LogDensidadeStudent(m_erros_quadrado[t], m_sigma2[t], m_graus_liberdade, constante_student);
      else
         log_verossimilhanca += LogDensidadeNormal(m_erros_quadrado[t], m_sigma2[t]);
     }

   m_log_verossimilhanca = log_verossimilhanca;
  }

double CGarch::VolatilidadeProximoPeriodo(void) const
  {
   if(!m_ajustado)
      return(0.0);

   double variancia = m_omega;
   for(int i = 1; i <= m_p; i++)
      variancia += m_alfa[i - 1] * m_erros_quadrado[m_tamanho - i];
   for(int j = 1; j <= m_q; j++)
      variancia += m_beta[j - 1] * m_sigma2[m_tamanho - j];

   return(MathSqrt(MathMax(variancia, 1.0e-300)));
  }

double CGarch::VolatilidadeAtual(void) const
  {
   int n = ArraySize(m_sigma2);
   if(!m_ajustado || n <= 0)
      return(0.0);
   return(MathSqrt(m_sigma2[n - 1]));
  }

bool CGarch::ObterSerieVolatilidade(double &saida[]) const
  {
   if(!m_ajustado)
      return(false);

   int n = ArraySize(m_sigma2) - m_inicio;
   if(n <= 0)
      return(false);

   ArrayResize(saida, n);
   for(int i = 0; i < n; i++)
      saida[i] = MathSqrt(m_sigma2[m_inicio + i]);
   return(true);
  }

bool CGarch::ObterResiduosPadronizados(double &saida[]) const
  {
   if(!m_ajustado)
      return(false);

   int n = m_tamanho - m_inicio;
   if(n <= 0)
      return(false);

   ArrayResize(saida, n);
   for(int i = 0; i < n; i++)
     {
      int t = m_inicio + i;
      double desvio = MathSqrt(m_sigma2[t]);
      saida[i] = (desvio > 0.0) ? m_erros[t] / desvio : 0.0;
     }
   return(true);
  }

double CGarch::Persistencia(void) const
  {
   double soma = 0.0;
   for(int i = 0; i < m_p; i++)
      soma += m_alfa[i];
   for(int j = 0; j < m_q; j++)
      soma += m_beta[j];
   return(soma);
  }

double CGarch::VarianciaLongoPrazo(void) const
  {
   double persistencia = Persistencia();
   if(persistencia >= 1.0 || persistencia < 0.0)
      return(m_variancia_amostral);
   return(m_omega / (1.0 - persistencia));
  }

double CGarch::AIC(void) const
  {
   if(!m_ajustado)
      return(DBL_MAX);
   return(CalcularAIC(m_log_verossimilhanca, NumParametros()));
  }

double CGarch::BIC(void) const
  {
   if(!m_ajustado)
      return(DBL_MAX);
   return(CalcularBIC(m_log_verossimilhanca, NumParametros(), m_tamanho - m_inicio));
  }

string CGarch::Descricao(void) const
  {
   string texto = StringFormat("GARCH(%d,%d)", m_p, m_q);
   if(!m_ajustado)
      return(texto + " [nao ajustado: " + m_erro + "]");

   texto += StringFormat(" omega=%.10f", m_omega);
   for(int i = 0; i < m_p; i++)
      texto += StringFormat(" alpha%d=%.6f", i + 1, m_alfa[i]);
   for(int j = 0; j < m_q; j++)
      texto += StringFormat(" beta%d=%.6f", j + 1, m_beta[j]);
   if(m_distribuicao == DISTRIBUICAO_STUDENT)
      texto += StringFormat(" nu=%.3f", m_graus_liberdade);
   texto += StringFormat(" | persist=%.6f volLP=%.6f logL=%.3f AIC=%.3f",
                         Persistencia(), MathSqrt(VarianciaLongoPrazo()), m_log_verossimilhanca, AIC());
   return(texto);
  }

#endif
