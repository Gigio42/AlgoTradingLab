//| Estudo de 13/11/2026 (dados/resultados/janelas_garch_2026-11-13/PROTOCOLO.md):
//| o mesmo CGarch do EA em series GARCH(1,1) artificiais, com verdade conhecida,
//| estimado com 120, 240, 500 e 1000 observacoes. Fora do TG.
//|   1) precisao: muitas series de um processo que NAO muda; erro dos parametros
//|      e da volatilidade prevista para o dia seguinte, por tamanho de janela;
//|   2) mudanca de regime: uma serie calma que passa por 150 dias de crise e
//|      volta a ser calma; a volatilidade prevista e o limiar (percentil 70 da
//|      volatilidade ajustada, como no EA) de cada janela, dia a dia.
//| Semente fixa: rodar de novo da os mesmos numeros. Saida em MQL5\Files.
//| Para rodar: ferramentas/scripts/janela_garch_simulada.sh
#include "..\Experts\AlgoTradingLab\robos\Include\Garch.mqh"
#include "..\Experts\AlgoTradingLab\robos\Include\Estatistica.mqh"

#define NJ 4
const int JANELAS[NJ] = {120, 240, 500, 1000};

//--- Normal(0,1) por Box-Muller (o mesmo do ValidacaoAlgoLab.mq5)
double Randn()
  {
   double u1 = (MathRand() + 1.0) / 32768.0;
   double u2 = (MathRand() + 1.0) / 32768.0;
   if(u1 <= 0.0) u1 = 1e-12;
   return(MathSqrt(-2.0 * MathLog(u1)) * MathCos(2.0 * M_PI * u2));
  }

//--- GARCH(1,1) com parametros por dia: eps[t] e sigma[t] (verdadeira), t = 0..n-1
void Simular(const int n, const double &w[], const double &a[], const double &b[], double &eps[], double &sig[])
  {
   ArrayResize(eps, n);
   ArrayResize(sig, n);
   double s2 = w[0] / (1.0 - a[0] - b[0]);
   double e = MathSqrt(s2) * Randn();
   sig[0] = MathSqrt(s2); eps[0] = e;
   for(int t = 1; t < n; t++)
     {
      s2 = w[t] + a[t] * e * e + b[t] * s2;
      e = MathSqrt(s2) * Randn();
      sig[t] = MathSqrt(s2); eps[t] = e;
     }
  }

//--- omega de um processo com persistencia a+b e volatilidade de longo prazo v
double OmegaPara(const double v, const double a, const double b) { return(v * v * (1.0 - a - b)); }

void OnStart()
  {
   MathSrand(20261113);
   const double A = 0.09, B = 0.89;

   //=== 1) precisao com o processo fixo (volatilidade de longo prazo 2,5% ao dia)
   int h = FileOpen("janela_sim_precisao.csv", FILE_WRITE | FILE_TXT | FILE_ANSI);
   FileWrite(h, "janela,rep,ok,alfa,beta,persist,vol_lp,vol_prev,vol_verd");
   const int REPS = 400, AQUEC = 500;
   double w[], a[], b[], eps[], sig[];
   int nmax = AQUEC + JANELAS[NJ - 1] + 1;
   ArrayResize(w, nmax); ArrayResize(a, nmax); ArrayResize(b, nmax);
   ArrayInitialize(w, OmegaPara(0.025, A, B)); ArrayInitialize(a, A); ArrayInitialize(b, B);
   for(int r = 0; r < REPS; r++)
     {
      // uma serie por repeticao; as quatro janelas terminam no mesmo dia e
      // preveem o mesmo dia seguinte (a ultima observacao fica de fora)
      Simular(nmax, w, a, b, eps, sig);
      for(int j = 0; j < NJ; j++)
        {
         int n = JANELAS[j];
         double res[];
         ArrayResize(res, n);
         for(int i = 0; i < n; i++) res[i] = eps[nmax - 1 - n + i];
         CGarch g;
         g.Definir(1, 1);
         g.DefinirOtimizador(300);
         bool ok = g.Ajustar(res);
         double lp = (ok && g.Persistencia() < 1.0) ? MathSqrt(g.VarianciaLongoPrazo()) : 0.0;
         FileWrite(h, StringFormat("%d,%d,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f", n, r, ok ? 1 : 0,
                   ok ? g.Alfa(0) : 0.0, ok ? g.Beta(0) : 0.0, ok ? g.Persistencia() : 0.0, lp,
                   ok ? g.VolatilidadeProximoPeriodo() : 0.0, sig[nmax - 1]));
        }
     }
   FileClose(h);
   Print("precisao: fim");

   //=== 2) mudanca de regime: calma (1,5%) ate o dia 1999, crise (4%) de 2000 a
   //===    2149, calma de novo depois. Estimacao diaria de 1800 a 2600.
   //===    REPS_REGIME series com a mesma mudanca: a primeira vai inteira para
   //===    janela_sim_regime.csv (o exemplo dos graficos); de todas, a fracao de
   //===    series em que cada janela vetou em cada dia e o erro medio da prevista
   //===    (janela_sim_regime_media.csv).
   const int NT = 2700, CRISE_INI = 2000, CRISE_FIM = 2150, DE = 1800, ATE = 2600, REPS_REGIME = 20;
   ArrayResize(w, NT); ArrayResize(a, NT); ArrayResize(b, NT);
   ArrayInitialize(a, A); ArrayInitialize(b, B);
   for(int t = 0; t < NT; t++)
      w[t] = OmegaPara((t >= CRISE_INI && t < CRISE_FIM) ? 0.04 : 0.015, A, B);
   int ND = ATE - DE + 1;
   double soma_veto[], soma_erro[], soma_verd[];
   ArrayResize(soma_veto, ND * NJ); ArrayResize(soma_erro, ND * NJ); ArrayResize(soma_verd, ND);
   ArrayInitialize(soma_veto, 0.0); ArrayInitialize(soma_erro, 0.0); ArrayInitialize(soma_verd, 0.0);
   for(int r = 0; r < REPS_REGIME; r++)
     {
      Simular(NT, w, a, b, eps, sig);
      if(r == 0)
        {
         h = FileOpen("janela_sim_regime.csv", FILE_WRITE | FILE_TXT | FILE_ANSI);
         FileWrite(h, "dia,retorno,vol_verd,prev_120,prev_240,prev_500,prev_1000,lim_120,lim_240,lim_500,lim_1000,pers_120,pers_240,pers_500,pers_1000");
        }
      for(int t = DE; t <= ATE; t++)
        {
         // no dia t o robo conhece eps ate t-1 e preve sigma[t]
         string linha = StringFormat("%d,%.6f,%.6f", t, eps[t], sig[t]);
         string prev = "", lim = "", pers = "";
         soma_verd[t - DE] += sig[t];
         for(int j = 0; j < NJ; j++)
           {
            int n = JANELAS[j];
            double res[];
            ArrayResize(res, n);
            for(int i = 0; i < n; i++) res[i] = eps[t - n + i];
            CGarch g;
            g.Definir(1, 1);
            g.DefinirOtimizador(300);
            double vp = 0.0, li = 0.0, pe = 0.0;
            if(g.Ajustar(res))
              {
               double serie[];
               vp = g.VolatilidadeProximoPeriodo();
               li = g.ObterSerieVolatilidade(serie) ? Percentil(serie, 70.0) : 0.0;
               pe = g.Persistencia();
              }
            if(vp > li) soma_veto[(t - DE) * NJ + j] += 1.0;
            soma_erro[(t - DE) * NJ + j] += MathAbs(vp / sig[t] - 1.0);
            prev += StringFormat(",%.6f", vp);
            lim += StringFormat(",%.6f", li);
            pers += StringFormat(",%.6f", pe);
           }
         if(r == 0)
            FileWrite(h, linha + prev + lim + pers);
        }
      if(r == 0)
         FileClose(h);
     }
   h = FileOpen("janela_sim_regime_media.csv", FILE_WRITE | FILE_TXT | FILE_ANSI);
   FileWrite(h, "dia,series,vol_verd_media,veto_120,veto_240,veto_500,veto_1000,erro_120,erro_240,erro_500,erro_1000");
   for(int d = 0; d < ND; d++)
     {
      string s = StringFormat("%d,%d,%.6f", DE + d, REPS_REGIME, soma_verd[d] / REPS_REGIME);
      for(int j = 0; j < NJ; j++) s += StringFormat(",%.4f", soma_veto[d * NJ + j] / REPS_REGIME);
      for(int j = 0; j < NJ; j++) s += StringFormat(",%.4f", soma_erro[d * NJ + j] / REPS_REGIME);
      FileWrite(h, s);
     }
   FileClose(h);
   h = FileOpen("janela_sim_fim.txt", FILE_WRITE | FILE_TXT | FILE_ANSI);
   FileWrite(h, "FIM");
   FileClose(h);
   Print("regime: fim");
  }
