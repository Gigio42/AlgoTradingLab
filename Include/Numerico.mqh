//+------------------------------------------------------------------+
//|                                                     Numerico.mqh |
//|                            Trabalho de Graduacao - FATEC Indaiatuba|
//+------------------------------------------------------------------+
//|                                                                  |
//|  NUCLEO NUMERICO — Minimos Quadrados Ordinarios (MQO/OLS)        |
//|                                                                  |
//|  Este modulo e a UNICA porta de entrada para algebra linear no   |
//|  projeto. Todo o resto (ADF, ARIMA) resolve seus sistemas aqui.  |
//|  Backend: ALGLIB, que ja acompanha a instalacao do MetaTrader 5  |
//|  (MQL5\Include\Math\Alglib) — nao ha nada para instalar.         |
//|                                                                  |
//|  POR QUE MQO E NAO GRADIENTE DESCENDENTE:                        |
//|                                                                  |
//|  O gradiente descendente precisa de uma "taxa de aprendizado".   |
//|  O gradiente de uma regressao cresce com o QUADRADO da escala    |
//|  dos dados, entao a mesma taxa que converge para um ativo de     |
//|  R$ 36,00 diverge para um de R$ 5,00. O MQO resolve o sistema    |
//|  de equacoes normais de forma exata e em um unico passo:         |
//|  nao tem taxa de aprendizado, nao tem numero de iteracoes,       |
//|  nao tem risco de divergencia e o resultado nao depende da       |
//|  escala do ativo.                                                |
//|                                                                  |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_NUMERICO_MQH
#define ALGOTRADINGLAB_NUMERICO_MQH

#include <Math\Alglib\alglib.mqh>

//+------------------------------------------------------------------+
//| MQO — Regressao linear por Minimos Quadrados Ordinarios          |
//+------------------------------------------------------------------+
//|                                                                  |
//|  Estima o vetor c que minimiza  || X*c - y ||^2                  |
//|                                                                  |
//|  Resolve as equacoes normais:   (X'X) * c = X'y                  |
//|                                                                  |
//|  ENTRADA:                                                        |
//|    X    — matriz de desenho (n linhas x k colunas). Cada linha   |
//|           e uma observacao, cada coluna uma variavel explicativa.|
//|           A constante, se desejada, deve ser uma coluna de 1.0.  |
//|    y    — vetor dependente (n elementos)                         |
//|    n    — numero de observacoes                                  |
//|    k    — numero de parametros (colunas de X)                    |
//|                                                                  |
//|  SAIDA:                                                          |
//|    coef — coeficientes estimados (k elementos)                   |
//|    se   — erros-padrao de cada coeficiente (k elementos).        |
//|           Necessarios para a estatistica t do teste ADF.         |
//|    ssr  — soma dos quadrados dos residuos                        |
//|                                                                  |
//|  Retorna false se o sistema for singular ou mal condicionado     |
//|  (por exemplo, colunas colineares em X).                         |
//|                                                                  |
//+------------------------------------------------------------------+
bool MQO(CMatrixDouble &X, const double &y[], const int n, const int k,
         double &coef[], double &se[], double &ssr,
         const bool calcular_erros = true)
  {
   ssr = 0.0;

   //--- Precisamos de mais observacoes do que parametros para ter
   //--- graus de liberdade. Caso contrario o ajuste e degenerado.
   if(n <= k || k <= 0 || n <= 0)
      return(false);

   if(X.Rows() < n || X.Cols() < k || ArraySize(y) < n)
      return(false);

   //--- ── Monta X'X (k x k) e X'y (k) ──
   //--- X'X e simetrica, entao calculamos so o triangulo inferior
   //--- e espelhamos. Guardamos DUAS copias porque o solver da
   //--- ALGLIB consome (fatora) a matriz que recebe, e ainda
   //--- precisaremos dela intacta para inverter e obter os erros.
   CMatrixDouble XtX(k, k);
   CMatrixDouble XtX_para_inversa(k, k);

   double Xty[];
   ArrayResize(Xty, k);

   for(int i = 0; i < k; i++)
     {
      double soma_xy = 0.0;
      for(int t = 0; t < n; t++)
         soma_xy += X.Get(t, i) * y[t];
      Xty[i] = soma_xy;

      for(int j = 0; j <= i; j++)
        {
         double soma = 0.0;
         for(int t = 0; t < n; t++)
            soma += X.Get(t, i) * X.Get(t, j);

         XtX.Set(i, j, soma);
         XtX.Set(j, i, soma);
         XtX_para_inversa.Set(i, j, soma);
         XtX_para_inversa.Set(j, i, soma);
        }
     }

   //--- ── Resolve (X'X)c = X'y ──
   int info = 0;
   CDenseSolverReportShell rep;
   ArrayResize(coef, k);
   ArrayInitialize(coef, 0.0);

   CAlglib::RMatrixSolve(XtX, k, Xty, info, rep, coef);

   //--- info > 0 significa sucesso; <= 0 indica matriz singular
   if(info <= 0 || ArraySize(coef) < k)
      return(false);

   //--- ── Residuos e SSR ──
   for(int t = 0; t < n; t++)
     {
      double ajustado = 0.0;
      for(int i = 0; i < k; i++)
         ajustado += X.Get(t, i) * coef[i];

      double residuo = y[t] - ajustado;
      ssr += residuo * residuo;
     }

   //--- ── Erros-padrao (opcionais) ──
   //--- Var(c) = sigma^2 * (X'X)^-1, com sigma^2 = SSR / (n - k)
   ArrayResize(se, k);
   ArrayInitialize(se, 0.0);

   if(!calcular_erros)
      return(true);

   double sigma2 = ssr / (double)(n - k);

   int info_inv = 0;
   CMatInvReportShell rep_inv;
   CAlglib::RMatrixInverse(XtX_para_inversa, k, info_inv, rep_inv);

   if(info_inv <= 0)
     {
      //--- Coeficientes sao validos, mas nao conseguimos os erros.
      //--- Sinalizamos com se = 0 e deixamos o chamador decidir.
      return(true);
     }

   for(int i = 0; i < k; i++)
     {
      double variancia_i = sigma2 * XtX_para_inversa.Get(i, i);
      se[i] = (variancia_i > 0.0) ? MathSqrt(variancia_i) : 0.0;
     }

   return(true);
  }

#endif // ALGOTRADINGLAB_NUMERICO_MQH
//+------------------------------------------------------------------+
