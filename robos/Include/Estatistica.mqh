//+------------------------------------------------------------------+
//| Estatistica.mqh                                                  |
//| Teste ADF, teste de Ljung-Box, AIC/BIC, media, variancia e       |
//| percentil.                                                       |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_ESTATISTICA_MQH
#define ALGOTRADINGLAB_ESTATISTICA_MQH

#include "Numerico.mqh"
#include <Math\Stat\ChiSquare.mqh>

//--- Termos deterministicos da regressao do ADF (mudam o valor critico)
enum ENUM_ADF_DETERMINISTICO
  {
   ADF_SEM_CONSTANTE = 0,        // Sem constante
   ADF_CONSTANTE = 1,            // Com constante
   ADF_CONSTANTE_TENDENCIA = 2   // Constante e tendencia
  };

struct ResultadoADF
  {
   bool     valido;
   double   estatistica;        // estatistica t do coeficiente do nivel defasado
   double   valor_critico_5;    // valor critico a 5%
   int      defasagens;
   int      observacoes;
   bool     estacionaria;       // estatistica < valor critico: rejeita a raiz unitaria
  };

//--- Valor critico a 5% de MacKinnon (2010), tabela 2, N = 1: b0 + b1/T + b2/T^2 + b3/T^3
double ValorCriticoADF5(const ENUM_ADF_DETERMINISTICO deterministico, const int observacoes)
  {
   static double coeficientes[3][4] =
     {
        { -1.94100, -0.2686, -3.365,  31.223 },   // sem constante
        { -2.86154, -2.8903, -4.234, -40.040 },   // com constante
        { -3.41049, -4.3904, -9.036, -45.374 }    // constante e tendencia
     };

   if(observacoes <= 0)
      return(0.0);

   int linha = (int)deterministico;
   if(linha < 0 || linha > 2)
      linha = 1;

   double inverso = 1.0 / (double)observacoes;

   return(coeficientes[linha][0]
          + coeficientes[linha][1] * inverso
          + coeficientes[linha][2] * inverso * inverso
          + coeficientes[linha][3] * inverso * inverso * inverso);
  }

//--- dy(t) = gamma y(t-1) + [a] + [b t] + soma c_j dy(t-j) + e, para t >= inicio.
//--- Devolve a estatistica t de gamma e o AIC da regressao.
bool RegressaoADF(const double &y[], const ENUM_ADF_DETERMINISTICO deterministico,
                  const int defasagens, const int inicio,
                  double &estatistica, double &aic, int &observacoes)
  {
   int n = ArraySize(y);
   int primeiro = MathMax(inicio, defasagens + 1);
   observacoes = n - primeiro;
   if(observacoes < defasagens + 5)
      return(false);

   int termos_deterministicos = 0;
   if(deterministico == ADF_CONSTANTE)            termos_deterministicos = 1;
   if(deterministico == ADF_CONSTANTE_TENDENCIA)  termos_deterministicos = 2;

   int parametros = 1 + termos_deterministicos + defasagens;
   if(observacoes <= parametros)
      return(false);

   CMatrixDouble X(observacoes, parametros);
   double variacao[];
   ArrayResize(variacao, observacoes);

   for(int t = primeiro, linha = 0; t <= n - 1; t++, linha++)
     {
      variacao[linha] = y[t] - y[t - 1];
      int coluna = 0;
      X.Set(linha, coluna++, y[t - 1]);
      if(termos_deterministicos >= 1) X.Set(linha, coluna++, 1.0);
      if(termos_deterministicos >= 2) X.Set(linha, coluna++, (double)t);
      for(int j = 1; j <= defasagens; j++)
         X.Set(linha, coluna++, y[t - j] - y[t - j - 1]);
     }

   double coeficientes[], erros_padrao[], soma_quadrados = 0.0;
   if(!MQO(X, variacao, observacoes, parametros, coeficientes, erros_padrao, soma_quadrados, true))
      return(false);
   if(erros_padrao[0] <= 0.0 || soma_quadrados <= 0.0)
      return(false);

   estatistica = coeficientes[0] / erros_padrao[0];
   aic = (double)observacoes * MathLog(soma_quadrados / (double)observacoes) + 2.0 * (double)parametros;
   return(true);
  }

//--- Dickey-Fuller aumentado. H0: raiz unitaria (nao estacionaria).
//--- defasagens = -1 escolhe o numero de defasagens pelo AIC.
bool TesteADF(const double &y[], const ENUM_ADF_DETERMINISTICO deterministico,
              const int defasagens, ResultadoADF &resultado)
  {
   resultado.valido = false;
   resultado.estatistica = 0.0;
   resultado.defasagens = 0;
   resultado.observacoes = 0;
   resultado.estacionaria = false;

   int n = ArraySize(y);
   if(n < 20)
      return(false);

   //--- Maximo de defasagens pela regra de Schwert: 12 (T/100)^(1/4)
   int maximo = (int)MathFloor(12.0 * MathPow(n / 100.0, 0.25));
   maximo = MathMax(0, MathMin(maximo, (n - 10) / 4));

   int primeira = (defasagens >= 0) ? MathMin(defasagens, maximo) : 0;
   int ultima   = (defasagens >= 0) ? primeira : maximo;

   //--- As candidatas comparam o AIC sobre a mesma amostra (t > ultima).
   //--- Escolhida a defasagem, a estatistica usa toda a amostra disponivel.
   double melhor_aic = DBL_MAX;
   int    melhor_defasagem = -1;

   for(int k = primeira; k <= ultima; k++)
     {
      double estatistica_k = 0.0, aic_k = 0.0;
      int    observacoes_k = 0;
      if(!RegressaoADF(y, deterministico, k, ultima + 1, estatistica_k, aic_k, observacoes_k))
         continue;
      if(aic_k < melhor_aic)
        {
         melhor_aic = aic_k;
         melhor_defasagem = k;
        }
     }

   if(melhor_defasagem < 0)
      return(false);

   double estatistica = 0.0, aic = 0.0;
   int    observacoes = 0;
   if(!RegressaoADF(y, deterministico, melhor_defasagem, melhor_defasagem + 1, estatistica, aic, observacoes))
      return(false);

   resultado.estatistica = estatistica;
   resultado.defasagens = melhor_defasagem;
   resultado.observacoes = observacoes;
   resultado.valor_critico_5 = ValorCriticoADF5(deterministico, observacoes);
   resultado.estacionaria = (resultado.estatistica < resultado.valor_critico_5);
   resultado.valido = true;
   return(true);
  }

double Autocorrelacao(const double &x[], const int defasagem)
  {
   int n = ArraySize(x);
   if(n <= defasagem || defasagem < 0)
      return(0.0);

   double media = 0.0;
   for(int i = 0; i < n; i++)
      media += x[i];
   media /= (double)n;

   double numerador = 0.0, denominador = 0.0;
   for(int i = 0; i < n; i++)
     {
      double desvio = x[i] - media;
      denominador += desvio * desvio;
      if(i >= defasagem)
         numerador += desvio * (x[i - defasagem] - media);
     }

   return((denominador > 0.0) ? numerador / denominador : 0.0);
  }

struct ResultadoLjungBox
  {
   bool     valido;
   double   estatistica;          // Q
   double   pvalor;
   int      graus_liberdade;
   bool     ruido_branco;         // p > 0,05: sem autocorrelacao restante
  };

//--- Q = n(n+2) soma r_k^2/(n-k), k = 1..h, contra qui-quadrado com h - (p+q) graus de liberdade
bool TesteLjungBox(const double &residuos[], const int defasagens, const int parametros_arma,
                   ResultadoLjungBox &resultado)
  {
   resultado.valido = false;
   resultado.estatistica = 0.0;
   resultado.pvalor = -1.0;
   resultado.graus_liberdade = 0;
   resultado.ruido_branco = false;

   int n = ArraySize(residuos);
   if(n < defasagens + 5 || defasagens <= 0)
      return(false);

   int graus_liberdade = defasagens - parametros_arma;
   if(graus_liberdade <= 0)
      return(false);

   double soma = 0.0;
   for(int k = 1; k <= defasagens; k++)
     {
      double r = Autocorrelacao(residuos, k);
      soma += (r * r) / (double)(n - k);
     }

   double Q = (double)n * (double)(n + 2) * soma;

   int erro = 0;
   double acumulada = MathCumulativeDistributionChiSquare(Q, (double)graus_liberdade, erro);
   if(erro != 0)
      return(false);

   resultado.estatistica = Q;
   resultado.graus_liberdade = graus_liberdade;
   resultado.pvalor = 1.0 - acumulada;
   resultado.ruido_branco = (resultado.pvalor > 0.05);
   resultado.valido = true;
   return(true);
  }

//--- k inclui todos os parametros estimados, inclusive a variancia dos residuos
double CalcularAIC(const double log_verossimilhanca, const int parametros)
  {
   return(-2.0 * log_verossimilhanca + 2.0 * (double)parametros);
  }

double CalcularBIC(const double log_verossimilhanca, const int parametros, const int observacoes)
  {
   if(observacoes <= 0)
      return(DBL_MAX);
   return(-2.0 * log_verossimilhanca + (double)parametros * MathLog((double)observacoes));
  }

double Media(const double &x[])
  {
   int n = ArraySize(x);
   if(n <= 0)
      return(0.0);

   double soma = 0.0;
   for(int i = 0; i < n; i++)
      soma += x[i];

   return(soma / (double)n);
  }

double Variancia(const double &x[])
  {
   int n = ArraySize(x);
   if(n <= 1)
      return(0.0);

   double media = Media(x);
   double soma = 0.0;
   for(int i = 0; i < n; i++)
      soma += (x[i] - media) * (x[i] - media);

   return(soma / (double)(n - 1));
  }

//--- Percentil com interpolacao linear (0 a 100)
double Percentil(const double &x[], const double percentual)
  {
   int n = ArraySize(x);
   if(n <= 0)
      return(0.0);
   if(n == 1)
      return(x[0]);

   double ordenado[];
   ArrayResize(ordenado, n);
   ArrayCopy(ordenado, x);
   ArraySort(ordenado);

   double fracao = MathMax(0.0, MathMin(100.0, percentual)) / 100.0;
   double posicao = fracao * (double)(n - 1);

   int i = (int)MathFloor(posicao);
   double resto = posicao - (double)i;

   if(i >= n - 1)
      return(ordenado[n - 1]);

   return(ordenado[i] * (1.0 - resto) + ordenado[i + 1] * resto);
  }

#endif
