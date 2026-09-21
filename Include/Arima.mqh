//+------------------------------------------------------------------+
//|                                                        Arima.mqh |
//|                            Trabalho de Graduacao - FATEC Indaiatuba|
//+------------------------------------------------------------------+
//|                                                                  |
//|  MODELO ARIMA(p,d,q) — MEDIA CONDICIONAL                         |
//|                                                                  |
//|  Modelo (sobre a serie ja diferenciada d vezes, z):              |
//|                                                                  |
//|    z(t) = c + SOMA_i phi_i * z(t-i)                              |
//|              + SOMA_j theta_j * e(t-j)                           |
//|              + e(t)                                              |
//|                                                                  |
//|  ESTIMACAO: metodo de Hannan-Rissanen (1982), em dois estagios.  |
//|                                                                  |
//|  O problema do ARMA e que os erros e(t) nao sao observaveis —    |
//|  eles dependem dos coeficientes que ainda queremos estimar.      |
//|  Hannan-Rissanen resolve isso em duas etapas, ambas por MQO:     |
//|                                                                  |
//|    Estagio 1: ajusta um AR(m) longo (m grande). Um AR longo      |
//|               aproxima qualquer ARMA invertivel, entao seus      |
//|               residuos sao uma boa ESTIMATIVA de e(t).           |
//|                                                                  |
//|    Estagio 2: agora que temos e(t) estimados, o modelo ARMA      |
//|               vira uma regressao linear comum de z(t) contra     |
//|               z(t-1..p) e e(t-1..q). Resolve-se por MQO.         |
//|                                                                  |
//|  Por que nao gradiente descendente (implementacao anterior):     |
//|  MQO nao tem taxa de aprendizado nem numero de iteracoes, da o   |
//|  otimo exato do problema de cada estagio e — o mais importante — |
//|  e invariante a escala. A versao com gradiente exigia recalibrar |
//|  a taxa de aprendizado para cada ativo e cada periodo.           |
//|                                                                  |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_ARIMA_MQH
#define ALGOTRADINGLAB_ARIMA_MQH

#include "Numerico.mqh"
#include "Estatistica.mqh"

//+------------------------------------------------------------------+
//| CArima                                                           |
//+------------------------------------------------------------------+
class CArima
  {
private:
   //--- Ordens do modelo
   int      m_p;                 // ordem autorregressiva
   int      m_d;                 // ordem de diferenciacao
   int      m_q;                 // ordem de medias moveis
   bool     m_com_constante;     // incluir o intercepto c

   //--- Parametros estimados
   double   m_c;                 // constante
   double   m_phi[];             // coeficientes AR
   double   m_theta[];           // coeficientes MA

   //--- Estado do ajuste
   double   m_z[];               // serie diferenciada
   double   m_e[];               // residuos alinhados com m_z (0 no aquecimento)
   double   m_niveis[];          // ultimos valores da serie ORIGINAL
   double   m_sigma2;            // variancia dos residuos
   double   m_logL;              // log-verossimilhanca condicional
   int      m_t0_rec;            // inicio da recursao dos residuos
   int      m_t0_ll;             // inicio da soma da verossimilhanca
   int      m_t0_min;            // aquecimento minimo imposto de fora
   int      m_n_efetivo;         // observacoes usadas na verossimilhanca
   bool     m_ajustado;
   string   m_erro;

   //--- Metodos internos
   void     Diferenciar(const double &origem[], double &destino[], const int ordem);
   bool     EstimarAR(const double &z[], const int ordem, double &coef_out[], double &res_out[]);
   bool     HannanRissanen(void);
   void     CalcularResiduos(void);
   void     CalcularVerossimilhanca(void);

public:
                     CArima(void);
                    ~CArima(void);

   //--- Configuracao
   void     Definir(const int p, const int d, const int q, const bool com_constante = true);

   //--- AQUECIMENTO MINIMO — essencial para comparar AIC entre modelos
   //--- Um ARIMA(0,d,0) consegue avaliar a verossimilhanca em todas as
   //--- observacoes; um ARIMA(4,d,4) precisa descartar as 4 primeiras.
   //--- Como a log-verossimilhanca CRESCE com o numero de observacoes,
   //--- comparar o AIC dos dois seria injusto: o modelo menor venceria
   //--- por ter somado mais parcelas, nao por ajustar melhor.
   //---
   //--- A busca em grade chama isto com max(p_max, q_max) para que TODOS
   //--- os candidatos sejam avaliados exatamente sobre as mesmas
   //--- observacoes. Sem isso a selecao fica viesada para modelos
   //--- pequenos — o vies chega a ser maior que a diferenca real entre
   //--- os modelos.
   void     DefinirAquecimentoMinimo(const int t0_min) { m_t0_min = MathMax(0, t0_min); }

   //--- Ajuste. 'serie' em ordem cronologica: indice 0 = mais antigo.
   bool     Ajustar(const double &serie[]);

   //--- Previsao um passo a frente
   double   PreverDiferenciado(void);   // no espaco diferenciado (z)
   double   PreverNivel(void);          // revertido para o nivel original

   //--- Diagnostico e selecao de modelo
   double   LogVerossimilhanca(void) const { return(m_logL);      }
   double   Sigma2(void)            const  { return(m_sigma2);    }
   int      NumParametros(void)     const;
   double   AIC(void)               const;
   double   BIC(void)               const;
   int      NEfetivo(void)          const  { return(m_n_efetivo); }
   bool     Ajustado(void)          const  { return(m_ajustado);  }
   string   UltimoErro(void)        const  { return(m_erro);      }

   int      P(void) const { return(m_p); }
   int      D(void) const { return(m_d); }
   int      Q(void) const { return(m_q); }
   double   Constante(void) const { return(m_c); }
   double   Phi(const int i)   const { return((i >= 0 && i < ArraySize(m_phi))   ? m_phi[i]   : 0.0); }
   double   Theta(const int j) const { return((j >= 0 && j < ArraySize(m_theta)) ? m_theta[j] : 0.0); }

   //--- Residuos VALIDOS (sem o periodo de aquecimento).
   //--- E esta a serie que alimenta o GARCH.
   bool     ObterResiduos(double &saida[]) const;

   //--- Guarda conservadora de estabilidade do polinomio AR.
   //--- SOMA|phi| < 1 e condicao SUFICIENTE (nao necessaria) para
   //--- estacionariedade. Se falhar, o modelo pode ainda ser valido,
   //--- mas a previsao merece desconfianca.
   bool     EstavelConservador(void) const;

   string   Descricao(void) const;
  };

//+------------------------------------------------------------------+
CArima::CArima(void) : m_p(1), m_d(1), m_q(1), m_com_constante(true),
                       m_c(0.0), m_sigma2(0.0), m_logL(0.0),
                       m_t0_rec(0), m_t0_ll(0), m_t0_min(0),
                       m_n_efetivo(0), m_ajustado(false), m_erro("")
  {
  }

//+------------------------------------------------------------------+
CArima::~CArima(void)
  {
   ArrayFree(m_phi);
   ArrayFree(m_theta);
   ArrayFree(m_z);
   ArrayFree(m_e);
   ArrayFree(m_niveis);
  }

//+------------------------------------------------------------------+
void CArima::Definir(const int p, const int d, const int q, const bool com_constante)
  {
   m_p = MathMax(0, p);
   m_d = MathMax(0, MathMin(2, d));
   m_q = MathMax(0, q);
   m_com_constante = com_constante;

   ArrayResize(m_phi, m_p);
   ArrayResize(m_theta, m_q);
   ArrayInitialize(m_phi, 0.0);
   ArrayInitialize(m_theta, 0.0);

   m_ajustado = false;
  }

//+------------------------------------------------------------------+
//| Diferenciacao de ordem 'ordem'                                   |
//+------------------------------------------------------------------+
//|  d=1: z(t) = y(t) - y(t-1)                                       |
//|  d=2: aplica o mesmo duas vezes                                  |
//+------------------------------------------------------------------+
void CArima::Diferenciar(const double &origem[], double &destino[], const int ordem)
  {
   int n = ArraySize(origem);
   ArrayResize(destino, n);
   ArrayCopy(destino, origem);

   for(int d = 0; d < ordem; d++)
     {
      int tam = ArraySize(destino);
      if(tam < 2)
         break;

      for(int i = 0; i < tam - 1; i++)
         destino[i] = destino[i + 1] - destino[i];

      ArrayResize(destino, tam - 1);
     }
  }

//+------------------------------------------------------------------+
//| Estima um AR(ordem) por MQO e devolve coeficientes e residuos    |
//+------------------------------------------------------------------+
//|  res_out fica alinhado com z: res_out[t] e o residuo em t,       |
//|  zerado para t < ordem (periodo de aquecimento).                 |
//+------------------------------------------------------------------+
bool CArima::EstimarAR(const double &z[], const int ordem,
                       double &coef_out[], double &res_out[])
  {
   int N = ArraySize(z);
   int n_obs = N - ordem;
   int n_par = ordem + 1;         // + constante

   if(ordem <= 0 || n_obs <= n_par)
      return(false);

   CMatrixDouble X(n_obs, n_par);
   double dep[];
   ArrayResize(dep, n_obs);

   for(int t = ordem, linha = 0; t < N; t++, linha++)
     {
      dep[linha] = z[t];
      X.Set(linha, 0, 1.0);
      for(int i = 1; i <= ordem; i++)
         X.Set(linha, i, z[t - i]);
     }

   double se[], ssr = 0.0;
   if(!MQO(X, dep, n_obs, n_par, coef_out, se, ssr, false))
      return(false);

   //--- Residuos do AR longo = estimativa de e(t)
   ArrayResize(res_out, N);
   ArrayInitialize(res_out, 0.0);

   for(int t = ordem; t < N; t++)
     {
      double ajuste = coef_out[0];
      for(int i = 1; i <= ordem; i++)
         ajuste += coef_out[i] * z[t - i];

      res_out[t] = z[t] - ajuste;
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Hannan-Rissanen — os dois estagios                               |
//+------------------------------------------------------------------+
bool CArima::HannanRissanen(void)
  {
   int N = ArraySize(m_z);

   //--- ── Caso especial: q = 0 ──
   //--- Sem componente MA, o modelo ja e uma regressao linear
   //--- direta. Um unico MQO resolve exatamente.
   if(m_q == 0)
     {
      if(m_p == 0)
        {
         //--- ARIMA(0,d,0): so a constante (passeio aleatorio com drift)
         m_c = m_com_constante ? Media(m_z) : 0.0;
         return(true);
        }

      int n_obs = N - m_p;
      int n_par = m_p + (m_com_constante ? 1 : 0);
      if(n_obs <= n_par)
        {
         m_erro = "Serie curta demais para AR(" + IntegerToString(m_p) + ")";
         return(false);
        }

      CMatrixDouble X(n_obs, n_par);
      double dep[];
      ArrayResize(dep, n_obs);

      for(int t = m_p, linha = 0; t < N; t++, linha++)
        {
         dep[linha] = m_z[t];
         int col = 0;
         if(m_com_constante)
            X.Set(linha, col++, 1.0);
         for(int i = 1; i <= m_p; i++)
            X.Set(linha, col++, m_z[t - i]);
        }

      double coef[], se[], ssr = 0.0;
      if(!MQO(X, dep, n_obs, n_par, coef, se, ssr, false))
        {
         m_erro = "MQO singular no ajuste AR";
         return(false);
        }

      int col = 0;
      m_c = m_com_constante ? coef[col++] : 0.0;
      for(int i = 0; i < m_p; i++)
         m_phi[i] = coef[col++];

      return(true);
     }

   //--- ── ESTAGIO 1: AR(m) longo para estimar os erros ──
   //--- m cresce com o tamanho da amostra. A regra log(N)^2 e a
   //--- usual na literatura de Hannan-Rissanen; limitamos abaixo
   //--- para nao consumir observacoes demais em janelas curtas.
   int m = (int)MathFloor(MathPow(MathLog((double)N), 2.0));
   m = MathMax(m, m_p + m_q + 1);
   m = MathMin(m, N / 5);

   if(m < 1 || N - m < m_p + m_q + 10)
     {
      m_erro = "Serie curta demais para Hannan-Rissanen";
      return(false);
     }

   double coef_ar[], e_est[];
   if(!EstimarAR(m_z, m, coef_ar, e_est))
     {
      m_erro = "Falha no estagio 1 (AR longo)";
      return(false);
     }

   //--- ── ESTAGIO 2: regressao de z contra z defasado e e defasado ──
   //--- Precisamos que e(t-1..t-q) sejam validos => t >= m + q
   int t_ini = MathMax(m + m_q, m_p);
   int n_obs = N - t_ini;
   int n_par = m_p + m_q + (m_com_constante ? 1 : 0);

   if(n_obs <= n_par + 5)
     {
      m_erro = "Observacoes insuficientes no estagio 2";
      return(false);
     }

   CMatrixDouble X(n_obs, n_par);
   double dep[];
   ArrayResize(dep, n_obs);

   for(int t = t_ini, linha = 0; t < N; t++, linha++)
     {
      dep[linha] = m_z[t];

      int col = 0;
      if(m_com_constante)
         X.Set(linha, col++, 1.0);

      for(int i = 1; i <= m_p; i++)
         X.Set(linha, col++, m_z[t - i]);

      for(int j = 1; j <= m_q; j++)
         X.Set(linha, col++, e_est[t - j]);
     }

   double coef[], se[], ssr = 0.0;
   if(!MQO(X, dep, n_obs, n_par, coef, se, ssr, false))
     {
      m_erro = "MQO singular no estagio 2";
      return(false);
     }

   int col = 0;
   m_c = m_com_constante ? coef[col++] : 0.0;
   for(int i = 0; i < m_p; i++)
      m_phi[i] = coef[col++];
   for(int j = 0; j < m_q; j++)
      m_theta[j] = coef[col++];

   return(true);
  }

//+------------------------------------------------------------------+
//| Recalcula os residuos pela recursao ARMA exata                   |
//+------------------------------------------------------------------+
//|  e(t) = z(t) - c - SOMA phi_i*z(t-i) - SOMA theta_j*e(t-j)       |
//|                                                                  |
//|  Os residuos do estagio 2 sao aproximados (usam os erros do AR   |
//|  longo). Aqui reconstruimos os residuos coerentes com os         |
//|  coeficientes finais — sao eles que alimentam o GARCH e o        |
//|  teste de Ljung-Box.                                             |
//+------------------------------------------------------------------+
void CArima::CalcularResiduos(void)
  {
   int N = ArraySize(m_z);

   ArrayResize(m_e, N);
   ArrayInitialize(m_e, 0.0);

   //--- A recursao comeca cedo (assim o componente MA tem tempo de
   //--- aquecer), mas a verossimilhanca so passa a somar em m_t0_ll.
   m_t0_rec = MathMax(m_p, m_q);
   m_t0_ll  = MathMax(m_t0_rec, m_t0_min);

   for(int t = m_t0_rec; t < N; t++)
     {
      double ajuste = m_c;

      for(int i = 0; i < m_p; i++)
         ajuste += m_phi[i] * m_z[t - 1 - i];

      for(int j = 0; j < m_q; j++)
         ajuste += m_theta[j] * m_e[t - 1 - j];

      m_e[t] = m_z[t] - ajuste;
     }
  }

//+------------------------------------------------------------------+
//| Log-verossimilhanca gaussiana condicional                        |
//+------------------------------------------------------------------+
//|  Com sigma2 estimado por maxima verossimilhanca (SSR/n), a       |
//|  expressao se reduz a:                                           |
//|                                                                  |
//|    logL = -n/2 * [ ln(2*pi) + ln(sigma2) + 1 ]                   |
//|                                                                  |
//|  E esta a verossimilhanca que alimenta o AIC usado para          |
//|  escolher (p,q) na busca em grade.                               |
//+------------------------------------------------------------------+
void CArima::CalcularVerossimilhanca(void)
  {
   int N = ArraySize(m_z);
   m_n_efetivo = N - m_t0_ll;

   if(m_n_efetivo <= 0)
     {
      m_sigma2 = 0.0;
      m_logL   = -DBL_MAX;
      return;
     }

   double ssr = 0.0;
   for(int t = m_t0_ll; t < N; t++)
      ssr += m_e[t] * m_e[t];

   m_sigma2 = ssr / (double)m_n_efetivo;

   if(m_sigma2 <= 0.0 || !MathIsValidNumber(m_sigma2))
     {
      m_logL = -DBL_MAX;
      return;
     }

   m_logL = -0.5 * (double)m_n_efetivo *
            (MathLog(2.0 * M_PI) + MathLog(m_sigma2) + 1.0);
  }

//+------------------------------------------------------------------+
//| Ajusta o modelo a uma serie                                      |
//+------------------------------------------------------------------+
bool CArima::Ajustar(const double &serie[])
  {
   m_ajustado = false;
   m_erro = "";

   int n = ArraySize(serie);

   //--- Precisamos de folga: diferenciacao consome d observacoes,
   //--- o estagio 1 consome m, o estagio 2 consome mais q.
   int minimo = m_p + m_q + m_d + 30;
   if(n < minimo)
     {
      m_erro = StringFormat("Serie com %d pontos; minimo %d", n, minimo);
      return(false);
     }

   //--- Guarda os ultimos niveis para reverter a diferenciacao
   ArrayResize(m_niveis, MathMin(n, 3));
   for(int i = 0; i < ArraySize(m_niveis); i++)
      m_niveis[i] = serie[n - ArraySize(m_niveis) + i];

   //--- Diferencia
   Diferenciar(serie, m_z, m_d);

   if(ArraySize(m_z) < m_p + m_q + 20)
     {
      m_erro = "Serie diferenciada curta demais";
      return(false);
     }

   ArrayResize(m_phi, m_p);
   ArrayResize(m_theta, m_q);
   ArrayInitialize(m_phi, 0.0);
   ArrayInitialize(m_theta, 0.0);
   m_c = 0.0;

   if(!HannanRissanen())
      return(false);

   //--- Verifica sanidade numerica dos coeficientes
   for(int i = 0; i < m_p; i++)
      if(!MathIsValidNumber(m_phi[i]))
        {
         m_erro = "Coeficiente AR invalido";
         return(false);
        }
   for(int j = 0; j < m_q; j++)
      if(!MathIsValidNumber(m_theta[j]))
        {
         m_erro = "Coeficiente MA invalido";
         return(false);
        }

   CalcularResiduos();
   CalcularVerossimilhanca();

   if(m_logL == -DBL_MAX)
     {
      m_erro = "Verossimilhanca invalida";
      return(false);
     }

   m_ajustado = true;
   return(true);
  }

//+------------------------------------------------------------------+
//| Previsao um passo a frente no espaco diferenciado                |
//+------------------------------------------------------------------+
//|  z(N) = c + SOMA phi_i*z(N-1-i) + SOMA theta_j*e(N-1-j)          |
//|                                                                  |
//|  O termo e(N) e omitido porque seu valor esperado e zero.        |
//+------------------------------------------------------------------+
double CArima::PreverDiferenciado(void)
  {
   if(!m_ajustado)
      return(0.0);

   int N = ArraySize(m_z);
   double previsao = m_c;

   for(int i = 0; i < m_p; i++)
     {
      int idx = N - 1 - i;
      if(idx >= 0)
         previsao += m_phi[i] * m_z[idx];
     }

   for(int j = 0; j < m_q; j++)
     {
      int idx = N - 1 - j;
      if(idx >= 0)
         previsao += m_theta[j] * m_e[idx];
     }

   return(previsao);
  }

//+------------------------------------------------------------------+
//| Previsao revertida para o nivel da serie original                |
//+------------------------------------------------------------------+
//|  d=0: y(N) = z(N)                                                |
//|  d=1: y(N) = y(N-1) + z(N)                                       |
//|  d=2: y(N) = 2*y(N-1) - y(N-2) + z(N)                            |
//+------------------------------------------------------------------+
double CArima::PreverNivel(void)
  {
   if(!m_ajustado)
      return(0.0);

   double z = PreverDiferenciado();
   int n = ArraySize(m_niveis);

   if(m_d == 0)
      return(z);

   if(m_d == 1)
      return((n >= 1) ? m_niveis[n - 1] + z : z);

   if(m_d == 2)
     {
      if(n < 2)
         return(z);
      return(2.0 * m_niveis[n - 1] - m_niveis[n - 2] + z);
     }

   return(z);
  }

//+------------------------------------------------------------------+
//| Numero de parametros para os criterios de informacao             |
//+------------------------------------------------------------------+
//|  p coeficientes AR + q coeficientes MA + constante + sigma2      |
//+------------------------------------------------------------------+
int CArima::NumParametros(void) const
  {
   return(m_p + m_q + (m_com_constante ? 1 : 0) + 1);
  }

double CArima::AIC(void) const
  {
   if(!m_ajustado)
      return(DBL_MAX);
   return(CalcularAIC(m_logL, NumParametros()));
  }

double CArima::BIC(void) const
  {
   if(!m_ajustado)
      return(DBL_MAX);
   return(CalcularBIC(m_logL, NumParametros(), m_n_efetivo));
  }

//+------------------------------------------------------------------+
//| Residuos validos (descarta o aquecimento)                        |
//+------------------------------------------------------------------+
//|  IMPORTANTE: a implementacao anterior passava ao GARCH o array   |
//|  inteiro, incluindo os zeros do periodo de aquecimento. Zeros    |
//|  artificiais reduzem a variancia amostral e contaminam a         |
//|  estimacao da volatilidade. Aqui eles sao cortados.              |
//+------------------------------------------------------------------+
bool CArima::ObterResiduos(double &saida[]) const
  {
   if(!m_ajustado)
      return(false);

   int N = ArraySize(m_e);
   int n_validos = N - m_t0_rec;

   if(n_validos <= 0)
      return(false);

   ArrayResize(saida, n_validos);
   for(int i = 0; i < n_validos; i++)
      saida[i] = m_e[m_t0_rec + i];

   return(true);
  }

//+------------------------------------------------------------------+
bool CArima::EstavelConservador(void) const
  {
   double soma = 0.0;
   for(int i = 0; i < m_p; i++)
      soma += MathAbs(m_phi[i]);

   return(soma < 1.0);
  }

//+------------------------------------------------------------------+
string CArima::Descricao(void) const
  {
   string s = StringFormat("ARIMA(%d,%d,%d)", m_p, m_d, m_q);

   if(!m_ajustado)
      return(s + " [nao ajustado: " + m_erro + "]");

   s += StringFormat(" c=%.8f", m_c);

   for(int i = 0; i < m_p; i++)
      s += StringFormat(" phi%d=%.6f", i + 1, m_phi[i]);
   for(int j = 0; j < m_q; j++)
      s += StringFormat(" theta%d=%.6f", j + 1, m_theta[j]);

   s += StringFormat(" | sigma2=%.10f logL=%.3f AIC=%.3f BIC=%.3f n=%d",
                     m_sigma2, m_logL, AIC(), BIC(), m_n_efetivo);

   return(s);
  }

#endif // ALGOTRADINGLAB_ARIMA_MQH
//+------------------------------------------------------------------+
