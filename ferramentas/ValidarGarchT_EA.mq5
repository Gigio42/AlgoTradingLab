//+------------------------------------------------------------------+
//|                                           ValidarGarchT_EA.mq5   |
//|                            Trabalho de Graduacao - FATEC Indaiatuba|
//+------------------------------------------------------------------+
//|                                                                  |
//|  Validacao do GARCH(1,1) com erros t de Student (13/10/2026)     |
//|  em series sinteticas com resposta conhecida, no mesmo espirito  |
//|  da validacao do GARCH normal (ValidacaoAlgoLab.mq5).            |
//|                                                                  |
//|  Roda como EA no TESTADOR (o calculo e todo no OnInit), porque   |
//|  script pelo [StartUp] nao abre com o perfil de graficos cheio   |
//|  (notas/INCERTEZAS.md, item 54). Saida em                        |
//|  Common/Files/AlgoLab/validacao_garch_t.txt.                     |
//|                                                                  |
//|  Gerador proprio de 30 bits: o MathRand() tem 15 bits, e uma     |
//|  uniforme grossa corta as caudas, que e justamente o que se      |
//|  quer testar aqui. A t sai de normais: t = z / raiz(qui2/nu),    |
//|  com nu inteiro, padronizada para variancia 1.                   |
//|                                                                  |
//|  Casos:                                                          |
//|   A) erros t (nu=5), n=2000: ajuste normal e t                   |
//|   B) erros normais, n=2000: o ajuste t deve dar nu grande        |
//|   C) 100 replicas de erros t (nu=5) com n=236 e n=116, os        |
//|      tamanhos de janela usados pelo EA: mediana e quartis        |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "TG - FATEC Indaiatuba (ADS)"
#property version   "1.00"

#include "AlgoTradingLab\Include\Garch.mqh"   // copiado para MQL5\Experts pelo validar_garch_t.sh

const double W_VERD = 1.0e-5, A_VERD = 0.09, B_VERD = 0.89;
const int    NU_VERD = 5;
int          g_fh = INVALID_HANDLE;

//--- Uniforme em (0,1) com 30 bits
double Unif(void)
  {
   return(((double)MathRand() * 32768.0 + (double)MathRand() + 0.5) / 1073741824.0);
  }

//--- Normal padrao (Box-Muller)
double Normal(void)
  {
   return(MathSqrt(-2.0 * MathLog(Unif())) * MathCos(2.0 * M_PI * Unif()));
  }

//--- t de Student padronizada (variancia 1); nu <= 0 devolve normal
double Choque(const int nu)
  {
   if(nu <= 0)
      return(Normal());
   double qui2 = 0.0;
   for(int i = 0; i < nu; i++)
     {
      double z = Normal();
      qui2 += z * z;
     }
   double t = Normal() / MathSqrt(qui2 / (double)nu);
   return(t * MathSqrt((double)(nu - 2) / (double)nu));
  }

//--- Serie GARCH(1,1) com aquecimento de 500 observacoes descartadas
void Simular(const int n, const int nu, double &eps[])
  {
   ArrayResize(eps, n);
   double s2 = W_VERD / (1.0 - A_VERD - B_VERD), e_ant = 0.0;
   for(int t = -500; t < n; t++)
     {
      s2 = W_VERD + A_VERD * e_ant * e_ant + B_VERD * s2;
      double e = MathSqrt(s2) * Choque(nu);
      if(t >= 0)
         eps[t] = e;
      e_ant = e;
     }
  }

void Escrever(const string s)
  {
   Print(s);
   if(g_fh != INVALID_HANDLE)
      FileWriteString(g_fh, s + "\r\n");
  }

string Linha(const string rotulo, CGarch &g)
  {
   if(!g.Ajustado())
      return(rotulo + ": nao ajustou (" + g.UltimoErro() + ")");
   return(StringFormat("%-22s omega=%.3e alpha=%.4f beta=%.4f persist=%.4f nu=%7.2f logL=%9.2f AIC=%9.2f",
                       rotulo, g.Omega(), g.Alfa(0), g.Beta(0), g.Persistencia(),
                       g.GrausLiberdade(), g.LogVerossimilhanca(), g.AIC()));
  }

double Quantil(double &x[], const double p)
  {
   int n = ArraySize(x);
   if(n == 0)
      return(0.0);
   ArraySort(x);
   double pos = p * (n - 1);
   int i = (int)MathFloor(pos);
   if(i >= n - 1)
      return(x[n - 1]);
   return(x[i] + (pos - i) * (x[i + 1] - x[i]));
  }

void Replicas(const int n, const int r)
  {
   double nu_t[], a_t[], b_t[], a_n[], b_n[];
   int ok_t = 0, ok_n = 0, no_teto = 0, no_piso = 0, t_melhor_aic = 0, ambos = 0;
   for(int k = 0; k < r; k++)
     {
      double eps[];
      Simular(n, NU_VERD, eps);
      CGarch gn, gt;
      gn.Definir(1, 1); gn.DefinirOtimizador(300);
      gt.Definir(1, 1); gt.DefinirOtimizador(300); gt.DefinirDistribuicao(DISTRIBUICAO_STUDENT);
      bool bn = gn.Ajustar(eps), bt = gt.Ajustar(eps);
      if(bn)
        {
         ArrayResize(a_n, ok_n + 1); ArrayResize(b_n, ok_n + 1);
         a_n[ok_n] = gn.Alfa(0); b_n[ok_n] = gn.Beta(0); ok_n++;
        }
      if(bt)
        {
         ArrayResize(nu_t, ok_t + 1); ArrayResize(a_t, ok_t + 1); ArrayResize(b_t, ok_t + 1);
         nu_t[ok_t] = gt.GrausLiberdade(); a_t[ok_t] = gt.Alfa(0); b_t[ok_t] = gt.Beta(0); ok_t++;
         if(gt.GrausLiberdade() > 199.0) no_teto++;
         if(gt.GrausLiberdade() < 2.3) no_piso++;
        }
      if(bn && bt)
        {
         ambos++;
         if(gt.AIC() < gn.AIC()) t_melhor_aic++;
        }
     }
   Escrever(StringFormat("  n=%d, %d replicas (verdade: alpha=%.2f beta=%.2f nu=%d)", n, r, A_VERD, B_VERD, NU_VERD));
   Escrever(StringFormat("    t:      ajustou %d | nu mediana %.2f (quartis %.2f a %.2f) | nu no teto (200) %d | no piso %d",
                         ok_t, Quantil(nu_t, 0.5), Quantil(nu_t, 0.25), Quantil(nu_t, 0.75), no_teto, no_piso));
   Escrever(StringFormat("    t:      alpha mediana %.4f (%.4f a %.4f) | beta mediana %.4f (%.4f a %.4f)",
                         Quantil(a_t, 0.5), Quantil(a_t, 0.25), Quantil(a_t, 0.75),
                         Quantil(b_t, 0.5), Quantil(b_t, 0.25), Quantil(b_t, 0.75)));
   Escrever(StringFormat("    normal: ajustou %d | alpha mediana %.4f (%.4f a %.4f) | beta mediana %.4f (%.4f a %.4f)",
                         ok_n, Quantil(a_n, 0.5), Quantil(a_n, 0.25), Quantil(a_n, 0.75),
                         Quantil(b_n, 0.5), Quantil(b_n, 0.25), Quantil(b_n, 0.75)));
   Escrever(StringFormat("    AIC menor com a t em %d de %d", t_melhor_aic, ambos));
  }

int OnInit()
  {
   MathSrand(20261013);
   g_fh = FileOpen("AlgoLab\\validacao_garch_t.txt", FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);

   Escrever("VALIDACAO DO GARCH(1,1) COM ERROS t DE STUDENT (semente 20261013)");
   Escrever(StringFormat("Verdade: omega=%.2e alpha=%.2f beta=%.2f persist=%.2f", W_VERD, A_VERD, B_VERD, A_VERD + B_VERD));
   Escrever("");

   double eps[];
   CGarch gn, gt;
   gn.Definir(1, 1); gn.DefinirOtimizador(300);
   gt.Definir(1, 1); gt.DefinirOtimizador(300); gt.DefinirDistribuicao(DISTRIBUICAO_STUDENT);

   Escrever(StringFormat("A) erros t com nu=%d, n=2000", NU_VERD));
   Simular(2000, NU_VERD, eps);
   gn.Ajustar(eps); gt.Ajustar(eps);
   Escrever(Linha("  ajuste normal", gn));
   Escrever(Linha("  ajuste t", gt));
   Escrever("");

   Escrever("B) erros normais, n=2000 (o ajuste t deve dar nu grande)");
   Simular(2000, 0, eps);
   gn.Ajustar(eps); gt.Ajustar(eps);
   Escrever(Linha("  ajuste normal", gn));
   Escrever(Linha("  ajuste t", gt));
   Escrever("");

   Escrever("C) replicas nos tamanhos de janela do EA (residuos de 240 e 120 barras)");
   Replicas(236, 100);
   Replicas(116, 100);

   if(g_fh != INVALID_HANDLE)
      FileClose(g_fh);
   return(INIT_SUCCEEDED);
  }

void OnTick() {}
//+------------------------------------------------------------------+
