//+------------------------------------------------------------------+
//| Numerico.mqh                                                     |
//| Minimos quadrados ordinarios (MQO) sobre a ALGLIB. E a unica     |
//| entrada para algebra linear do projeto (ADF e ARIMA).            |
//+------------------------------------------------------------------+
#ifndef ALGOTRADINGLAB_NUMERICO_MQH
#define ALGOTRADINGLAB_NUMERICO_MQH

#include <Math\Alglib\alglib.mqh>

//--- Resolve (X'X) coeficientes = X'y. A constante, se houver, e uma coluna de 1.
//--- Devolve falso se X'X for singular.
bool MQO(CMatrixDouble &X, const double &y[], const int observacoes, const int parametros,
         double &coeficientes[], double &erros_padrao[], double &soma_quadrados_residuos,
         const bool calcular_erros_padrao = true)
  {
   soma_quadrados_residuos = 0.0;

   if(observacoes <= parametros || parametros <= 0 || observacoes <= 0)
      return(false);
   if(X.Rows() < observacoes || X.Cols() < parametros || ArraySize(y) < observacoes)
      return(false);

   //--- O solver da ALGLIB destroi a matriz que recebe; a copia serve para a inversa.
   CMatrixDouble XtX(parametros, parametros);
   CMatrixDouble XtX_para_inversa(parametros, parametros);
   double Xty[];
   ArrayResize(Xty, parametros);

   for(int i = 0; i < parametros; i++)
     {
      double soma_xy = 0.0;
      for(int t = 0; t < observacoes; t++)
         soma_xy += X.Get(t, i) * y[t];
      Xty[i] = soma_xy;

      for(int j = 0; j <= i; j++)
        {
         double soma = 0.0;
         for(int t = 0; t < observacoes; t++)
            soma += X.Get(t, i) * X.Get(t, j);

         XtX.Set(i, j, soma);
         XtX.Set(j, i, soma);
         XtX_para_inversa.Set(i, j, soma);
         XtX_para_inversa.Set(j, i, soma);
        }
     }

   int situacao = 0;
   CDenseSolverReportShell relatorio_solver;
   ArrayResize(coeficientes, parametros);
   ArrayInitialize(coeficientes, 0.0);

   CAlglib::RMatrixSolve(XtX, parametros, Xty, situacao, relatorio_solver, coeficientes);
   if(situacao <= 0 || ArraySize(coeficientes) < parametros)
      return(false);

   for(int t = 0; t < observacoes; t++)
     {
      double ajustado = 0.0;
      for(int i = 0; i < parametros; i++)
         ajustado += X.Get(t, i) * coeficientes[i];

      double residuo = y[t] - ajustado;
      soma_quadrados_residuos += residuo * residuo;
     }

   ArrayResize(erros_padrao, parametros);
   ArrayInitialize(erros_padrao, 0.0);
   if(!calcular_erros_padrao)
      return(true);

   //--- Var(coeficientes) = sigma2 (X'X)^-1, com sigma2 = SQR / (n - k)
   double sigma2 = soma_quadrados_residuos / (double)(observacoes - parametros);

   int situacao_inversa = 0;
   CMatInvReportShell relatorio_inversa;
   CAlglib::RMatrixInverse(XtX_para_inversa, parametros, situacao_inversa, relatorio_inversa);
   if(situacao_inversa <= 0)
      return(true);   // coeficientes valem; erros-padrao ficam em zero

   for(int i = 0; i < parametros; i++)
     {
      double variancia = sigma2 * XtX_para_inversa.Get(i, i);
      erros_padrao[i] = (variancia > 0.0) ? MathSqrt(variancia) : 0.0;
     }

   return(true);
  }

#endif
