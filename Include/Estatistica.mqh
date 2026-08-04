//+------------------------------------------------------------------+
//|                                                  Estatistica.mqh |
//|                            Trabalho de Graduacao - FATEC Indaiatuba|
//+------------------------------------------------------------------+
//|                                                                  |
//|  TESTES ESTATISTICOS                                             |
//|                                                                  |
//|  Implementa os testes que a metodologia do TG (secao 3.4 e 3.6)  |
//|  afirma terem sido executados:                                   |
//|                                                                  |
//|    - ADF (Dickey-Fuller Aumentado) .... define a ordem 'd'       |
//|    - Ljung-Box ....................... valida os residuos        |
//|    - AIC / BIC ....................... seleciona (p,q)           |
//|                                                                  |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_ESTATISTICA_MQH
#define ALGOTRADINGLAB_ESTATISTICA_MQH

#include "Numerico.mqh"
#include <Math\Stat\ChiSquare.mqh>
#include <Math\Stat\Normal.mqh>

//+------------------------------------------------------------------+
//| Termos deterministicos da regressao ADF                          |
//+------------------------------------------------------------------+
//|                                                                  |
//|  A escolha muda os valores criticos do teste, entao ela importa. |
//|                                                                  |
//|  ADF_SEM_CONSTANTE     — serie sem media e sem tendencia.        |
//|                          Apropriado para RETORNOS.               |
//|  ADF_CONSTANTE         — serie com media diferente de zero.      |
//|                          Padrao para precos.                     |
//|  ADF_CONSTANTE_TENDENCIA — serie com tendencia deterministica.   |
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_ADF_DETERMINISTICO
  {
   ADF_SEM_CONSTANTE = 0,        // Sem constante (nc)
   ADF_CONSTANTE = 1,            // Com constante (c)
   ADF_CONSTANTE_TENDENCIA = 2   // Constante + tendencia (ct)
  };

//+------------------------------------------------------------------+
//| Resultado do teste ADF                                           |
//+------------------------------------------------------------------+
struct ResultadoADF
  {
   bool     valido;            // false se nao houve dados suficientes
   double   estatistica;       // estatistica t de gamma
   double   vc_1pct;           // valor critico a 1%
   double   vc_5pct;           // valor critico a 5%
   double   vc_10pct;          // valor critico a 10%
   double   pvalor_aprox;      // p-valor APROXIMADO (ver nota abaixo)
   int      lags;              // defasagens usadas
   int      n_obs;             // observacoes efetivas na regressao
   bool     estacionaria_5pct; // estatistica < vc_5pct
  };

//+------------------------------------------------------------------+
//| Valores criticos de MacKinnon (2010)                             |
//+------------------------------------------------------------------+
//|                                                                  |
//|  O teste ADF nao segue distribuicao t de Student — sua           |
//|  distribuicao nula e nao-padrao. MacKinnon estimou por simulacao |
//|  uma "superficie de resposta" que da o valor critico em funcao   |
//|  do tamanho da amostra T:                                        |
//|                                                                  |
//|      VC(T) = b0 + b1/T + b2/T^2 + b3/T^3                         |
//|                                                                  |
//|  Fonte: MacKinnon, J. G. "Critical Values for Cointegration      |
//|  Tests" (2010), Tabela 2, coluna N=1. Sao os mesmos coeficientes |
//|  usados pelo pacote statsmodels do Python, o que permite         |
//|  conferir os resultados deste EA contra uma referencia externa.  |
//|                                                                  |
//+------------------------------------------------------------------+
double ADF_ValorCritico(const ENUM_ADF_DETERMINISTICO det,
                        const int nivel_idx,   // 0 = 1%, 1 = 5%, 2 = 10%
                        const int T)
  {
   //--- [determinismo][nivel][coeficiente b0..b3]
   static double tab[3][3][4] =
     {
        //--- ADF_SEM_CONSTANTE (nc)
        {
           { -2.56574, -2.2358,  -3.627,    0.000 },
           { -1.94100, -0.2686,  -3.365,   31.223 },
           { -1.61682,  0.2656,  -2.714,   25.364 }
        },
        //--- ADF_CONSTANTE (c)
        {
           { -3.43035, -6.5393, -16.786,  -79.433 },
           { -2.86154, -2.8903,  -4.234,  -40.040 },
           { -2.56677, -1.5384,  -2.809,    0.000 }
        },
        //--- ADF_CONSTANTE_TENDENCIA (ct)
        {
           { -3.95877, -9.0531, -28.428, -134.155 },
           { -3.41049, -4.3904,  -9.036,  -45.374 },
           { -3.12705, -2.5856,  -3.925,  -22.380 }
        }
     };

   if(T <= 0)
      return(0.0);

   int d = (int)det;
   if(d < 0 || d > 2)      d = 1;
   int L = nivel_idx;
   if(L < 0 || L > 2)      L = 1;

   double invT = 1.0 / (double)T;

   return(tab[d][L][0]
          + tab[d][L][1] * invT
          + tab[d][L][2] * invT * invT
          + tab[d][L][3] * invT * invT * invT);
  }

//+------------------------------------------------------------------+
//| p-valor aproximado do ADF                                        |
//+------------------------------------------------------------------+
//|                                                                  |
//|  ATENCAO — LIMITACAO CONHECIDA E DELIBERADA:                     |
//|                                                                  |
//|  O p-valor exato do ADF exige a superficie de resposta completa  |
//|  de MacKinnon (dezenas de coeficientes por regiao da            |
//|  distribuicao). Aqui ele e obtido por interpolacao entre os      |
//|  tres valores criticos (1%, 5%, 10%) na escala do quantil        |
//|  normal. E adequado para leitura ("bem abaixo de 5%"), mas NAO   |
//|  deve ser reportado no TG como um p-valor exato.                 |
//|                                                                  |
//|  A DECISAO do teste (estacionaria ou nao) usa sempre os valores  |
//|  criticos, que sao exatos. O p-valor e apenas informativo.       |
//|                                                                  |
//+------------------------------------------------------------------+
double ADF_PValorAproximado(const double estatistica,
                            const double vc1, const double vc5, const double vc10)
  {
   //--- Quantis normais correspondentes a 1%, 5% e 10%
   const double z1  = -2.326347;
   const double z5  = -1.644854;
   const double z10 = -1.281552;

   double z;

   if(estatistica <= vc5)
     {
      //--- Entre 1% e 5%, e extrapolando abaixo de 1% com a mesma
      //--- inclinacao (por isso os dois casos usam a mesma reta)
      double inclinacao = (z5 - z1) / (vc5 - vc1);
      z = z1 + (estatistica - vc1) * inclinacao;
     }
   else if(estatistica <= vc10)
     {
      double inclinacao = (z10 - z5) / (vc10 - vc5);
      z = z5 + (estatistica - vc5) * inclinacao;
     }
   else
     {
      double inclinacao = (z10 - z5) / (vc10 - vc5);
      z = z10 + (estatistica - vc10) * inclinacao;
     }

   int erro = 0;
   double p = MathCumulativeDistributionNormal(z, 0.0, 1.0, erro);

   if(erro != 0)
      return(-1.0);

   //--- Limita a faixa em que a aproximacao tem algum sentido
   return(MathMax(0.001, MathMin(0.999, p)));
  }

//+------------------------------------------------------------------+
//| TESTE ADF — Dickey-Fuller Aumentado                              |
//+------------------------------------------------------------------+
//|                                                                  |
//|  HIPOTESE NULA (H0): a serie possui raiz unitaria                |
//|                      => NAO e estacionaria                       |
//|  HIPOTESE ALT. (H1): a serie e estacionaria                      |
//|                                                                  |
//|  Estimamos por MQO a regressao:                                  |
//|                                                                  |
//|    dy(t) = gamma*y(t-1) + [a] + [b*t] + SOMA(c_i * dy(t-i)) + e  |
//|                                                                  |
//|  e testamos gamma = 0 pela estatistica t. Se gamma = 0, entao    |
//|  dy(t) nao depende do nivel y(t-1) — a serie "passeia" sem ser   |
//|  puxada de volta, ou seja, tem raiz unitaria.                    |
//|                                                                  |
//|  Rejeitamos H0 quando a estatistica t e MENOR (mais negativa)    |
//|  que o valor critico. Note que o teste e unilateral a esquerda.  |
//|                                                                  |
//|  ENTRADA:                                                        |
//|    y     — serie em ordem cronologica (indice 0 = mais antigo)   |
//|    det   — termos deterministicos                                |
//|    lags  — numero de defasagens de dy. Use -1 para selecao       |
//|            automatica por AIC (recomendado).                     |
//|                                                                  |
//+------------------------------------------------------------------+
bool TesteADF(const double &y[], const ENUM_ADF_DETERMINISTICO det,
              const int lags, ResultadoADF &res)
  {
   res.valido = false;
   res.estatistica = 0.0;
   res.pvalor_aprox = -1.0;
   res.lags = 0;
   res.n_obs = 0;
   res.estacionaria_5pct = false;

   int n = ArraySize(y);
   if(n < 20)
      return(false);

   //--- Regra de Schwert para o numero maximo de defasagens:
   //--- k_max = floor(12 * (T/100)^(1/4))
   int k_max = (int)MathFloor(12.0 * MathPow(n / 100.0, 0.25));
   k_max = MathMax(0, MathMin(k_max, (n - 10) / 4));

   int k_ini, k_fim;
   if(lags >= 0)
     {
      k_ini = MathMin(lags, k_max);
      k_fim = k_ini;
     }
   else
     {
      //--- Selecao automatica: testa 0..k_max e fica com o menor AIC
      k_ini = 0;
      k_fim = k_max;
     }

   double melhor_aic = DBL_MAX;
   bool   achou = false;

   for(int k = k_ini; k <= k_fim; k++)
     {
      //--- ── Monta a regressao para esta quantidade de defasagens ──
      //--- dy tem n-1 elementos: dy[i] = y[i+1] - y[i]
      //--- A observacao no tempo t usa dy[t-1] como dependente,
      //--- y[t-1] como nivel e dy[t-1-j] como defasagens.
      //--- t varre de (k+1) ate (n-1).
      int n_obs = n - 1 - k;
      if(n_obs < k + 5)
         continue;

      int n_det = 0;
      if(det == ADF_CONSTANTE)             n_det = 1;
      if(det == ADF_CONSTANTE_TENDENCIA)   n_det = 2;

      int n_par = 1 + n_det + k;   // gamma + deterministicos + defasagens
      if(n_obs <= n_par)
         continue;

      CMatrixDouble X(n_obs, n_par);
      double dep[];
      ArrayResize(dep, n_obs);

      for(int t = k + 1, linha = 0; t <= n - 1; t++, linha++)
        {
         dep[linha] = y[t] - y[t - 1];

         int col = 0;
         //--- nivel defasado (o coeficiente de interesse, gamma)
         X.Set(linha, col++, y[t - 1]);

         if(n_det >= 1)
            X.Set(linha, col++, 1.0);
         if(n_det >= 2)
            X.Set(linha, col++, (double)t);

         //--- defasagens da primeira diferenca
         for(int j = 1; j <= k; j++)
            X.Set(linha, col++, y[t - j] - y[t - j - 1]);
        }

      double coef[], se[], ssr = 0.0;
      if(!MQO(X, dep, n_obs, n_par, coef, se, ssr, true))
         continue;

      //--- Sem erro-padrao nao ha estatistica t
      if(se[0] <= 0.0)
         continue;

      //--- AIC da regressao auxiliar, usado apenas para escolher k
      double aic = (double)n_obs * MathLog(ssr / (double)n_obs) + 2.0 * (double)n_par;

      if(aic < melhor_aic)
        {
         melhor_aic = aic;
         achou = true;

         res.estatistica = coef[0] / se[0];
         res.lags = k;
         res.n_obs = n_obs;
        }
     }

   if(!achou)
      return(false);

   res.vc_1pct  = ADF_ValorCritico(det, 0, res.n_obs);
   res.vc_5pct  = ADF_ValorCritico(det, 1, res.n_obs);
   res.vc_10pct = ADF_ValorCritico(det, 2, res.n_obs);

   res.pvalor_aprox = ADF_PValorAproximado(res.estatistica,
                                           res.vc_1pct, res.vc_5pct, res.vc_10pct);

   //--- Rejeita H0 (raiz unitaria) => serie estacionaria
   res.estacionaria_5pct = (res.estatistica < res.vc_5pct);
   res.valido = true;

   return(true);
  }

//+------------------------------------------------------------------+
//| Autocorrelacao amostral no lag k                                 |
//+------------------------------------------------------------------+
double Autocorrelacao(const double &x[], const int k)
  {
   int n = ArraySize(x);
   if(n <= k || k < 0)
      return(0.0);

   double media = 0.0;
   for(int i = 0; i < n; i++)
      media += x[i];
   media /= (double)n;

   double num = 0.0, den = 0.0;
   for(int i = 0; i < n; i++)
     {
      double d = x[i] - media;
      den += d * d;
      if(i >= k)
         num += d * (x[i - k] - media);
     }

   return((den > 0.0) ? num / den : 0.0);
  }

//+------------------------------------------------------------------+
//| Resultado do teste de Ljung-Box                                  |
//+------------------------------------------------------------------+
struct ResultadoLjungBox
  {
   bool     valido;
   double   estatistica;   // Q
   double   pvalor;
   int      lags;          // h
   int      gl;            // graus de liberdade
   bool     ruido_branco;  // p > 0.05 => residuos sem autocorrelacao
  };

//+------------------------------------------------------------------+
//| TESTE DE LJUNG-BOX                                               |
//+------------------------------------------------------------------+
//|                                                                  |
//|  Verifica se os residuos do modelo ainda carregam autocorrelacao.|
//|  Se carregam, sobrou estrutura que o ARIMA nao capturou e o      |
//|  modelo esta mal especificado.                                   |
//|                                                                  |
//|    Q = n(n+2) * SOMA_{k=1..h} [ r_k^2 / (n-k) ]  ~  Qui2(h - m)  |
//|                                                                  |
//|  onde m = p + q e o numero de parametros ARMA estimados.         |
//|                                                                  |
//|  H0: residuos sao ruido branco (o que QUEREMOS nao rejeitar).    |
//|  p-valor ALTO (> 0,05) e o resultado desejavel aqui.             |
//|                                                                  |
//+------------------------------------------------------------------+
bool TesteLjungBox(const double &residuos[], const int h, const int n_par_arma,
                   ResultadoLjungBox &res)
  {
   res.valido = false;
   res.estatistica = 0.0;
   res.pvalor = -1.0;
   res.lags = h;
   res.gl = 0;
   res.ruido_branco = false;

   int n = ArraySize(residuos);
   if(n < h + 5 || h <= 0)
      return(false);

   int gl = h - n_par_arma;
   if(gl <= 0)
      return(false);

   double soma = 0.0;
   for(int k = 1; k <= h; k++)
     {
      double r = Autocorrelacao(residuos, k);
      soma += (r * r) / (double)(n - k);
     }

   double Q = (double)n * (double)(n + 2) * soma;

   int erro = 0;
   double cdf = MathCumulativeDistributionChiSquare(Q, (double)gl, erro);
   if(erro != 0)
      return(false);

   res.estatistica = Q;
   res.gl = gl;
   res.pvalor = 1.0 - cdf;
   res.ruido_branco = (res.pvalor > 0.05);
   res.valido = true;

   return(true);
  }

//+------------------------------------------------------------------+
//| Criterios de informacao                                          |
//+------------------------------------------------------------------+
//|                                                                  |
//|  Ambos penalizam a complexidade do modelo. Menor = melhor.       |
//|                                                                  |
//|    AIC = -2*logL + 2k                                            |
//|    BIC = -2*logL + k*ln(n)    (penaliza mais que o AIC)          |
//|                                                                  |
//|  'k' deve incluir TODOS os parametros estimados, inclusive a     |
//|  variancia dos residuos. Esquecer isso e um erro comum que       |
//|  desloca a comparacao entre modelos de tamanhos diferentes.      |
//|                                                                  |
//+------------------------------------------------------------------+
double CalcularAIC(const double log_verossimilhanca, const int k)
  {
   return(-2.0 * log_verossimilhanca + 2.0 * (double)k);
  }

double CalcularBIC(const double log_verossimilhanca, const int k, const int n)
  {
   if(n <= 0)
      return(DBL_MAX);
   return(-2.0 * log_verossimilhanca + (double)k * MathLog((double)n));
  }

//+------------------------------------------------------------------+
//| Media e variancia amostral                                       |
//+------------------------------------------------------------------+
double Media(const double &x[])
  {
   int n = ArraySize(x);
   if(n <= 0)
      return(0.0);

   double s = 0.0;
   for(int i = 0; i < n; i++)
      s += x[i];

   return(s / (double)n);
  }

double Variancia(const double &x[])
  {
   int n = ArraySize(x);
   if(n <= 1)
      return(0.0);

   double m = Media(x);
   double s = 0.0;
   for(int i = 0; i < n; i++)
      s += (x[i] - m) * (x[i] - m);

   return(s / (double)(n - 1));
  }

#endif // ALGOTRADINGLAB_ESTATISTICA_MQH
//+------------------------------------------------------------------+
