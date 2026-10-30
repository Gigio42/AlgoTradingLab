//| Copia versionada (15/10/2026). Para rodar: ferramentas/scripts/verificar_mv.sh |
//+------------------------------------------------------------------+
//| A maxima verossimilhanca do ARIMA esta certa? E por que o AIC    |
//| escolhe pior com ela?                                            |
//+------------------------------------------------------------------+
//|  Roda como EA no TESTADOR (calculo no OnInit), como os outros    |
//|  validadores (perfil de graficos cheio, INCERTEZAS item 54).     |
//|                                                                  |
//|  1) Otimizador x busca exaustiva: ARMA(1,1) sem constante, janela|
//|     de 240, 20 series. A soma dos residuos ao quadrado (SSR) e   |
//|     calculada numa grade de 397 x 397 valores de (phi, theta) em |
//|     (-0,99; 0,99). A MV tem de chegar ao minimo da grade (ou     |
//|     abaixo, por ser continua) e nunca acima do HR.               |
//|  2) Quais ordens cada metodo escolhe (AR(1) phi=0,3, 150 series):|
//|     as 5 mais escolhidas pelo HR com AIC e pela MV com AIC, AICc |
//|     e BIC; e quanto a log-verossimilhanca do maior modelo, (4,4),|
//|     sobe em relacao ao verdadeiro, em cada metodo.               |
//+------------------------------------------------------------------+
#include "AlgoTradingLab\robos\Include\Arima.mqh"

int g_h = INVALID_HANDLE;
void Log(string s) { Print(s); if(g_h != INVALID_HANDLE) FileWrite(g_h, s); }

double Randn()
  {
   double u1 = (MathRand() + 1.0) / 32768.0;
   double u2 = (MathRand() + 1.0) / 32768.0;
   return(MathSqrt(-2.0 * MathLog(u1)) * MathCos(2.0 * M_PI * u2));
  }

void GerarArma11(const int n, const double phi, const double theta, double &z[])
  {
   int tot = n + 100;
   double zz[], e[];
   ArrayResize(zz, tot); ArrayResize(e, tot);
   e[0] = Randn(); zz[0] = e[0];
   for(int t = 1; t < tot; t++) { e[t] = Randn(); zz[t] = phi * zz[t - 1] + e[t] + theta * e[t - 1]; }
   ArrayResize(z, n);
   for(int i = 0; i < n; i++) z[i] = zz[100 + i];
  }

//--- ajusta (p,0,q) com constante e aquecimento comum 4, como no EA
bool Ajusta(const double &z[], const int p, const int q, const ENUM_ESTIMACAO_ARIMA met,
            double &aic, double &aicc, double &bic, double &ll)
  {
   CArima m;
   m.DefinirEstimacao(met);
   m.Definir(p, 0, q, true);
   m.DefinirAquecimentoMinimo(4);
   if(!m.Ajustar(z)) return(false);
   aic = m.AIC(); bic = m.BIC(); ll = m.LogVerossimilhanca();
   int k = m.NumParametros(), n = m.ObservacoesEfetivas();
   aicc = aic + 2.0 * k * (k + 1) / MathMax(1.0, (double)(n - k - 1));
   return(true);
  }

int OnInit()
  {
   g_h = FileOpen("AlgoLab\\verificacao_mv.txt", FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   MathSrand(20261015);
   Log("========= VERIFICACAO DA MAXIMA VEROSSIMILHANCA DO ARIMA =========");

   //=== 1) Otimizador x busca exaustiva ===============================
   Log("");
   Log("--- 1) ARMA(1,1) sem constante, janela 240: SSR do HR, da MV e minimo da grade 397x397 ---");
   Log("  serie  verdadeiro(phi,theta)   HR(phi,theta) SSR_HR | MV(phi,theta) SSR_MV | grade(phi,theta) SSR_grade | MV-grade");
   int pior = 0;
   double maior_dif = -1e9;
   for(int s = 0; s < 20; s++)
     {
      double phi0 = (s % 2 == 0) ? 0.6 : 0.3, th0 = (s % 2 == 0) ? 0.4 : -0.2;
      double z[];
      GerarArma11(241, phi0, th0, z);
      //--- d = 1 sobre a serie acumulada: o EA so permite "sem constante" com d >= 1
      double y[];
      ArrayResize(y, 241);
      y[0] = 0.0;
      for(int i = 1; i < 241; i++) y[i] = y[i - 1] + z[i];
      double ph[2], th[2], ssr[2];
      CArima ref;
      for(int k = 0; k < 2; k++)
        {
         CArima m;
         m.DefinirEstimacao((ENUM_ESTIMACAO_ARIMA)k);
         m.Definir(1, 1, 1, false);
         m.Ajustar(y);
         ph[k] = m.Phi(0); th[k] = m.Theta(0);
         ssr[k] = m.Sigma2() * m.ObservacoesEfetivas();
        }
      //--- mesma funcao objetivo, avaliada na grade
      CDadosVerossimilhancaArima d;
      d.tamanho = 240;
      ArrayResize(d.serie, 240);
      for(int i = 0; i < 240; i++) d.serie[i] = y[i + 1] - y[i];
      d.p = 1; d.q = 1; d.com_constante = false; d.inicio_recursao = 1; d.inicio_soma = 1;
      double best = DBL_MAX, bp = 0, bq = 0, a[1], b[1];
      for(int i = -198; i <= 198; i++)
         for(int j = -198; j <= 198; j++)
           {
            a[0] = i * 0.005; b[0] = j * 0.005;
            double v = SomaQuadradosResiduosArima(d, 0.0, a, b);
            if(v < best) { best = v; bp = a[0]; bq = b[0]; }
           }
      double dif = ssr[1] - best;
      if(dif > 1e-6 * best) pior++;
      maior_dif = MathMax(maior_dif, dif / best);
      Log(StringFormat("  %2d     (%.1f, %+.1f)        (%+.3f, %+.3f) %.4f | (%+.3f, %+.3f) %.4f | (%+.3f, %+.3f) %.4f | %+.2e",
                       s, phi0, th0, ph[0], th[0], ssr[0], ph[1], th[1], ssr[1], bp, bq, best, dif));
     }
   Log(StringFormat("  MV acima do minimo da grade (por mais de 1e-6 relativo) em %d de 20; maior diferenca relativa %.2e",
                    pior, maior_dif));

   //=== 2) Quais ordens cada metodo escolhe ===========================
   Log("");
   Log("--- 2) AR(1) phi=0,3, janela 240, 150 series: ordens escolhidas ---");
   int cont[4][25];
   ArrayInitialize(cont, 0);
   double ganho_hr = 0, ganho_mv = 0;
   int n_ganho = 0;
   for(int r = 0; r < 150; r++)
     {
      double z[];
      GerarArma11(240, 0.3, 0.0, z);
      double melhor[4] = {DBL_MAX, DBL_MAX, DBL_MAX, DBL_MAX};
      int esc[4] = {-1, -1, -1, -1};
      double ll_hr10 = 0, ll_hr44 = 0, ll_mv10 = 0, ll_mv44 = 0;
      for(int p = 0; p <= 4; p++)
         for(int q = 0; q <= 4; q++)
           {
            double aic, aicc, bic, ll;
            if(Ajusta(z, p, q, ESTIMACAO_HANNAN_RISSANEN, aic, aicc, bic, ll))
              {
               if(aic < melhor[0]) { melhor[0] = aic; esc[0] = p * 5 + q; }
               if(p == 1 && q == 0) ll_hr10 = ll;
               if(p == 4 && q == 4) ll_hr44 = ll;
              }
            if(Ajusta(z, p, q, ESTIMACAO_VEROSSIMILHANCA, aic, aicc, bic, ll))
              {
               if(aic  < melhor[1]) { melhor[1] = aic;  esc[1] = p * 5 + q; }
               if(aicc < melhor[2]) { melhor[2] = aicc; esc[2] = p * 5 + q; }
               if(bic  < melhor[3]) { melhor[3] = bic;  esc[3] = p * 5 + q; }
               if(p == 1 && q == 0) ll_mv10 = ll;
               if(p == 4 && q == 4) ll_mv44 = ll;
              }
           }
      for(int k = 0; k < 4; k++) if(esc[k] >= 0) cont[k][esc[k]]++;
      ganho_hr += ll_hr44 - ll_hr10;
      ganho_mv += ll_mv44 - ll_mv10;
      n_ganho++;
     }
   string nomes[4] = {"HR + AIC ", "MV + AIC ", "MV + AICc", "MV + BIC "};
   for(int k = 0; k < 4; k++)
     {
      //--- as 5 ordens mais escolhidas
      int usado[25];
      ArrayInitialize(usado, 0);
      string s = "";
      int acerto = cont[k][5];   // (1,0)
      for(int t = 0; t < 5; t++)
        {
         int bi = -1;
         for(int i = 0; i < 25; i++) if(!usado[i] && (bi < 0 || cont[k][i] > cont[k][bi])) bi = i;
         usado[bi] = 1;
         s += StringFormat(" (%d,%d)=%d", bi / 5, bi % 5, cont[k][bi]);
        }
      Log(StringFormat("  %s acerta (1,0) em %3d de 150 | mais escolhidas:%s", nomes[k], acerto, s));
     }
   Log(StringFormat("  Ganho medio de log-verossimilhanca do (4,4) sobre o verdadeiro (1,0): HR %+.2f | MV %+.2f",
                    ganho_hr / n_ganho, ganho_mv / n_ganho));
   Log("  (o AIC so aceita os 7 parametros a mais do (4,4) se o ganho passar de 7)");
   Log("================ FIM ================");
   if(g_h != INVALID_HANDLE) FileClose(g_h);
   return(INIT_SUCCEEDED);
  }

void OnTick() {}
