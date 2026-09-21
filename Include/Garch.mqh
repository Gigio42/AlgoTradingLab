//+------------------------------------------------------------------+
//|                                                        Garch.mqh |
//|                            Trabalho de Graduacao - FATEC Indaiatuba|
//+------------------------------------------------------------------+
//|                                                                  |
//|  MODELO GARCH(p,q) — VARIANCIA CONDICIONAL                       |
//|                                                                  |
//|    sigma2(t) = omega + SOMA_i alpha_i * eps2(t-i)                |
//|                      + SOMA_j beta_j  * sigma2(t-j)              |
//|                                                                  |
//|    alpha — REATIVIDADE: quanto a volatilidade responde a um      |
//|            choque recente                                        |
//|    beta  — PERSISTENCIA: quanto da volatilidade de ontem         |
//|            sobrevive hoje                                        |
//|                                                                  |
//|  Restricoes obrigatorias para o modelo fazer sentido:            |
//|    omega > 0, alpha_i >= 0, beta_j >= 0   (variancia positiva)   |
//|    SOMA(alpha) + SOMA(beta) < 1           (estacionariedade)     |
//|                                                                  |
//|  ESTIMACAO: maxima verossimilhanca com restricoes, via ALGLIB    |
//|  MinBLEIC (Bound and Linear Equality-Inequality Constraints).    |
//|  As restricoes acima entram diretamente no otimizador, nao como  |
//|  "clipping" depois do passo — a diferenca importa, porque        |
//|  clipping deixa o otimizador empurrar o parametro contra a       |
//|  parede indefinidamente sem nunca convergir.                     |
//|                                                                  |
//|  ─────────────────────────────────────────────────────────────   |
//|  TRUQUE DE ESCALA (importante):                                  |
//|                                                                  |
//|  omega tem a mesma unidade da VARIANCIA dos residuos. Se os      |
//|  residuos forem log-retornos, omega ~ 1e-6; se forem reais,      |
//|  omega ~ 0,25. Ja alpha e beta sao sempre da ordem de 0,1 a 0,9. |
//|  Otimizar parametros com escalas tao diferentes e uma receita    |
//|  para nao convergir.                                             |
//|                                                                  |
//|  Por isso otimizamos omega_rel = omega / variancia_amostral, que |
//|  e adimensional e da mesma ordem de alpha e beta. O modelo fica  |
//|  numericamente identico e o otimizador passa a funcionar bem     |
//|  para qualquer ativo e qualquer escala de preco.                 |
//|  ─────────────────────────────────────────────────────────────   |
//|                                                                  |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_GARCH_MQH
#define ALGOTRADINGLAB_GARCH_MQH

#include <Math\Alglib\alglib.mqh>
#include "Estatistica.mqh"

//+------------------------------------------------------------------+
//| Dados passados ao otimizador                                     |
//+------------------------------------------------------------------+
//|  A ALGLIB chama nossa funcao objetivo com um CObject generico.   |
//|  Esta classe e o "pacote" com tudo que a funcao precisa ler.     |
//+------------------------------------------------------------------+
class CGarchDados : public CObject
  {
public:
   double            eps2[];        // residuos ao quadrado
   int               n;             // tamanho de eps2
   int               p;             // ordem ARCH
   int               q;             // ordem GARCH
   int               t0;            // primeiro indice avaliado
   double            var_amostral;  // variancia amostral dos residuos

                     CGarchDados(void) : n(0), p(1), q(1), t0(1), var_amostral(0.0) {}
                    ~CGarchDados(void) { ArrayFree(eps2); }
  };

//+------------------------------------------------------------------+
//| Funcao objetivo: -log verossimilhanca                            |
//+------------------------------------------------------------------+
//|                                                                  |
//|  NLL = 0.5 * SOMA [ ln(2pi) + ln(sigma2_t) + eps2_t/sigma2_t ]   |
//|                                                                  |
//|  MINIMIZAR a NLL equivale a MAXIMIZAR a verossimilhanca.         |
//|                                                                  |
//|  (A implementacao anterior calculava a derivada da              |
//|  log-verossimilhanca e depois SUBTRAIA lr*gradiente, o que       |
//|  minimizava a verossimilhanca em vez de maximiza-la. Aqui o      |
//|  sentido fica explicito: devolvemos a NLL e o otimizador         |
//|  minimiza.)                                                      |
//|                                                                  |
//|  par[0]     = omega_rel  (omega = omega_rel * var_amostral)      |
//|  par[1..p]  = alpha                                              |
//|  par[p+1..] = beta                                               |
//|                                                                  |
//+------------------------------------------------------------------+
double GarchNLL(CGarchDados &d, const double &par[])
  {
   int n = d.n;
   int p = d.p;
   int q = d.q;

   if(n <= d.t0 || ArraySize(par) < 1 + p + q)
      return(1.0e10);

   double omega = par[0] * d.var_amostral;

   if(omega <= 0.0 || !MathIsValidNumber(omega))
      return(1.0e10);

   double soma_coef = 0.0;
   for(int i = 1; i <= p + q; i++)
     {
      if(par[i] < 0.0 || !MathIsValidNumber(par[i]))
         return(1.0e10);
      soma_coef += par[i];
     }

   //--- Guarda extra: o otimizador respeita a restricao linear, mas
   //--- pode avaliar pontos ligeiramente fora durante a busca.
   if(soma_coef >= 1.0)
      return(1.0e10);

   //--- ── Recursao da variancia condicional ──
   double sigma2[];
   ArrayResize(sigma2, n);

   //--- Aquecimento: antes de t0 usamos a variancia amostral.
   //--- E o procedimento padrao de inicializacao do GARCH.
   for(int t = 0; t < d.t0; t++)
      sigma2[t] = d.var_amostral;

   double nll = 0.0;
   const double LN2PI = MathLog(2.0 * M_PI);

   for(int t = d.t0; t < n; t++)
     {
      double s2 = omega;

      for(int i = 1; i <= p; i++)
         s2 += par[i] * d.eps2[t - i];

      for(int j = 1; j <= q; j++)
         s2 += par[p + j] * sigma2[t - j];

      if(s2 <= 0.0 || !MathIsValidNumber(s2))
         return(1.0e10);

      sigma2[t] = s2;

      nll += 0.5 * (LN2PI + MathLog(s2) + d.eps2[t] / s2);
     }

   if(!MathIsValidNumber(nll))
      return(1.0e10);

   return(nll);
  }

//+------------------------------------------------------------------+
//| Adaptador para o otimizador da ALGLIB                            |
//+------------------------------------------------------------------+
//|  A ALGLIB invoca Func() com um CRowDouble (ver                   |
//|  CAlglib::MinBLEICOptimize em alglib.mqh), entao e esta          |
//|  sobrecarga que precisa ser redefinida.                          |
//+------------------------------------------------------------------+
class CGarchObjetivo : public CNDimensional_Func
  {
public:
   virtual void      Func(CRowDouble &x, double &func, CObject &obj);
  };

void CGarchObjetivo::Func(CRowDouble &x, double &func, CObject &obj)
  {
   CGarchDados *d = dynamic_cast<CGarchDados *>(GetPointer(obj));

   if(d == NULL)
     {
      func = 1.0e10;
      return;
     }

   int k = x.Size();
   double par[];
   ArrayResize(par, k);
   for(int i = 0; i < k; i++)
      par[i] = x[i];

   func = GarchNLL(d, par);
  }

//+------------------------------------------------------------------+
//| CGarch                                                           |
//+------------------------------------------------------------------+
class CGarch
  {
private:
   int      m_p;                  // ordem ARCH
   int      m_q;                  // ordem GARCH
   double   m_omega;
   double   m_alpha[];
   double   m_beta[];

   double   m_eps[];              // residuos usados no ajuste
   double   m_eps2[];             // residuos ao quadrado
   double   m_sigma2[];           // variancia condicional ajustada
   double   m_var_amostral;
   double   m_logL;
   int      m_t0;
   int      m_n;
   bool     m_ajustado;
   string   m_erro;

   int      m_max_iter;
   double   m_passo_diferencas;

   void     RecalcularVariancias(void);

public:
                     CGarch(void);
                    ~CGarch(void);

   void     Definir(const int p, const int q);
   void     DefinirOtimizador(const int max_iter, const double passo_dif = 1.0e-6);

   //--- Ajusta aos residuos do ARIMA (ordem cronologica)
   bool     Ajustar(const double &residuos[]);

   //--- Previsao da VARIANCIA h passos a frente
   bool     PreverVariancia(const int passos, double &saida[]);
   //--- Previsao da VOLATILIDADE (desvio padrao) h passos a frente
   bool     PreverVolatilidade(const int passos, double &saida[]);
   //--- Atalho: volatilidade prevista para o proximo periodo
   double   VolatilidadeProximoPeriodo(void);

   //--- Volatilidade condicional do ultimo periodo observado
   double   VolatilidadeAtual(void) const;

   //--- Serie historica de volatilidade condicional ajustada
   bool     ObterSerieVolatilidade(double &saida[]) const;

   //--- Residuos padronizados eps(t)/sigma(t).
   //--- Se o GARCH capturou bem a heterocedasticidade, o QUADRADO
   //--- destes residuos nao deve mais ter autocorrelacao.
   bool     ObterResiduosPadronizados(double &saida[]) const;

   double   Omega(void) const { return(m_omega); }
   double   Alpha(const int i) const { return((i >= 0 && i < ArraySize(m_alpha)) ? m_alpha[i] : 0.0); }
   double   Beta(const int j)  const { return((j >= 0 && j < ArraySize(m_beta))  ? m_beta[j]  : 0.0); }

   //--- Persistencia = SOMA(alpha) + SOMA(beta).
   //--- Proximo de 1 => choques de volatilidade demoram a dissipar.
   double   Persistencia(void) const;

   //--- Variancia de longo prazo para a qual o modelo converge:
   //---   omega / (1 - persistencia)
   double   VarianciaLongoPrazo(void) const;

   double   LogVerossimilhanca(void) const { return(m_logL); }
   int      NumParametros(void) const { return(1 + m_p + m_q); }
   double   AIC(void) const;
   double   BIC(void) const;
   bool     Ajustado(void) const { return(m_ajustado); }
   string   UltimoErro(void) const { return(m_erro); }
   int      P(void) const { return(m_p); }
   int      Q(void) const { return(m_q); }

   string   Descricao(void) const;
  };

//+------------------------------------------------------------------+
CGarch::CGarch(void) : m_p(1), m_q(1), m_omega(0.0), m_var_amostral(0.0),
                       m_logL(0.0), m_t0(1), m_n(0), m_ajustado(false),
                       m_erro(""), m_max_iter(200), m_passo_diferencas(1.0e-6)
  {
   ArrayResize(m_alpha, 1);
   ArrayResize(m_beta, 1);
   ArrayInitialize(m_alpha, 0.0);
   ArrayInitialize(m_beta, 0.0);
  }

//+------------------------------------------------------------------+
CGarch::~CGarch(void)
  {
   ArrayFree(m_alpha);
   ArrayFree(m_beta);
   ArrayFree(m_eps);
   ArrayFree(m_eps2);
   ArrayFree(m_sigma2);
  }

//+------------------------------------------------------------------+
void CGarch::Definir(const int p, const int q)
  {
   m_p = MathMax(1, p);
   m_q = MathMax(0, q);

   ArrayResize(m_alpha, m_p);
   ArrayResize(m_beta, MathMax(1, m_q));
   ArrayInitialize(m_alpha, 0.0);
   ArrayInitialize(m_beta, 0.0);

   m_ajustado = false;
  }

//+------------------------------------------------------------------+
void CGarch::DefinirOtimizador(const int max_iter, const double passo_dif)
  {
   m_max_iter = MathMax(10, max_iter);
   m_passo_diferencas = (passo_dif > 0.0) ? passo_dif : 1.0e-6;
  }

//+------------------------------------------------------------------+
//| Ajuste por maxima verossimilhanca com restricoes                 |
//+------------------------------------------------------------------+
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

   //--- Guarda os residuos e seus quadrados
   ArrayResize(m_eps, n);
   ArrayResize(m_eps2, n);
   ArrayCopy(m_eps, residuos);

   for(int i = 0; i < n; i++)
      m_eps2[i] = residuos[i] * residuos[i];

   m_n = n;
   m_t0 = MathMax(m_p, m_q);
   if(m_t0 < 1)
      m_t0 = 1;

   //--- Variancia amostral: base do truque de escala e da
   //--- inicializacao da recursao
   double soma = 0.0;
   for(int i = 0; i < n; i++)
      soma += m_eps2[i];
   m_var_amostral = soma / (double)n;

   if(m_var_amostral <= 0.0 || !MathIsValidNumber(m_var_amostral))
     {
      m_erro = "Variancia amostral dos residuos nula ou invalida";
      return(false);
     }

   //--- ── Prepara o pacote de dados para o otimizador ──
   CGarchDados dados;
   ArrayResize(dados.eps2, n);
   ArrayCopy(dados.eps2, m_eps2);
   dados.n = n;
   dados.p = m_p;
   dados.q = m_q;
   dados.t0 = m_t0;
   dados.var_amostral = m_var_amostral;

   int k = 1 + m_p + m_q;

   //--- ── Ponto inicial ──
   //--- Valores tipicos de series financeiras diarias:
   //--- persistencia alta (beta ~ 0,85) e reatividade baixa
   //--- (alpha ~ 0,10). Partir dali acelera muito a convergencia.
   double x[];
   ArrayResize(x, k);
   x[0] = 0.05;                                   // omega_rel
   for(int i = 1; i <= m_p; i++)
      x[i] = 0.10 / (double)m_p;
   for(int j = 1; j <= m_q; j++)
      x[m_p + j] = 0.85 / (double)m_q;

   //--- ── Restricoes de caixa ──
   double bndl[], bndu[];
   ArrayResize(bndl, k);
   ArrayResize(bndu, k);

   bndl[0] = 1.0e-8;   bndu[0] = 10.0;            // omega_rel > 0
   for(int i = 1; i < k; i++)
     {
      bndl[i] = 0.0;                              // alpha, beta >= 0
      bndu[i] = 1.0;
     }

   //--- ── Restricao linear: SOMA(alpha) + SOMA(beta) <= 0,9999 ──
   //--- Esta e a condicao de estacionariedade da variancia. Sem
   //--- ela o modelo pode divergir para volatilidade infinita.
   CMatrixDouble lc(1, k + 1);
   for(int i = 0; i <= k; i++)
      lc.Set(0, i, 0.0);
   for(int i = 1; i < k; i++)
      lc.Set(0, i, 1.0);        // coeficientes de alpha e beta
   lc.Set(0, k, 0.9999);        // lado direito

   int ct[];
   ArrayResize(ct, 1);
   ct[0] = -1;                  // -1 significa "<="

   //--- ── Otimiza ──
   //--- CreateF usa diferencas finitas: nao precisamos derivar o
   //--- gradiente da verossimilhanca a mao. Com apenas 3 parametros
   //--- (GARCH(1,1)) o custo e irrelevante e elimina uma fonte
   //--- classica de erro algebrico.
   CMinBLEICStateShell estado;
   CMinBLEICReportShell relatorio;
   CGarchObjetivo objetivo;
   CNDimensional_Rep repositor;

   CAlglib::MinBLEICCreateF(k, x, m_passo_diferencas, estado);
   CAlglib::MinBLEICSetBC(estado, bndl, bndu);
   CAlglib::MinBLEICSetLC(estado, lc, ct, 1);
   CAlglib::MinBLEICSetInnerCond(estado, 0.0, 0.0, 1.0e-8);
   CAlglib::MinBLEICSetOuterCond(estado, 1.0e-8, 1.0e-8);
   CAlglib::MinBLEICSetMaxIts(estado, m_max_iter);

   CAlglib::MinBLEICOptimize(estado, objetivo, repositor, false, dados);

   double x_final[];
   CAlglib::MinBLEICResults(estado, x_final, relatorio);

   int cod = relatorio.GetTerminationType();

   //--- Codigos <= 0 indicam falha; 1..5 e 7 sao terminacoes normais
   if(cod <= 0 || ArraySize(x_final) < k)
     {
      m_erro = StringFormat("Otimizador falhou (codigo %d)", cod);
      return(false);
     }

   //--- ── Extrai os parametros ──
   m_omega = x_final[0] * m_var_amostral;

   ArrayResize(m_alpha, m_p);
   for(int i = 0; i < m_p; i++)
      m_alpha[i] = x_final[1 + i];

   ArrayResize(m_beta, MathMax(1, m_q));
   ArrayInitialize(m_beta, 0.0);
   for(int j = 0; j < m_q; j++)
      m_beta[j] = x_final[1 + m_p + j];

   if(m_omega <= 0.0 || !MathIsValidNumber(m_omega))
     {
      m_erro = "Omega estimado invalido";
      return(false);
     }

   RecalcularVariancias();

   m_ajustado = true;
   return(true);
  }

//+------------------------------------------------------------------+
//| Reconstroi a serie de variancia e a verossimilhanca finais       |
//+------------------------------------------------------------------+
void CGarch::RecalcularVariancias(void)
  {
   ArrayResize(m_sigma2, m_n);

   for(int t = 0; t < m_t0; t++)
      m_sigma2[t] = m_var_amostral;

   const double LN2PI = MathLog(2.0 * M_PI);
   double logL = 0.0;

   for(int t = m_t0; t < m_n; t++)
     {
      double s2 = m_omega;

      for(int i = 1; i <= m_p; i++)
         s2 += m_alpha[i - 1] * m_eps2[t - i];

      for(int j = 1; j <= m_q; j++)
         s2 += m_beta[j - 1] * m_sigma2[t - j];

      m_sigma2[t] = MathMax(s2, 1.0e-300);

      logL += -0.5 * (LN2PI + MathLog(m_sigma2[t]) + m_eps2[t] / m_sigma2[t]);
     }

   m_logL = logL;
  }

//+------------------------------------------------------------------+
//| PREVISAO DA VARIANCIA                                            |
//+------------------------------------------------------------------+
//|                                                                  |
//|  Um passo a frente (h=1) — TODOS os termos sao conhecidos:       |
//|                                                                  |
//|    sigma2(N) = omega + SOMA alpha_i*eps2(N-i)                    |
//|                      + SOMA beta_j*sigma2(N-j)                   |
//|                                                                  |
//|  O erro eps(N-1) JA FOI OBSERVADO — e o ultimo residuo do ARIMA. |
//|  (A implementacao anterior zerava o termo ARCH na previsao       |
//|  alegando que "o erro futuro e desconhecido". Isso confundia     |
//|  eps(N), de fato desconhecido, com eps(N-1), que e dado. O       |
//|  efeito era subestimar a volatilidade de forma sistematica.)     |
//|                                                                  |
//|  Varios passos a frente (h>1) — o erro futuro entra pelo seu     |
//|  valor esperado, que e a propria variancia prevista:             |
//|                                                                  |
//|    E[eps2(N+h)] = sigma2(N+h)                                    |
//|                                                                  |
//+------------------------------------------------------------------+
bool CGarch::PreverVariancia(const int passos, double &saida[])
  {
   if(!m_ajustado || passos <= 0)
      return(false);

   int total = m_n + passos;

   //--- Series estendidas: passado observado + futuro previsto
   double eps2_ext[], sig2_ext[];
   ArrayResize(eps2_ext, total);
   ArrayResize(sig2_ext, total);

   for(int t = 0; t < m_n; t++)
     {
      eps2_ext[t] = m_eps2[t];
      sig2_ext[t] = m_sigma2[t];
     }

   for(int h = 0; h < passos; h++)
     {
      int t = m_n + h;
      double s2 = m_omega;

      for(int i = 1; i <= m_p; i++)
         s2 += m_alpha[i - 1] * eps2_ext[t - i];

      for(int j = 1; j <= m_q; j++)
         s2 += m_beta[j - 1] * sig2_ext[t - j];

      s2 = MathMax(s2, 1.0e-300);

      sig2_ext[t] = s2;
      //--- Valor esperado do quadrado do erro futuro
      eps2_ext[t] = s2;
     }

   ArrayResize(saida, passos);
   for(int h = 0; h < passos; h++)
      saida[h] = sig2_ext[m_n + h];

   return(true);
  }

//+------------------------------------------------------------------+
bool CGarch::PreverVolatilidade(const int passos, double &saida[])
  {
   double var[];
   if(!PreverVariancia(passos, var))
      return(false);

   int n = ArraySize(var);
   ArrayResize(saida, n);

   for(int i = 0; i < n; i++)
      saida[i] = MathSqrt(var[i]);

   return(true);
  }

//+------------------------------------------------------------------+
double CGarch::VolatilidadeProximoPeriodo(void)
  {
   double vol[];
   if(!PreverVolatilidade(1, vol) || ArraySize(vol) < 1)
      return(0.0);

   return(vol[0]);
  }

//+------------------------------------------------------------------+
double CGarch::VolatilidadeAtual(void) const
  {
   int n = ArraySize(m_sigma2);
   if(!m_ajustado || n <= 0)
      return(0.0);

   return(MathSqrt(m_sigma2[n - 1]));
  }

//+------------------------------------------------------------------+
bool CGarch::ObterSerieVolatilidade(double &saida[]) const
  {
   if(!m_ajustado)
      return(false);

   int n = ArraySize(m_sigma2) - m_t0;
   if(n <= 0)
      return(false);

   ArrayResize(saida, n);
   for(int i = 0; i < n; i++)
      saida[i] = MathSqrt(m_sigma2[m_t0 + i]);

   return(true);
  }

//+------------------------------------------------------------------+
bool CGarch::ObterResiduosPadronizados(double &saida[]) const
  {
   if(!m_ajustado)
      return(false);

   int n = m_n - m_t0;
   if(n <= 0)
      return(false);

   ArrayResize(saida, n);
   for(int i = 0; i < n; i++)
     {
      int t = m_t0 + i;
      double s = MathSqrt(m_sigma2[t]);
      saida[i] = (s > 0.0) ? m_eps[t] / s : 0.0;
     }

   return(true);
  }

//+------------------------------------------------------------------+
double CGarch::Persistencia(void) const
  {
   double soma = 0.0;

   for(int i = 0; i < m_p; i++)
      soma += m_alpha[i];
   for(int j = 0; j < m_q; j++)
      soma += m_beta[j];

   return(soma);
  }

//+------------------------------------------------------------------+
double CGarch::VarianciaLongoPrazo(void) const
  {
   double persist = Persistencia();

   if(persist >= 1.0 || persist < 0.0)
      return(m_var_amostral);

   return(m_omega / (1.0 - persist));
  }

//+------------------------------------------------------------------+
double CGarch::AIC(void) const
  {
   if(!m_ajustado)
      return(DBL_MAX);
   return(CalcularAIC(m_logL, NumParametros()));
  }

//+------------------------------------------------------------------+
double CGarch::BIC(void) const
  {
   if(!m_ajustado)
      return(DBL_MAX);
   return(CalcularBIC(m_logL, NumParametros(), m_n - m_t0));
  }

//+------------------------------------------------------------------+
string CGarch::Descricao(void) const
  {
   string s = StringFormat("GARCH(%d,%d)", m_p, m_q);

   if(!m_ajustado)
      return(s + " [nao ajustado: " + m_erro + "]");

   s += StringFormat(" omega=%.10f", m_omega);

   for(int i = 0; i < m_p; i++)
      s += StringFormat(" alpha%d=%.6f", i + 1, m_alpha[i]);
   for(int j = 0; j < m_q; j++)
      s += StringFormat(" beta%d=%.6f", j + 1, m_beta[j]);

   s += StringFormat(" | persist=%.6f volLP=%.6f logL=%.3f AIC=%.3f",
                     Persistencia(), MathSqrt(VarianciaLongoPrazo()),
                     m_logL, AIC());

   return(s);
  }

#endif // ALGOTRADINGLAB_GARCH_MQH
//+------------------------------------------------------------------+
