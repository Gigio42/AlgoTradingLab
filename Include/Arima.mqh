//+------------------------------------------------------------------+
//| Arima.mqh                                                        |
//| ARIMA(p,d,q): media condicional, estimada por Hannan-Rissanen.   |
//|                                                                  |
//|   z(t) = c + soma phi_i z(t-i) + soma theta_j e(t-j) + e(t)      |
//|                                                                  |
//| z e a serie diferenciada d vezes. Os erros e(t) nao sao          |
//| observados; o primeiro estagio os estima com um AR longo e o     |
//| segundo regride z contra z e e defasados. Os dois sao MQO.       |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_ARIMA_MQH
#define ALGOTRADINGLAB_ARIMA_MQH

#include "Numerico.mqh"
#include "Estatistica.mqh"
#include "ArimaVerossimilhanca.mqh"   //@omitir

//@omitir-inicio
enum ENUM_ESTIMACAO_ARIMA
  {
   ESTIMACAO_HANNAN_RISSANEN = 0,   // Hannan-Rissanen (dois estagios de MQO)
   ESTIMACAO_VEROSSIMILHANCA = 1    // Maxima verossimilhanca condicional (experimental)
  };
  //@omitir-fim

class CArima
  {
private:
   int      m_p;
   int      m_d;
   int      m_q;
   bool     m_com_constante;
   ENUM_ESTIMACAO_ARIMA m_estimacao;   //@omitir

   double   m_constante;
   double   m_phi[];
   double   m_theta[];

   double   m_serie_diferenciada[];
   double   m_residuos[];               // alinhados com a serie diferenciada (zero no aquecimento)
   double   m_ultimos_niveis[];         // fim da serie original, para desfazer a diferenciacao
   double   m_sigma2;
   double   m_log_verossimilhanca;
   int      m_inicio_recursao;          // primeiro residuo calculado
   int      m_inicio_verossimilhanca;   // primeiro residuo somado na verossimilhanca
   int      m_aquecimento_minimo;
   int      m_observacoes_efetivas;
   bool     m_ajustado;
   string   m_erro;   //@omitir

   static ENUM_ESTIMACAO_ARIMA s_estimacao_padrao;   //@omitir

   void     Diferenciar(const double &origem[], double &destino[], const int ordem);
   bool     EstimarAR(const double &z[], const int ordem, double &coeficientes[], double &residuos[]);
   bool     HannanRissanen(void);
   void     CalcularResiduos(void);
   void     CalcularVerossimilhanca(void);

public:
                     CArima(void);
                    ~CArima(void);   //@omitir

   //@omitir-inicio
   //--- Estimacao usada pelos objetos criados depois (a selecao de ordens cria um por candidato)
   static void DefinirEstimacaoPadrao(const ENUM_ESTIMACAO_ARIMA estimacao) { s_estimacao_padrao = estimacao; }
   void     DefinirEstimacao(const ENUM_ESTIMACAO_ARIMA estimacao) { m_estimacao = estimacao; }
   //@omitir-fim

   void     Definir(const int p, const int d, const int q, const bool com_constante = true);

   //--- Descarta as primeiras observacoes da verossimilhanca. A selecao de ordens usa
   //--- o mesmo valor em todos os candidatos para o AIC comparar a mesma amostra.
   void     DefinirAquecimentoMinimo(const int observacoes) { m_aquecimento_minimo = MathMax(0, observacoes); }

   //--- serie em ordem cronologica (indice 0 = mais antigo)
   bool     Ajustar(const double &serie[]);

   double   PreverDiferenciado(void);   // proximo z
   double   PreverNivel(void);          // proximo valor da serie original

   //--- Residuos sem o aquecimento: e a serie que vai para o GARCH
   bool     ObterResiduos(double &saida[]) const;
   //@omitir-inicio
   //--- Os ultimos 'quantidade' residuos dos coeficientes atuais sobre outra serie,
   //--- mais longa que a da estimacao (janela propria do GARCH)
   bool     ResiduosSobre(const double &serie[], const int quantidade, double &saida[]);
   //@omitir-fim

   double   LogVerossimilhanca(void)   const { return(m_log_verossimilhanca);  }   //@omitir
   double   Sigma2(void)               const { return(m_sigma2);               }   //@omitir
   int      ObservacoesEfetivas(void)  const { return(m_observacoes_efetivas); }   //@omitir
   int      NumParametros(void)        const { return(m_p + m_q + (m_com_constante ? 1 : 0) + 1); }
   double   AIC(void)                  const;
   double   BIC(void)                  const;   //@omitir
   string   UltimoErro(void)           const { return(m_erro); }   //@omitir

   int      P(void) const { return(m_p); }   //@omitir
   int      D(void) const { return(m_d); }
   int      Q(void) const { return(m_q); }   //@omitir
   double   Constante(void) const { return(m_constante); }   //@omitir
   double   Phi(const int i)   const { return((i >= 0 && i < ArraySize(m_phi))   ? m_phi[i]   : 0.0); }   //@omitir
   double   Theta(const int j) const { return((j >= 0 && j < ArraySize(m_theta)) ? m_theta[j] : 0.0); }   //@omitir

   //@omitir-inicio
   //--- soma |phi| < 1: condicao suficiente (nao necessaria) de estacionariedade
   bool     EstacionariedadeGarantida(void) const;
   string   Descricao(void) const;
   //@omitir-fim
  };

ENUM_ESTIMACAO_ARIMA CArima::s_estimacao_padrao = ESTIMACAO_HANNAN_RISSANEN;   //@omitir

CArima::CArima(void) : m_p(1), m_d(1), m_q(1), m_com_constante(true),
                       m_estimacao(s_estimacao_padrao),   //@omitir
                       m_constante(0.0), m_sigma2(0.0), m_log_verossimilhanca(0.0),
                       m_inicio_recursao(0), m_inicio_verossimilhanca(0), m_aquecimento_minimo(0),
                       //@apendice: m_observacoes_efetivas(0), m_ajustado(false)
                       m_observacoes_efetivas(0), m_ajustado(false), m_erro("")   //@omitir
  {
  }

//@omitir-inicio
CArima::~CArima(void)
  {
   ArrayFree(m_phi);
   ArrayFree(m_theta);
   ArrayFree(m_serie_diferenciada);
   ArrayFree(m_residuos);
   ArrayFree(m_ultimos_niveis);
  }

//@omitir-fim
void CArima::Definir(const int p, const int d, const int q, const bool com_constante)
  {
   m_p = MathMax(0, p);
   m_d = MathMax(0, MathMin(2, d));
   m_q = MathMax(0, q);
   //--- Com d = 0 o modelo descreve o nivel do log-preco, que nao tem media zero
   m_com_constante = com_constante || (m_d == 0);

   ArrayResize(m_phi, m_p);
   ArrayResize(m_theta, m_q);
   ArrayInitialize(m_phi, 0.0);
   ArrayInitialize(m_theta, 0.0);
   m_ajustado = false;
  }

void CArima::Diferenciar(const double &origem[], double &destino[], const int ordem)
  {
   ArrayResize(destino, ArraySize(origem));
   ArrayCopy(destino, origem);

   for(int vez = 0; vez < ordem; vez++)
     {
      int tamanho = ArraySize(destino);
      if(tamanho < 2)
         break;
      for(int i = 0; i < tamanho - 1; i++)
         destino[i] = destino[i + 1] - destino[i];
      ArrayResize(destino, tamanho - 1);
     }
  }

//--- AR(ordem) com constante por MQO; residuos[t] alinhado com z, zero para t < ordem
bool CArima::EstimarAR(const double &z[], const int ordem, double &coeficientes[], double &residuos[])
  {
   int tamanho = ArraySize(z);
   int observacoes = tamanho - ordem;
   int parametros = ordem + 1;

   if(ordem <= 0 || observacoes <= parametros)
      return(false);

   CMatrixDouble X(observacoes, parametros);
   double dependente[];
   ArrayResize(dependente, observacoes);

   for(int t = ordem, linha = 0; t < tamanho; t++, linha++)
     {
      dependente[linha] = z[t];
      X.Set(linha, 0, 1.0);
      for(int i = 1; i <= ordem; i++)
         X.Set(linha, i, z[t - i]);
     }

   double erros_padrao[], soma_quadrados = 0.0;
   if(!MQO(X, dependente, observacoes, parametros, coeficientes, erros_padrao, soma_quadrados, false))
      return(false);

   ArrayResize(residuos, tamanho);
   ArrayInitialize(residuos, 0.0);
   for(int t = ordem; t < tamanho; t++)
     {
      double ajuste = coeficientes[0];
      for(int i = 1; i <= ordem; i++)
         ajuste += coeficientes[i] * z[t - i];
      residuos[t] = z[t] - ajuste;
     }

   return(true);
  }

bool CArima::HannanRissanen(void)
  {
   int tamanho = ArraySize(m_serie_diferenciada);

   //--- Sem termos MA o modelo ja e uma regressao linear: um MQO basta
   if(m_q == 0)
     {
      if(m_p == 0)
        {
         m_constante = m_com_constante ? Media(m_serie_diferenciada) : 0.0;
         return(true);
        }

      int observacoes = tamanho - m_p;
      int parametros = m_p + (m_com_constante ? 1 : 0);
      if(observacoes <= parametros)
        {
         m_erro = "Serie curta demais para AR(" + IntegerToString(m_p) + ")";   //@omitir
         return(false);
        }

      CMatrixDouble X(observacoes, parametros);
      double dependente[];
      ArrayResize(dependente, observacoes);

      for(int t = m_p, linha = 0; t < tamanho; t++, linha++)
        {
         dependente[linha] = m_serie_diferenciada[t];
         int coluna = 0;
         if(m_com_constante)
            X.Set(linha, coluna++, 1.0);
         for(int i = 1; i <= m_p; i++)
            X.Set(linha, coluna++, m_serie_diferenciada[t - i]);
        }

      double coeficientes[], erros_padrao[], soma_quadrados = 0.0;
      if(!MQO(X, dependente, observacoes, parametros, coeficientes, erros_padrao, soma_quadrados, false))
        {
         m_erro = "MQO singular no ajuste AR";   //@omitir
         return(false);
        }

      int coluna = 0;
      m_constante = m_com_constante ? coeficientes[coluna++] : 0.0;
      for(int i = 0; i < m_p; i++)
         m_phi[i] = coeficientes[coluna++];
      return(true);
     }

   //--- Estagio 1: AR longo, ordem log(N)^2, para estimar os erros
   int ordem_longa = (int)MathFloor(MathPow(MathLog((double)tamanho), 2.0));
   ordem_longa = MathMax(ordem_longa, m_p + m_q + 1);
   ordem_longa = MathMin(ordem_longa, tamanho / 5);

   if(ordem_longa < 1 || tamanho - ordem_longa < m_p + m_q + 10)
     {
      m_erro = "Serie curta demais para Hannan-Rissanen";   //@omitir
      return(false);
     }

   double coeficientes_ar_longo[], erros_estimados[];
   if(!EstimarAR(m_serie_diferenciada, ordem_longa, coeficientes_ar_longo, erros_estimados))
     {
      m_erro = "Falha no estagio 1 (AR longo)";   //@omitir
      return(false);
     }

   //--- Estagio 2: z contra z defasado e erros estimados defasados
   int primeiro = MathMax(ordem_longa + m_q, m_p);
   int observacoes = tamanho - primeiro;
   int parametros = m_p + m_q + (m_com_constante ? 1 : 0);

   if(observacoes <= parametros + 5)
     {
      m_erro = "Observacoes insuficientes no estagio 2";   //@omitir
      return(false);
     }

   CMatrixDouble X(observacoes, parametros);
   double dependente[];
   ArrayResize(dependente, observacoes);

   for(int t = primeiro, linha = 0; t < tamanho; t++, linha++)
     {
      dependente[linha] = m_serie_diferenciada[t];
      int coluna = 0;
      if(m_com_constante)
         X.Set(linha, coluna++, 1.0);
      for(int i = 1; i <= m_p; i++)
         X.Set(linha, coluna++, m_serie_diferenciada[t - i]);
      for(int j = 1; j <= m_q; j++)
         X.Set(linha, coluna++, erros_estimados[t - j]);
     }

   double coeficientes[], erros_padrao[], soma_quadrados = 0.0;
   if(!MQO(X, dependente, observacoes, parametros, coeficientes, erros_padrao, soma_quadrados, false))
     {
      m_erro = "MQO singular no estagio 2";   //@omitir
      return(false);
     }

   int coluna = 0;
   m_constante = m_com_constante ? coeficientes[coluna++] : 0.0;
   for(int i = 0; i < m_p; i++)
      m_phi[i] = coeficientes[coluna++];
   for(int j = 0; j < m_q; j++)
      m_theta[j] = coeficientes[coluna++];
   return(true);
  }

//--- Residuos coerentes com os coeficientes finais (os do estagio 2 sao aproximados)
void CArima::CalcularResiduos(void)
  {
   int tamanho = ArraySize(m_serie_diferenciada);
   ArrayResize(m_residuos, tamanho);
   ArrayInitialize(m_residuos, 0.0);

   m_inicio_recursao = MathMax(m_p, m_q);
   m_inicio_verossimilhanca = MathMax(m_inicio_recursao, m_aquecimento_minimo);

   for(int t = m_inicio_recursao; t < tamanho; t++)
     {
      double ajuste = m_constante;
      for(int i = 0; i < m_p; i++)
         ajuste += m_phi[i] * m_serie_diferenciada[t - 1 - i];
      for(int j = 0; j < m_q; j++)
         ajuste += m_theta[j] * m_residuos[t - 1 - j];
      m_residuos[t] = m_serie_diferenciada[t] - ajuste;
     }
  }

//--- Gaussiana condicional com sigma2 = SQR/n: logL = -n/2 [ln(2 pi) + ln(sigma2) + 1]
void CArima::CalcularVerossimilhanca(void)
  {
   int tamanho = ArraySize(m_serie_diferenciada);
   m_observacoes_efetivas = tamanho - m_inicio_verossimilhanca;

   if(m_observacoes_efetivas <= 0)
     {
      m_sigma2 = 0.0;
      m_log_verossimilhanca = -DBL_MAX;
      return;
     }

   double soma_quadrados = 0.0;
   for(int t = m_inicio_verossimilhanca; t < tamanho; t++)
      soma_quadrados += m_residuos[t] * m_residuos[t];

   m_sigma2 = soma_quadrados / (double)m_observacoes_efetivas;
   if(m_sigma2 <= 0.0 || !MathIsValidNumber(m_sigma2))
     {
      m_log_verossimilhanca = -DBL_MAX;
      return;
     }

   m_log_verossimilhanca = -0.5 * (double)m_observacoes_efetivas *
                           (MathLog(2.0 * M_PI) + MathLog(m_sigma2) + 1.0);
  }

bool CArima::Ajustar(const double &serie[])
  {
   m_ajustado = false;
   m_erro = "";   //@omitir

   int n = ArraySize(serie);
   int minimo = m_p + m_q + m_d + 30;
   if(n < minimo)
     {
      m_erro = StringFormat("Serie com %d pontos; minimo %d", n, minimo);   //@omitir
      return(false);
     }

   ArrayResize(m_ultimos_niveis, MathMin(n, 3));
   for(int i = 0; i < ArraySize(m_ultimos_niveis); i++)
      m_ultimos_niveis[i] = serie[n - ArraySize(m_ultimos_niveis) + i];

   Diferenciar(serie, m_serie_diferenciada, m_d);
   if(ArraySize(m_serie_diferenciada) < m_p + m_q + 20)
     {
      m_erro = "Serie diferenciada curta demais";   //@omitir
      return(false);
     }

   ArrayResize(m_phi, m_p);
   ArrayResize(m_theta, m_q);
   ArrayInitialize(m_phi, 0.0);
   ArrayInitialize(m_theta, 0.0);
   m_constante = 0.0;

   if(!HannanRissanen())
      return(false);

   for(int i = 0; i < m_p; i++)
      if(!MathIsValidNumber(m_phi[i]))
        {
         m_erro = "Coeficiente AR invalido";   //@omitir
         return(false);
        }
   for(int j = 0; j < m_q; j++)
      if(!MathIsValidNumber(m_theta[j]))
        {
         m_erro = "Coeficiente MA invalido";   //@omitir
         return(false);
        }

   CalcularResiduos();
   //@omitir-inicio
   if(m_estimacao == ESTIMACAO_VEROSSIMILHANCA)
     {
      RefinarPorVerossimilhanca(m_serie_diferenciada, m_p, m_q, m_com_constante,
                                m_inicio_recursao, m_inicio_verossimilhanca,
                                m_constante, m_phi, m_theta);
      CalcularResiduos();
     }
     //@omitir-fim
   CalcularVerossimilhanca();

   if(m_log_verossimilhanca == -DBL_MAX)
     {
      m_erro = "Verossimilhanca invalida";   //@omitir
      return(false);
     }

   m_ajustado = true;
   return(true);
  }

//--- z(N) = c + soma phi_i z(N-1-i) + soma theta_j e(N-1-j); o e(N) entra pelo valor esperado, zero
double CArima::PreverDiferenciado(void)
  {
   if(!m_ajustado)
      return(0.0);

   int tamanho = ArraySize(m_serie_diferenciada);
   double previsao = m_constante;

   for(int i = 0; i < m_p; i++)
     {
      int indice = tamanho - 1 - i;
      if(indice >= 0)
         previsao += m_phi[i] * m_serie_diferenciada[indice];
     }
   for(int j = 0; j < m_q; j++)
     {
      int indice = tamanho - 1 - j;
      if(indice >= 0)
         previsao += m_theta[j] * m_residuos[indice];
     }

   return(previsao);
  }

//--- d=1: y(N) = y(N-1) + z(N);  d=2: y(N) = 2 y(N-1) - y(N-2) + z(N)
double CArima::PreverNivel(void)
  {
   if(!m_ajustado)
      return(0.0);

   double z = PreverDiferenciado();
   int n = ArraySize(m_ultimos_niveis);

   if(m_d == 1)
      return((n >= 1) ? m_ultimos_niveis[n - 1] + z : z);
   if(m_d == 2 && n >= 2)
      return(2.0 * m_ultimos_niveis[n - 1] - m_ultimos_niveis[n - 2] + z);

   return(z);
  }

double CArima::AIC(void) const
  {
   if(!m_ajustado)
      return(DBL_MAX);
   return(CalcularAIC(m_log_verossimilhanca, NumParametros()));
  }

//@omitir-inicio
double CArima::BIC(void) const
  {
   if(!m_ajustado)
      return(DBL_MAX);
   return(CalcularBIC(m_log_verossimilhanca, NumParametros(), m_observacoes_efetivas));
  }
  //@omitir-fim

bool CArima::ObterResiduos(double &saida[]) const
  {
   if(!m_ajustado)
      return(false);

   int validos = ArraySize(m_residuos) - m_inicio_recursao;
   if(validos <= 0)
      return(false);

   ArrayResize(saida, validos);
   for(int i = 0; i < validos; i++)
      saida[i] = m_residuos[m_inicio_recursao + i];

   return(true);
  }

//@omitir-inicio
bool CArima::ResiduosSobre(const double &serie[], const int quantidade, double &saida[])
  {
   if(!m_ajustado || quantidade <= 0)
      return(false);

   double z[];
   Diferenciar(serie, z, m_d);
   int tamanho = ArraySize(z);
   int inicio = MathMax(m_p, m_q);
   if(tamanho - inicio < quantidade)
      return(false);

   double erros[];
   ArrayResize(erros, tamanho);
   ArrayInitialize(erros, 0.0);
   for(int t = inicio; t < tamanho; t++)
     {
      double ajuste = m_constante;
      for(int i = 0; i < m_p; i++)
         ajuste += m_phi[i] * z[t - 1 - i];
      for(int j = 0; j < m_q; j++)
         ajuste += m_theta[j] * erros[t - 1 - j];
      erros[t] = z[t] - ajuste;
     }

   ArrayResize(saida, quantidade);
   for(int i = 0; i < quantidade; i++)
      saida[i] = erros[tamanho - quantidade + i];
   return(true);
  }
  //@omitir-fim

//@omitir-inicio
bool CArima::EstacionariedadeGarantida(void) const
  {
   double soma = 0.0;
   for(int i = 0; i < m_p; i++)
      soma += MathAbs(m_phi[i]);
   return(soma < 1.0);
  }

string CArima::Descricao(void) const
  {
   string texto = StringFormat("ARIMA(%d,%d,%d)", m_p, m_d, m_q);
   if(!m_ajustado)
      return(texto + " [nao ajustado: " + m_erro + "]");

   texto += StringFormat(" c=%.8f", m_constante);
   for(int i = 0; i < m_p; i++)
      texto += StringFormat(" phi%d=%.6f", i + 1, m_phi[i]);
   for(int j = 0; j < m_q; j++)
      texto += StringFormat(" theta%d=%.6f", j + 1, m_theta[j]);
   texto += StringFormat(" | sigma2=%.10f logL=%.3f AIC=%.3f BIC=%.3f n=%d",
                         m_sigma2, m_log_verossimilhanca, AIC(), BIC(), m_observacoes_efetivas);
   return(texto);
  }
  //@omitir-fim

#endif
