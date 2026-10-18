//| Copia versionada (15/10/2026). Para rodar: ferramentas/scripts/validar_mv.sh |
//|  Roda como EA no TESTADOR (o calculo e todo no OnInit), porque   |
//|  script pelo [StartUp] nao abre com o perfil de graficos cheio   |
//|  (notas/INCERTEZAS.md, item 54), como o ValidarGarchT_EA.        |
//+------------------------------------------------------------------+
//| Comparacao Hannan-Rissanen x maxima verossimilhanca condicional  |
//+------------------------------------------------------------------+
//|  Passos 2 e 3 do PENDENCIAS.md, item 1. Decide (passo 4) se a    |
//|  estimacao por maxima verossimilhanca vira o padrao do EA, ANTES  |
//|  de qualquer teste de mercado.                                   |
//|                                                                  |
//|  1) As mesmas series da Tabela 1 (mesma semente e mesma ordem de |
//|     sorteio do ValidacaoAlgoLab): ARMA(1,1) e AR(2), N = 4000.   |
//|  2) Monte Carlo com janelas do tamanho que o robo usa (240):     |
//|     erro quadratico medio dos coeficientes, 300 replicas cada,   |
//|     em ARMA(1,1), MA(1), AR(1) fraco e ARMA(1,1) quase nulo.      |
//|  3) Acerto da ordem pelo AIC (grade 0..4 x 0..4, aquecimento     |
//|     comum 4, como no EA), 150 replicas de ARMA(1,1) e de AR(1).  |
//|  4) Tempo medio por ajuste, janela 240.                          |
//|  5) PETR4_OFICIAL, 500 pregoes: ARIMA(1,1,1) pelos dois metodos. |
//+------------------------------------------------------------------+
#include "AlgoTradingLab\Include\Arima.mqh"   // copiado para MQL5\Experts pelo validar_mv.sh

int g_h = INVALID_HANDLE;

void Log(string s)
  {
   Print(s);
   if(g_h != INVALID_HANDLE)
      FileWrite(g_h, s);
  }

//--- Normal(0,1) por Box-Muller (o mesmo do ValidacaoAlgoLab)
double Randn()
  {
   double u1 = (MathRand() + 1.0) / 32768.0;
   double u2 = (MathRand() + 1.0) / 32768.0;
   if(u1 <= 0.0) u1 = 1e-12;
   return(MathSqrt(-2.0 * MathLog(u1)) * MathCos(2.0 * M_PI * u2));
  }

//--- ARMA(p<=1, q<=1) com 100 valores de aquecimento descartados
void GerarArma11(const int n, const double phi, const double theta, double &z[])
  {
   int tot = n + 100;
   double zz[], e[];
   ArrayResize(zz, tot);
   ArrayResize(e, tot);
   e[0] = Randn();
   zz[0] = e[0];
   for(int t = 1; t < tot; t++)
     {
      e[t] = Randn();
      zz[t] = phi * zz[t - 1] + e[t] + theta * e[t - 1];
     }
   ArrayResize(z, n);
   for(int i = 0; i < n; i++)
      z[i] = zz[100 + i];
  }

bool Ajusta(const double &z[], const int p, const int q, const ENUM_ESTIMACAO_ARIMA met,
            double &phi, double &theta, double &aic)
  {
   CArima m;
   m.DefinirMetodo(met);
   m.Definir(p, 0, q, true);
   m.DefinirAquecimentoMinimo(4);
   if(!m.Ajustar(z))
      return(false);
   phi = m.Phi(0);
   theta = m.Theta(0);
   aic = m.AIC();
   return(true);
  }

//--- Monte Carlo de um caso: imprime RMSE de phi e theta pelos dois metodos
void MonteCarlo(const string nome, const int p, const int q, const double phi0, const double theta0,
                const int reps, const int n)
  {
   double s_phi[2] = {0, 0}, s_th[2] = {0, 0};
   int ok[2] = {0, 0}, melhor_mv = 0, comuns = 0;
   int fb0 = CArima::s_mv_fallback, tt0 = CArima::s_mv_tentativas;
   double z[];
   for(int r = 0; r < reps; r++)
     {
      GerarArma11(n, phi0, theta0, z);
      double ph[2], th[2], ai[2];
      bool b[2];
      for(int k = 0; k < 2; k++)
        {
         b[k] = Ajusta(z, p, q, (ENUM_ESTIMACAO_ARIMA)k, ph[k], th[k], ai[k]);
         if(b[k])
           {
            ok[k]++;
            s_phi[k] += (ph[k] - phi0) * (ph[k] - phi0);
            s_th[k]  += (th[k] - theta0) * (th[k] - theta0);
           }
        }
      if(b[0] && b[1])
        {
         comuns++;
         if(ai[1] <= ai[0] + 1e-9)
            melhor_mv++;
        }
     }
   Log(StringFormat("  %-30s HR: rmse_phi=%.4f rmse_theta=%.4f (ok %d) | MV: rmse_phi=%.4f rmse_theta=%.4f (ok %d) | AIC_MV<=AIC_HR em %d de %d | MV voltou ao HR em %d de %d",
                    nome,
                    p > 0 ? MathSqrt(s_phi[0] / MathMax(ok[0], 1)) : 0.0,
                    q > 0 ? MathSqrt(s_th[0] / MathMax(ok[0], 1)) : 0.0, ok[0],
                    p > 0 ? MathSqrt(s_phi[1] / MathMax(ok[1], 1)) : 0.0,
                    q > 0 ? MathSqrt(s_th[1] / MathMax(ok[1], 1)) : 0.0, ok[1],
                    melhor_mv, comuns,
                    CArima::s_mv_fallback - fb0, CArima::s_mv_tentativas - tt0));
  }

//--- Selecao de ordens pelo AIC: quantas vezes acerta (p0,q0)
void Selecao(const string nome, const int p0, const int q0, const double phi0, const double theta0,
             const int reps, const int n)
  {
   int acertos[2] = {0, 0};
   double z[];
   for(int r = 0; r < reps; r++)
     {
      GerarArma11(n, phi0, theta0, z);
      for(int k = 0; k < 2; k++)
        {
         double melhor = DBL_MAX;
         int bp = -1, bq = -1;
         for(int p = 0; p <= 4; p++)
            for(int q = 0; q <= 4; q++)
              {
               double ph, th, ai;
               if(Ajusta(z, p, q, (ENUM_ESTIMACAO_ARIMA)k, ph, th, ai) && ai < melhor)
                 {
                  melhor = ai;
                  bp = p;
                  bq = q;
                 }
              }
         if(bp == p0 && bq == q0)
            acertos[k]++;
        }
     }
   Log(StringFormat("  %-30s ordem certa (%d,%d): HR %d de %d (%.1f%%) | MV %d de %d (%.1f%%)",
                    nome, p0, q0, acertos[0], reps, 100.0 * acertos[0] / reps,
                    acertos[1], reps, 100.0 * acertos[1] / reps));
  }

int OnInit()
  {
   g_h = FileOpen("AlgoLab\\validacao_mv_arima.txt", FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   MathSrand(20260803);
   Log("========= HANNAN-RISSANEN x MAXIMA VEROSSIMILHANCA CONDICIONAL =========");

   //--- 1) As series da Tabela 1. Reproduz a ordem de sorteio do
   //--- ValidacaoAlgoLab: primeiro as tres series do ADF (2000 + 2000 numeros
   //--- normais), depois o ARMA(1,1) e o AR(2), com N = 4000.
   int N = 2000;
   for(int i = 1; i < N; i++) Randn();       // passeio aleatorio
   for(int i = 1; i < N; i++) Randn();       // AR(1)
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
   double z2[];
   ArrayResize(z2, M);
   z2[0] = Randn(); z2[1] = Randn();
   for(int t = 2; t < M; t++)
      z2[t] = 0.5 * z2[t - 1] - 0.3 * z2[t - 2] + Randn();

   Log("");
   Log("--- 1) Series da Tabela 1 (N = 4000) ---");
   Log("  ARMA(1,1) verdadeiro: phi1=0.600 theta1=0.400 | AR(2) verdadeiro: phi1=0.500 phi2=-0.300");
   for(int k = 0; k < 2; k++)
     {
      CArima a, b;
      a.DefinirMetodo((ENUM_ESTIMACAO_ARIMA)k);
      b.DefinirMetodo((ENUM_ESTIMACAO_ARIMA)k);
      a.Definir(1, 0, 1, true);
      b.Definir(2, 0, 0, true);
      bool oa = a.Ajustar(z), ob = b.Ajustar(z2);
      Log(StringFormat("  %s: ARMA(1,1) phi1=%.4f theta1=%.4f logL=%.3f | AR(2) phi1=%.4f phi2=%.4f logL=%.3f",
                       k == 0 ? "HR" : "MV",
                       oa ? a.Phi(0) : 0.0, oa ? a.Theta(0) : 0.0, oa ? a.LogVerossimilhanca() : 0.0,
                       ob ? b.Phi(0) : 0.0, ob ? b.Phi(1) : 0.0, ob ? b.LogVerossimilhanca() : 0.0));
     }

   Log("");
   Log("--- 2) Monte Carlo, janela de 240, 300 replicas por caso ---");
   MonteCarlo("ARMA(1,1) phi=0.6 theta=0.4", 1, 1, 0.6, 0.4, 300, 240);
   MonteCarlo("MA(1) theta=0.5", 0, 1, 0.0, 0.5, 300, 240);
   MonteCarlo("AR(1) phi=0.1 (fraco)", 1, 0, 0.1, 0.0, 300, 240);
   MonteCarlo("ARMA(1,1) phi=0.3 theta=-0.2", 1, 1, 0.3, -0.2, 300, 240);

   Log("");
   Log("--- 3) Selecao de ordens pelo AIC (grade 0..4 x 0..4), janela de 240 ---");
   Selecao("ARMA(1,1) phi=0.6 theta=0.4", 1, 1, 0.6, 0.4, 150, 240);
   Selecao("AR(1) phi=0.3", 1, 0, 0.3, 0.0, 150, 240);

   Log("");
   Log("--- 4) Tempo medio por ajuste, janela de 240 (200 ajustes por celula) ---");
   GerarArma11(240, 0.3, -0.2, z);
   int ordens[][2] = {{1, 0}, {1, 1}, {2, 2}, {4, 4}};
   for(int o = 0; o < 4; o++)
     {
      double us[2];
      for(int k = 0; k < 2; k++)
        {
         ulong t0 = GetMicrosecondCount();
         for(int r = 0; r < 200; r++)
           {
            double ph, th, ai;
            Ajusta(z, ordens[o][0], ordens[o][1], (ENUM_ESTIMACAO_ARIMA)k, ph, th, ai);
           }
         us[k] = (double)(GetMicrosecondCount() - t0) / 200.0;
        }
      Log(StringFormat("  ARMA(%d,%d): HR %.0f us | MV %.0f us | razao %.1fx",
                       ordens[o][0], ordens[o][1], us[0], us[1], us[1] / MathMax(us[0], 1.0)));
     }

   Log("");
   Log("--- 5) PETR4_OFICIAL, ate 500 pregoes disponiveis no testador, ARIMA(1,1,1) com constante ---");
   double close[];
   int n = CopyClose("PETR4_OFICIAL", PERIOD_D1, 1, 500, close);
   Log(StringFormat("  Pregoes copiados: %d", n));
   if(n > 250)
     {
      double lp[];
      ArrayResize(lp, n);
      for(int i = 0; i < n; i++)
         lp[i] = MathLog(close[i]);
      for(int k = 0; k < 2; k++)
        {
         CArima ap;
         ap.DefinirMetodo((ENUM_ESTIMACAO_ARIMA)k);
         ap.Definir(1, 1, 1, true);
         if(ap.Ajustar(lp))
            Log(StringFormat("  %s: %s", k == 0 ? "HR" : "MV", ap.Descricao()));
         else
            Log("  falhou: " + ap.UltimoErro());
        }
     }
   else
      Log("  Historico PETR4_OFICIAL insuficiente.");

   Log("");
   Log(StringFormat("Total: MV tentado %d vezes, voltou ao HR em %d (%.2f%%)",
                    CArima::s_mv_tentativas, CArima::s_mv_fallback,
                    100.0 * CArima::s_mv_fallback / MathMax(CArima::s_mv_tentativas, 1)));
   Log("================ FIM ================");
   if(g_h != INVALID_HANDLE)
      FileClose(g_h);
   return(INIT_SUCCEEDED);
  }

void OnTick() {}
