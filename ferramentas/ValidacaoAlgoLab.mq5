//| Copia versionada (05/10/2026). Para rodar: copiar para MQL5\Scripts |
//--- Script TEMPORARIO de validacao numerica. Nao faz parte do projeto.
#include "..\Experts\AlgoTradingLab\Include\Arima.mqh"
#include "..\Experts\AlgoTradingLab\Include\Garch.mqh"

int g_h = INVALID_HANDLE;

void Log(string s)
  {
   Print(s);
   if(g_h != INVALID_HANDLE)
      FileWrite(g_h, s);
  }

//--- Normal(0,1) por Box-Muller
double Randn()
  {
   double u1 = (MathRand() + 1.0) / 32768.0;
   double u2 = (MathRand() + 1.0) / 32768.0;
   if(u1 <= 0.0) u1 = 1e-12;
   return(MathSqrt(-2.0 * MathLog(u1)) * MathCos(2.0 * M_PI * u2));
  }

void OnStart()
  {
   g_h = FileOpen("validacao_algolab.txt", FILE_WRITE | FILE_TXT | FILE_ANSI);
   MathSrand(20260803);

   Log("================ VALIDACAO NUMERICA ================");

   //=================================================================
   // 1) ADF deve DISTINGUIR passeio aleatorio de serie estacionaria
   //=================================================================
   Log("");
   Log("--- 1) TESTE ADF ---");
   int N = 2000;

   //--- (a) Passeio aleatorio: NAO deve rejeitar H0 (nao estacionaria)
   double rw[];
   ArrayResize(rw, N);
   rw[0] = 0.0;
   for(int i = 1; i < N; i++)
      rw[i] = rw[i - 1] + Randn();

   ResultadoADF a1;
   if(TesteADF(rw, ADF_CONSTANTE, -1, a1))
      Log(StringFormat("  Passeio aleatorio : stat=%8.4f  vc5=%8.4f  lags=%d  -> estacionaria=%s  [ESPERADO: nao]",
                       a1.estatistica, a1.vc_5pct, a1.lags, a1.estacionaria_5pct ? "SIM" : "nao"));

   //--- (b) AR(1) com phi=0.5: DEVE rejeitar H0 (estacionaria)
   double ar1[];
   ArrayResize(ar1, N);
   ar1[0] = 0.0;
   for(int i = 1; i < N; i++)
      ar1[i] = 0.5 * ar1[i - 1] + Randn();

   ResultadoADF a2;
   if(TesteADF(ar1, ADF_CONSTANTE, -1, a2))
      Log(StringFormat("  AR(1) phi=0.5     : stat=%8.4f  vc5=%8.4f  lags=%d  -> estacionaria=%s  [ESPERADO: SIM]",
                       a2.estatistica, a2.vc_5pct, a2.lags, a2.estacionaria_5pct ? "SIM" : "nao"));

   //--- (c) Primeira diferenca do passeio aleatorio: DEVE ser estacionaria
   double drw[];
   ArrayResize(drw, N - 1);
   for(int i = 0; i < N - 1; i++)
      drw[i] = rw[i + 1] - rw[i];

   ResultadoADF a3;
   if(TesteADF(drw, ADF_CONSTANTE, -1, a3))
      Log(StringFormat("  d(passeio), d=1   : stat=%8.4f  vc5=%8.4f  lags=%d  -> estacionaria=%s  [ESPERADO: SIM]",
                       a3.estatistica, a3.vc_5pct, a3.lags, a3.estacionaria_5pct ? "SIM" : "nao"));

   //=================================================================
   // 2) ARIMA deve RECUPERAR coeficientes conhecidos
   //=================================================================
   Log("");
   Log("--- 2) RECUPERACAO DE PARAMETROS ARMA(1,1) ---");
   Log("  Verdadeiro: phi1=0.600  theta1=0.400  c=0.000");

   int M = 4000;
   double z[], e[];
   ArrayResize(z, M);
   ArrayResize(e, M);
   e[0] = Randn();
   z[0] = e[0];
   for(int t = 1; t < M; t++)
     {
      e[t] = Randn();
      z[t] = 0.6 * z[t - 1] + e[t] + 0.4 * e[t - 1];
     }

   CArima m1;
   m1.Definir(1, 0, 1, true);
   if(m1.Ajustar(z))
      Log(StringFormat("  Estimado  : phi1=%.4f  theta1=%.4f  c=%.4f  sigma2=%.4f (verdadeiro 1.0)",
                       m1.Phi(0), m1.Theta(0), m1.Constante(), m1.Sigma2()));
   else
      Log("  FALHOU: " + m1.UltimoErro());

   //--- AR(2) puro (caminho q=0, MQO direto)
   Log("");
   Log("--- 2b) RECUPERACAO AR(2) (caminho q=0) ---");
   Log("  Verdadeiro: phi1=0.500  phi2=-0.300");
   double z2[];
   ArrayResize(z2, M);
   z2[0] = Randn(); z2[1] = Randn();
   for(int t = 2; t < M; t++)
      z2[t] = 0.5 * z2[t - 1] - 0.3 * z2[t - 2] + Randn();

   CArima m2;
   m2.Definir(2, 0, 0, true);
   if(m2.Ajustar(z2))
      Log(StringFormat("  Estimado  : phi1=%.4f  phi2=%.4f  c=%.4f",
                       m2.Phi(0), m2.Phi(1), m2.Constante()));
   else
      Log("  FALHOU: " + m2.UltimoErro());

   //=================================================================
   // 3) GARCH deve RECUPERAR omega, alpha, beta conhecidos
   //=================================================================
   Log("");
   Log("--- 3) RECUPERACAO DE PARAMETROS GARCH(1,1) ---");
   double w_true = 0.00001, a_true = 0.09, b_true = 0.89;
   Log(StringFormat("  Verdadeiro: omega=%.8f  alpha=%.4f  beta=%.4f  persist=%.4f",
                    w_true, a_true, b_true, a_true + b_true));

   int G = 6000;
   double eps[], s2[];
   ArrayResize(eps, G);
   ArrayResize(s2, G);
   s2[0] = w_true / (1.0 - a_true - b_true);
   eps[0] = MathSqrt(s2[0]) * Randn();
   for(int t = 1; t < G; t++)
     {
      s2[t] = w_true + a_true * eps[t - 1] * eps[t - 1] + b_true * s2[t - 1];
      eps[t] = MathSqrt(s2[t]) * Randn();
     }

   CGarch g1;
   g1.Definir(1, 1);
   g1.DefinirOtimizador(500);
   if(g1.Ajustar(eps))
      Log(StringFormat("  Estimado  : omega=%.8f  alpha=%.4f  beta=%.4f  persist=%.4f",
                       g1.Omega(), g1.Alpha(0), g1.Beta(0), g1.Persistencia()));
   else
      Log("  FALHOU: " + g1.UltimoErro());

   //--- A previsao 1 passo deve usar o termo ARCH (bug antigo zerava)
   double volp = g1.VolatilidadeProximoPeriodo();
   Log(StringFormat("  Vol prevista(h=1)=%.8f | Vol atual=%.8f | Vol longo prazo=%.8f",
                    volp, g1.VolatilidadeAtual(), MathSqrt(g1.VarianciaLongoPrazo())));

   //=================================================================
   // 4) PETR4 real: pipeline completo
   //=================================================================
   Log("");
   //--- Serie OFICIAL (B3 COTAHIST, so desdobramentos), e nao a PETR4 da
   //--- corretora. Trocado em 05/10/2026 (notas/INCERTEZAS.md, itens 33 e 42).
   Log("--- 4) PETR4_OFICIAL D1 (dados reais, B3 COTAHIST) ---");
   double close[];
   int copiados = CopyClose("PETR4_OFICIAL", PERIOD_D1, 1, 500, close);
   datetime t_ult[];
   if(CopyTime("PETR4_OFICIAL", PERIOD_D1, 1, 1, t_ult) == 1)
      Log("  Ultima barra usada: " + TimeToString(t_ult[0], TIME_DATE));
   Log(StringFormat("  Barras copiadas: %d", copiados));

   if(copiados > 250)
     {
      //--- log-precos
      double lp[];
      ArrayResize(lp, copiados);
      for(int i = 0; i < copiados; i++)
         lp[i] = MathLog(close[i]);

      ResultadoADF ad0, ad1;
      if(TesteADF(lp, ADF_CONSTANTE, -1, ad0))
         Log(StringFormat("  ADF log-preco  (d=0): stat=%8.4f vc5=%8.4f -> estacionaria=%s",
                          ad0.estatistica, ad0.vc_5pct, ad0.estacionaria_5pct ? "SIM" : "nao"));

      double dlp[];
      ArrayResize(dlp, copiados - 1);
      for(int i = 0; i < copiados - 1; i++)
         dlp[i] = lp[i + 1] - lp[i];

      if(TesteADF(dlp, ADF_CONSTANTE, -1, ad1))
         Log(StringFormat("  ADF log-retorno(d=1): stat=%8.4f vc5=%8.4f -> estacionaria=%s",
                          ad1.estatistica, ad1.vc_5pct, ad1.estacionaria_5pct ? "SIM" : "nao"));

      CArima ap;
      ap.Definir(1, 1, 1, true);
      if(ap.Ajustar(lp))
        {
         Log("  " + ap.Descricao());

         double r[];
         if(ap.ObterResiduos(r))
           {
            Log(StringFormat("  Residuos validos: %d | desvio-padrao=%.6f",
                             ArraySize(r), MathSqrt(Variancia(r))));

            ResultadoLjungBox lb;
            if(TesteLjungBox(r, 10, 2, lb))
               Log(StringFormat("  Ljung-Box(10): Q=%.3f gl=%d p=%.4f -> ruido branco=%s",
                                lb.estatistica, lb.gl, lb.pvalor, lb.ruido_branco ? "SIM" : "nao"));

            CGarch gp;
            gp.Definir(1, 1);
            gp.DefinirOtimizador(500);
            if(gp.Ajustar(r))
              {
               Log("  " + gp.Descricao());
               Log(StringFormat("  >>> Vol diaria prevista = %.6f  (= %.3f%% ao dia)",
                                gp.VolatilidadeProximoPeriodo(),
                                gp.VolatilidadeProximoPeriodo() * 100.0));

               double zp[];
               if(gp.ObterResiduosPadronizados(zp))
                 {
                  int nz = ArraySize(zp);
                  double zp2[];
                  ArrayResize(zp2, nz);
                  for(int i = 0; i < nz; i++)
                     zp2[i] = zp[i] * zp[i];

                  ResultadoLjungBox lb2;
                  if(TesteLjungBox(zp2, 10, 2, lb2))
                     Log(StringFormat("  Ljung-Box nos residuos padronizados^2: Q=%.3f p=%.4f -> heterocedasticidade capturada=%s",
                                      lb2.estatistica, lb2.pvalor, lb2.ruido_branco ? "SIM" : "nao"));
                 }
              }
            else
               Log("  GARCH FALHOU: " + gp.UltimoErro());
           }
        }
      else
         Log("  ARIMA FALHOU: " + ap.UltimoErro());
     }
   else
      Log("  Historico PETR4_OFICIAL insuficiente.");

   Log("");
   Log("================ FIM ================");

   if(g_h != INVALID_HANDLE)
      FileClose(g_h);
  }
