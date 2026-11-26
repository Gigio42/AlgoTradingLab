//+------------------------------------------------------------------+
//| ValidacaoAssimetrico.mq5 (18/11/2026)                            |
//| Antes das simulacoes do estudo de 18/11 (PROTOCOLO.md da pasta   |
//| dados/resultados/assimetricos_2026-11-18/): as partes novas do   |
//| modelo funcionam como a teoria diz? Usa o CGarch, o CArima e a   |
//| selecao de ordens do proprio EA. Fora do TG.                     |
//|   1) recuperacao de parametros: GJR e EGARCH, normal e t(6),     |
//|      em series artificiais com verdade conhecida (500 e 3000);   |
//|   2) dados sem assimetria: gama estimado perto de zero;          |
//|   3) consistencia: GJR com gama = 0 da a mesma verossimilhanca   |
//|      do GARCH simetrico; previsao de um passo = formula a mao;   |
//|      E|z| da t conferido por Monte Carlo;                        |
//|   4) curva de impacto: queda pesa mais que alta;                 |
//|   5) PETR4 real (500 retornos a cada 63 pregoes, 2005-2026):     |
//|      sinal do efeito alavanca, AIC e Ljung-Box;                  |
//|   6) AIC x BIC em series com ordem conhecida;                    |
//|   7) janela expansiva x movel: precisao e quebra estrutural.     |
//| Semente fixa. Saida em MQL5\Files\valid_assim_*.                 |
//| Para rodar: ferramentas/scripts/validar_assimetrico.sh           |
//+------------------------------------------------------------------+
#include "..\Experts\AlgoTradingLab\robos\Include\Garch.mqh"
#include "..\Experts\AlgoTradingLab\robos\Include\SelecaoModelo.mqh"
#include "..\Experts\AlgoTradingLab\robos\Include\Estatistica.mqh"

int g_resumo = INVALID_HANDLE;
int g_falhas = 0;

void Linha(const string texto) { FileWrite(g_resumo, texto); Print(texto); }
void Criterio(const string nome, const bool passou, const string detalhe)
  {
   if(!passou) g_falhas++;
   Linha(StringFormat("  [%s] %s: %s", passou ? "PASSOU" : "FALHOU", nome, detalhe));
  }

//--- Uniforme com 30 bits (MathRand tem 15) e normal por Box-Muller
double Uniforme() { return(((double)MathRand() * 32768.0 + (double)MathRand() + 0.5) / 1073741824.0); }
double Randn() { return(MathSqrt(-2.0 * MathLog(Uniforme())) * MathCos(2.0 * M_PI * Uniforme())); }
//--- t de Student padronizada (variancia 1), nu inteiro
double RandT(const int nu)
  {
   double qui = 0.0;
   for(int k = 0; k < nu; k++) { double x = Randn(); qui += x * x; }
   return(Randn() / MathSqrt(qui / nu) * MathSqrt((nu - 2.0) / nu));
  }
double Choque(const ENUM_DISTRIBUICAO_GARCH dist, const int nu) { return(dist == DISTRIBUICAO_STUDENT ? RandT(nu) : Randn()); }

//--- Serie de um GARCH(1,1), GJR ou EGARCH com 500 dias de aquecimento descartados
void Simular(const ENUM_MODELO_GARCH modelo, const double omega, const double alfa, const double gama,
             const double beta, const ENUM_DISTRIBUICAO_GARCH dist, const int nu, const int n, double &eps[])
  {
   int aquec = 500;
   ArrayResize(eps, n);
   double eabs = ValorAbsolutoEsperado(dist, nu);
   double s2 = (modelo == GARCH_EGARCH) ? MathExp(omega / (1.0 - beta))
               : omega / (1.0 - alfa - beta - (modelo == GARCH_GJR ? 0.5 * gama : 0.0));
   double e = MathSqrt(s2) * Choque(dist, nu);
   for(int t = 1; t < aquec + n; t++)
     {
      double novo;
      if(modelo == GARCH_SIMETRICO)
         novo = omega + alfa * e * e + beta * s2;
      else
         PassoVarianciaAssimetrica(modelo, omega, alfa, gama, beta, e, s2, eabs, novo);
      s2 = novo;
      e = MathSqrt(s2) * Choque(dist, nu);
      if(t >= aquec) eps[t - aquec] = e;
     }
  }

double MedianaDe(double &x[])
  {
   int n = ArraySize(x);
   if(n == 0) return(0.0);
   double c[]; ArrayCopy(c, x); ArraySort(c);
   return((n % 2 == 1) ? c[n / 2] : 0.5 * (c[n / 2 - 1] + c[n / 2]));
  }
double Desvio(const double &x[]) { double m = Media(x), s = 0.0; int n = ArraySize(x); for(int i = 0; i < n; i++) s += (x[i] - m) * (x[i] - m); return(n > 1 ? MathSqrt(s / (n - 1)) : 0.0); }
void Acrescentar(double &x[], const double v) { int n = ArraySize(x); ArrayResize(x, n + 1); x[n] = v; }

bool Ajustar(CGarch &g, const ENUM_MODELO_GARCH modelo, const ENUM_DISTRIBUICAO_GARCH dist, const double &eps[])
  {
   g.Definir(1, 1);
   g.DefinirOtimizador(300);
   g.DefinirDistribuicao(dist);
   g.DefinirModelo(modelo);
   return(g.Ajustar(eps));
  }

string NomeModelo(const ENUM_MODELO_GARCH m) { return(m == GARCH_GJR ? "GJR" : (m == GARCH_EGARCH ? "EGARCH" : "GARCH")); }
string NomeDist(const ENUM_DISTRIBUICAO_GARCH d) { return(d == DISTRIBUICAO_STUDENT ? "t" : "normal"); }

//=== 1) e 2) recuperacao de parametros =================================
void Recuperacao(const int arquivo, const string caso, const ENUM_MODELO_GARCH gerador, const ENUM_MODELO_GARCH modelo,
                 const ENUM_DISTRIBUICAO_GARCH dist, const double omega, const double alfa, const double gama,
                 const double beta, const int n, const int reps, double &med_alfa, double &med_gama,
                 double &med_beta, double &med_nu, double &med_pers, double &frac_ok)
  {
   double va[], vg[], vb[], vn[], vp[];
   int ok = 0;
   for(int r = 0; r < reps; r++)
     {
      double eps[];
      Simular(gerador, omega, alfa, gama, beta, dist, 6, n, eps);
      CGarch g;
      bool ajustou = Ajustar(g, modelo, dist, eps);
      FileWrite(arquivo, StringFormat("%s,%s,%s,%s,%d,%d,%d,%.8g,%.6f,%.6f,%.6f,%.3f,%.6f", caso, NomeModelo(gerador),
                NomeModelo(modelo), NomeDist(dist), n, r, ajustou ? 1 : 0, ajustou ? g.Omega() : 0.0,
                ajustou ? g.Alfa(0) : 0.0, ajustou ? g.Gama() : 0.0, ajustou ? g.Beta(0) : 0.0,
                ajustou ? g.GrausLiberdade() : 0.0, ajustou ? g.Persistencia() : 0.0));
      if(!ajustou) continue;
      ok++;
      Acrescentar(va, g.Alfa(0)); Acrescentar(vg, g.Gama()); Acrescentar(vb, g.Beta(0));
      Acrescentar(vn, g.GrausLiberdade()); Acrescentar(vp, g.Persistencia());
     }
   med_alfa = MedianaDe(va); med_gama = MedianaDe(vg); med_beta = MedianaDe(vb); med_nu = MedianaDe(vn); med_pers = MedianaDe(vp);
   frac_ok = (double)ok / reps;
   int positivos = 0;
   for(int i = 0; i < ArraySize(vg); i++) if(vg[i] > 0.0) positivos++;
   Linha(StringFormat("%-28s n=%4d ajustou %3d/%3d | mediana alfa %.4f gama %.4f beta %.4f pers %.4f nu %.2f | dp gama %.4f | gama>0 em %.0f%%",
                      caso, n, ok, reps, med_alfa, med_gama, med_beta, med_pers, med_nu, Desvio(vg),
                      ArraySize(vg) > 0 ? 100.0 * positivos / ArraySize(vg) : 0.0));
  }

void OnStart()
  {
   MathSrand(20261118);
   g_resumo = FileOpen("valid_assim_resumo.txt", FILE_WRITE | FILE_TXT | FILE_ANSI);
   Linha("Validacao das partes novas (GJR, EGARCH, t, BIC, janela expansiva) - 18/11/2026, semente 20261118");

   //--- Verdade: volatilidade de longo prazo ~2% ao dia, persistencia 0,97 (GJR) e 0,96 (EGARCH)
   const double V = 0.0004;
   const double GJR_A = 0.03, GJR_G = 0.12, GJR_B = 0.88;
   const double GJR_W = V * (1.0 - GJR_A - 0.5 * GJR_G - GJR_B);
   const double EG_A = 0.15, EG_G = -0.08, EG_B = 0.96;
   const double EG_W = (1.0 - EG_B) * MathLog(V);

   int h = FileOpen("valid_assim_recuperacao.csv", FILE_WRITE | FILE_TXT | FILE_ANSI);
   FileWrite(h, "caso,gerador,modelo,dist,n,rep,ok,omega,alfa,gama,beta,nu,persist");
   double ma, mg, mb, mn, mp, fo;

   Linha("\n1) Recuperacao de parametros (verdade: GJR alfa 0.03 gama 0.12 beta 0.88 pers 0.97; EGARCH alfa 0.15 gama -0.08 beta 0.96; t com nu 6)");
   Recuperacao(h, "GJR normal", GARCH_GJR, GARCH_GJR, DISTRIBUICAO_NORMAL, GJR_W, GJR_A, GJR_G, GJR_B, 500, 200, ma, mg, mb, mn, mp, fo);
   Criterio("GJR normal n=500 ajusta", fo >= 0.95, StringFormat("%.0f%% das series", 100 * fo));
   Recuperacao(h, "GJR normal", GARCH_GJR, GARCH_GJR, DISTRIBUICAO_NORMAL, GJR_W, GJR_A, GJR_G, GJR_B, 3000, 40, ma, mg, mb, mn, mp, fo);
   Criterio("GJR normal n=3000 recupera", MathAbs(ma - GJR_A) < 0.03 && MathAbs(mg - GJR_G) < 0.04 && MathAbs(mb - GJR_B) < 0.03 && MathAbs(mp - 0.97) < 0.02,
            StringFormat("alfa %.3f gama %.3f beta %.3f pers %.3f", ma, mg, mb, mp));
   Recuperacao(h, "EGARCH normal", GARCH_EGARCH, GARCH_EGARCH, DISTRIBUICAO_NORMAL, EG_W, EG_A, EG_G, EG_B, 500, 200, ma, mg, mb, mn, mp, fo);
   Criterio("EGARCH normal n=500 ajusta", fo >= 0.95, StringFormat("%.0f%% das series", 100 * fo));
   Recuperacao(h, "EGARCH normal", GARCH_EGARCH, GARCH_EGARCH, DISTRIBUICAO_NORMAL, EG_W, EG_A, EG_G, EG_B, 3000, 40, ma, mg, mb, mn, mp, fo);
   Criterio("EGARCH normal n=3000 recupera", MathAbs(ma - EG_A) < 0.05 && MathAbs(mg - EG_G) < 0.04 && MathAbs(mb - EG_B) < 0.03,
            StringFormat("alfa %.3f gama %.3f beta %.3f", ma, mg, mb));
   Recuperacao(h, "GJR t", GARCH_GJR, GARCH_GJR, DISTRIBUICAO_STUDENT, GJR_W, GJR_A, GJR_G, GJR_B, 500, 100, ma, mg, mb, mn, mp, fo);
   Recuperacao(h, "GJR t", GARCH_GJR, GARCH_GJR, DISTRIBUICAO_STUDENT, GJR_W, GJR_A, GJR_G, GJR_B, 3000, 20, ma, mg, mb, mn, mp, fo);
   Criterio("GJR t n=3000 recupera", MathAbs(mg - GJR_G) < 0.05 && MathAbs(mb - GJR_B) < 0.04 && mn > 4.5 && mn < 8.5,
            StringFormat("gama %.3f beta %.3f nu %.2f", mg, mb, mn));
   Recuperacao(h, "EGARCH t", GARCH_EGARCH, GARCH_EGARCH, DISTRIBUICAO_STUDENT, EG_W, EG_A, EG_G, EG_B, 500, 100, ma, mg, mb, mn, mp, fo);
   Recuperacao(h, "EGARCH t", GARCH_EGARCH, GARCH_EGARCH, DISTRIBUICAO_STUDENT, EG_W, EG_A, EG_G, EG_B, 3000, 20, ma, mg, mb, mn, mp, fo);
   Criterio("EGARCH t n=3000 recupera", MathAbs(mg - EG_G) < 0.05 && MathAbs(mb - EG_B) < 0.04 && mn > 4.5 && mn < 8.5,
            StringFormat("gama %.3f beta %.3f nu %.2f", mg, mb, mn));

   Linha("\n2) Serie SEM assimetria (GARCH simetrico alfa 0.08 beta 0.90): gama deve ficar perto de zero");
   const double S_A = 0.08, S_B = 0.90, S_W = V * (1.0 - S_A - S_B);
   double gjr_sim, eg_sim;
   Recuperacao(h, "GJR em dado simetrico", GARCH_SIMETRICO, GARCH_GJR, DISTRIBUICAO_NORMAL, S_W, S_A, 0.0, S_B, 3000, 40, ma, gjr_sim, mb, mn, mp, fo);
   Recuperacao(h, "EGARCH em dado simetrico", GARCH_SIMETRICO, GARCH_EGARCH, DISTRIBUICAO_NORMAL, S_W, S_A, 0.0, S_B, 3000, 40, ma, eg_sim, mb, mn, mp, fo);
   Criterio("GJR sem assimetria: |gama| pequeno", MathAbs(gjr_sim) < 0.03, StringFormat("mediana gama %.4f (com assimetria a verdade e 0.12)", gjr_sim));
   Criterio("EGARCH sem assimetria: |gama| pequeno", MathAbs(eg_sim) < 0.03, StringFormat("mediana gama %.4f (com assimetria a verdade e -0.08)", eg_sim));
   FileClose(h);

   //=== 3) consistencia ===================================================
   Linha("\n3) Consistencia do codigo");
   {
    double eps[];
    Simular(GARCH_SIMETRICO, S_W, S_A, 0.0, S_B, DISTRIBUICAO_NORMAL, 6, 1000, eps);
    CGarch g;
    Ajustar(g, GARCH_SIMETRICO, DISTRIBUICAO_NORMAL, eps);
    ParametrosGarchAssimetrico par;
    par.omega = g.Omega(); par.alfa = g.Alfa(0); par.gama = 0.0; par.beta = g.Beta(0); par.graus_liberdade = 0.0;
    double s2[], logl;
    double v = 0.0; for(int i = 0; i < 1000; i++) v += eps[i] * eps[i]; v /= 1000.0;
    RecursaoGarchAssimetrico(GARCH_GJR, DISTRIBUICAO_NORMAL, par, eps, 1000, 1, v, s2, logl);
    Criterio("GJR com gama=0 = GARCH simetrico (log-verossimilhanca)", MathAbs(logl - g.LogVerossimilhanca()) < 1e-6 * MathAbs(logl),
             StringFormat("%.8f x %.8f", logl, g.LogVerossimilhanca()));
    double prev_sim = g.VolatilidadeProximoPeriodo();
    double prev_gjr = MathSqrt(par.omega + par.alfa * eps[999] * eps[999] + par.beta * s2[999]);
    Criterio("previsao de um passo GARCH = formula", MathAbs(prev_sim - prev_gjr) < 1e-10, StringFormat("%.10f x %.10f", prev_sim, prev_gjr));

    //--- previsao do GJR e do EGARCH ajustados = formula escrita aqui
    double e2[];
    Simular(GARCH_GJR, GJR_W, GJR_A, GJR_G, GJR_B, DISTRIBUICAO_NORMAL, 6, 1000, e2);
    CGarch gj, ge;
    Ajustar(gj, GARCH_GJR, DISTRIBUICAO_NORMAL, e2);
    Ajustar(ge, GARCH_EGARCH, DISTRIBUICAO_NORMAL, e2);
    double ult = e2[999], s2j = MathPow(gj.VolatilidadeAtual(), 2), s2e = MathPow(ge.VolatilidadeAtual(), 2);
    double fj = MathSqrt(gj.Omega() + (gj.Alfa(0) + (ult < 0 ? gj.Gama() : 0.0)) * ult * ult + gj.Beta(0) * s2j);
    double z = ult / MathSqrt(s2e);
    double fe = MathSqrt(MathExp(ge.Omega() + ge.Beta(0) * MathLog(s2e) + ge.Alfa(0) * (MathAbs(z) - MathSqrt(2.0 / M_PI)) + ge.Gama() * z));
    Criterio("previsao de um passo GJR = formula", MathAbs(fj - gj.VolatilidadeProximoPeriodo()) < 1e-10, StringFormat("%.10f x %.10f", fj, gj.VolatilidadeProximoPeriodo()));
    Criterio("previsao de um passo EGARCH = formula", MathAbs(fe - ge.VolatilidadeProximoPeriodo()) < 1e-10, StringFormat("%.10f x %.10f", fe, ge.VolatilidadeProximoPeriodo()));
    Criterio("GJR e EGARCH tem um parametro a mais", gj.NumParametros() == 4 && ge.NumParametros() == 4 && g.NumParametros() == 3,
             StringFormat("%d, %d e %d", gj.NumParametros(), ge.NumParametros(), g.NumParametros()));

    //--- E|z| por Monte Carlo
    double sn = 0.0, st = 0.0; const int M = 400000;
    for(int i = 0; i < M; i++) { sn += MathAbs(Randn()); st += MathAbs(RandT(6)); }
    double fn = ValorAbsolutoEsperado(DISTRIBUICAO_NORMAL, 0), ft = ValorAbsolutoEsperado(DISTRIBUICAO_STUDENT, 6);
    Criterio("E|z| normal (Monte Carlo)", MathAbs(sn / M / fn - 1.0) < 0.005, StringFormat("simulado %.5f formula %.5f", sn / M, fn));
    Criterio("E|z| t(6) padronizada (Monte Carlo)", MathAbs(st / M / ft - 1.0) < 0.005, StringFormat("simulado %.5f formula %.5f", st / M, ft));
    Criterio("E|z| t com nu grande tende a normal", MathAbs(ValorAbsolutoEsperado(DISTRIBUICAO_STUDENT, 2000) / fn - 1.0) < 0.001,
             StringFormat("nu=2000: %.5f", ValorAbsolutoEsperado(DISTRIBUICAO_STUDENT, 2000)));
   }

   //=== 4) curva de impacto com a verdade ==================================
   Linha("\n4) Curva de impacto (variancia do dia seguinte para um choque de -k a +k desvios, partindo da variancia de longo prazo)");
   {
    int hi = FileOpen("valid_assim_impacto.csv", FILE_WRITE | FILE_TXT | FILE_ANSI);
    FileWrite(hi, "choque_desvios,garch,gjr,egarch");
    double eabs = MathSqrt(2.0 / M_PI), s0 = V;
    double s2_eg0 = MathExp(EG_W / (1.0 - EG_B));
    for(int k = -40; k <= 40; k++)
      {
       double c = k / 10.0, a, b, d;
       a = S_W + S_A * c * c * s0 + S_B * s0;
       PassoVarianciaAssimetrica(GARCH_GJR, GJR_W, GJR_A, GJR_G, GJR_B, c * MathSqrt(s0), s0, eabs, b);
       PassoVarianciaAssimetrica(GARCH_EGARCH, EG_W, EG_A, EG_G, EG_B, c * MathSqrt(s2_eg0), s2_eg0, eabs, d);
       FileWrite(hi, StringFormat("%.1f,%.8f,%.8f,%.8f", c, a, b, d));
      }
    FileClose(hi);
    double qj, aj, qe, ae;
    PassoVarianciaAssimetrica(GARCH_GJR, GJR_W, GJR_A, GJR_G, GJR_B, -2.0 * MathSqrt(s0), s0, eabs, qj);
    PassoVarianciaAssimetrica(GARCH_GJR, GJR_W, GJR_A, GJR_G, GJR_B, 2.0 * MathSqrt(s0), s0, eabs, aj);
    PassoVarianciaAssimetrica(GARCH_EGARCH, EG_W, EG_A, EG_G, EG_B, -2.0 * MathSqrt(s2_eg0), s2_eg0, eabs, qe);
    PassoVarianciaAssimetrica(GARCH_EGARCH, EG_W, EG_A, EG_G, EG_B, 2.0 * MathSqrt(s2_eg0), s2_eg0, eabs, ae);
    Criterio("GJR: queda de 2 desvios pesa mais que alta", qj > aj, StringFormat("vol seguinte %.4f%% x %.4f%%", 100 * MathSqrt(qj), 100 * MathSqrt(aj)));
    Criterio("EGARCH: queda de 2 desvios pesa mais que alta", qe > ae, StringFormat("vol seguinte %.4f%% x %.4f%%", 100 * MathSqrt(qe), 100 * MathSqrt(ae)));
   }

   //=== 5) PETR4 real ======================================================
   Linha("\n5) PETR4_OFICIAL (B3): janelas de 500 log-retornos (menos a media), uma a cada 63 pregoes");
   {
    double fech[]; string datas[];
    int f = FileOpen("PETR4_OFICIAL.csv", FILE_READ | FILE_TXT | FILE_ANSI);
    while(f != INVALID_HANDLE && !FileIsEnding(f))
      {
       string l = FileReadString(f);
       string p[];
       if(StringSplit(l, ',', p) < 6) continue;
       int n = ArraySize(fech); ArrayResize(fech, n + 1); ArrayResize(datas, n + 1);
       fech[n] = StringToDouble(p[5]); datas[n] = p[0];
      }
    if(f != INVALID_HANDLE) FileClose(f);
    int nf = ArraySize(fech);
    Linha(StringFormat("  %d fechamentos lidos (%s a %s)", nf, nf > 0 ? datas[0] : "-", nf > 0 ? datas[nf - 1] : "-"));
    int hp = FileOpen("valid_assim_petr4.csv", FILE_WRITE | FILE_TXT | FILE_ANSI);
    FileWrite(hp, "fim,modelo,dist,ok,logL,aic,bic,alfa,gama,beta,nu,persist,lb_p");
    int janelas = 0, gjr_pos = 0, eg_neg = 0, gjr_aic = 0, eg_aic = 0, t_aic = 0, lr_sig = 0, lb_ok = 0, lb_tot = 0;
    for(int fim = 500; fim < nf; fim += 63)
      {
       double r[]; ArrayResize(r, 500);
       double m = 0;
       for(int i = 0; i < 500; i++) { r[i] = MathLog(fech[fim - 499 + i] / fech[fim - 500 + i]); m += r[i]; }
       m /= 500;
       for(int i = 0; i < 500; i++) r[i] -= m;
       double aic[3][2], ll[3][2], gam[3];
       bool todos = true;
       for(int mo = 0; mo < 3; mo++)
          for(int di = 0; di < 2; di++)
            {
             CGarch g;
             bool ok = Ajustar(g, (ENUM_MODELO_GARCH)mo, (ENUM_DISTRIBUICAO_GARCH)di, r);
             double lbp = -1;
             if(ok)
               {
                double z[]; g.ObterResiduosPadronizados(z);
                for(int i = 0; i < ArraySize(z); i++) z[i] = z[i] * z[i];
                ResultadoLjungBox lb;
                if(TesteLjungBox(z, 10, 0, lb)) lbp = lb.pvalor;
                if(lbp >= 0) { lb_tot++; if(lbp > 0.05) lb_ok++; }
               }
             aic[mo][di] = ok ? g.AIC() : 1e300; ll[mo][di] = ok ? g.LogVerossimilhanca() : -1e300;
             if(di == 0) gam[mo] = g.Gama();
             if(!ok) todos = false;
             FileWrite(hp, StringFormat("%s,%s,%s,%d,%.4f,%.4f,%.4f,%.6f,%.6f,%.6f,%.3f,%.6f,%.4f", datas[fim], NomeModelo((ENUM_MODELO_GARCH)mo),
                       NomeDist((ENUM_DISTRIBUICAO_GARCH)di), ok ? 1 : 0, ll[mo][di], ok ? g.AIC() : 0.0, ok ? g.BIC() : 0.0, ok ? g.Alfa(0) : 0.0,
                       ok ? g.Gama() : 0.0, ok ? g.Beta(0) : 0.0, ok ? g.GrausLiberdade() : 0.0, ok ? g.Persistencia() : 0.0, lbp));
            }
       if(!todos) continue;
       janelas++;
       if(gam[1] > 0) gjr_pos++;
       if(gam[2] < 0) eg_neg++;
       if(aic[1][0] < aic[0][0]) gjr_aic++;
       if(aic[2][0] < aic[0][0]) eg_aic++;
       if(aic[0][1] < aic[0][0]) t_aic++;
       if(2.0 * (ll[1][0] - ll[0][0]) > 3.841) lr_sig++;
      }
    FileClose(hp);
    Linha(StringFormat("  %d janelas com os seis modelos ajustados", janelas));
    Linha(StringFormat("  GJR gama > 0 (alavanca) em %d (%.0f%%); EGARCH gama < 0 em %d (%.0f%%)", gjr_pos, 100.0 * gjr_pos / MathMax(1, janelas), eg_neg, 100.0 * eg_neg / MathMax(1, janelas)));
    Linha(StringFormat("  AIC menor que o do GARCH: GJR em %.0f%%, EGARCH em %.0f%%; t menor que a normal (GARCH) em %.0f%%",
                       100.0 * gjr_aic / MathMax(1, janelas), 100.0 * eg_aic / MathMax(1, janelas), 100.0 * t_aic / MathMax(1, janelas)));
    Linha(StringFormat("  razao de verossimilhanca GJR x GARCH significativa a 5%% em %.0f%% das janelas", 100.0 * lr_sig / MathMax(1, janelas)));
    Linha(StringFormat("  Ljung-Box (10) nos residuos padronizados ao quadrado sem rejeitar a 5%%: %d de %d ajustes", lb_ok, lb_tot));
    Criterio("PETR4: alavanca no sentido da teoria na maioria das janelas", gjr_pos > janelas / 2 && eg_neg > janelas / 2,
             StringFormat("GJR %d/%d, EGARCH %d/%d", gjr_pos, janelas, eg_neg, janelas));
   }

   //=== 6) AIC x BIC =======================================================
   Linha("\n6) AIC x BIC: 200 series de 240 log-retornos por caso, log-preco = soma, selecao do EA (ADF + grade 0..4, COM constante: sem ela o ARIMA(0,1,0) fica fora da grade e o ruido branco nao teria a ordem certa entre as candidatas)");
   {
    int hb = FileOpen("valid_assim_bic.csv", FILE_WRITE | FILE_TXT | FILE_ANSI);
    FileWrite(hb, "caso,rep,criterio,d,p,q");
    string casos[2] = {"ruido branco", "AR(1) phi 0.3"};
    for(int c = 0; c < 2; c++)
      {
       int certos[2] = {0, 0}, total[2] = {0, 0}; double ordem[2] = {0, 0};
       for(int r = 0; r < 200; r++)
         {
          double ret[], nivel[]; ArrayResize(ret, 240); ArrayResize(nivel, 241);
          double ant = 0; nivel[0] = MathLog(30.0);
          for(int t = 0; t < 240; t++)
            {
             ret[t] = (c == 1 ? 0.3 * ant : 0.0) + 0.02 * Randn(); ant = ret[t];
             nivel[t + 1] = nivel[t] + ret[t];
            }
          for(int k = 0; k < 2; k++)
            {
             DefinirCriterioDeOrdens(k == 0 ? CRITERIO_AIC : CRITERIO_BIC);
             ResultadoSelecao s; string rel;
             if(!SelecionarModelo(nivel, 2, 4, 4, true, ADF_CONSTANTE, s, rel)) continue;
             total[k]++; ordem[k] += s.p + s.q;
             if((c == 0 && s.p == 0 && s.q == 0 && s.d == 1) || (c == 1 && s.p == 1 && s.q == 0 && s.d == 1)) certos[k]++;
             FileWrite(hb, StringFormat("%s,%d,%s,%d,%d,%d", casos[c], r, k == 0 ? "AIC" : "BIC", s.d, s.p, s.q));
            }
         }
       DefinirCriterioDeOrdens(CRITERIO_AIC);
       Linha(StringFormat("  %-14s AIC: ordem certa %3d/%d, p+q medio %.2f | BIC: ordem certa %3d/%d, p+q medio %.2f",
                          casos[c], certos[0], total[0], ordem[0] / MathMax(1, total[0]), certos[1], total[1], ordem[1] / MathMax(1, total[1])));
       Criterio("BIC escolhe modelos menores que o AIC (" + casos[c] + ")", ordem[1] / MathMax(1, total[1]) < ordem[0] / MathMax(1, total[0]),
                StringFormat("p+q medio %.2f x %.2f", ordem[1] / MathMax(1, total[1]), ordem[0] / MathMax(1, total[0])));
       Criterio("BIC acerta a ordem mais vezes (" + casos[c] + ")", certos[1] >= certos[0], StringFormat("%d x %d", certos[1], certos[0]));
      }
    FileClose(hb);
   }

   //=== 7) janela expansiva x movel ========================================
   Linha("\n7) Janela expansiva x movel (AR(1) nos log-retornos, estimado pelo CArima do EA, d=0, sem constante)");
   {
    int he = FileOpen("valid_assim_expansiva.csv", FILE_WRITE | FILE_TXT | FILE_ANSI);
    FileWrite(he, "caso,rep,phi_movel240,phi_expansiva2000");
    for(int c = 0; c < 2; c++)
      {
       double pm[], pe[];
       for(int r = 0; r < 300; r++)
         {
          double x[]; ArrayResize(x, 2000);
          double ant = 0;
          for(int t = 0; t < 2000; t++)
            {
             double phi = (c == 1 && t >= 1500) ? -0.2 : (c == 1 ? 0.2 : 0.1);
             x[t] = phi * ant + 0.02 * Randn(); ant = x[t];
            }
          double ult[]; ArrayResize(ult, 240); for(int i = 0; i < 240; i++) ult[i] = x[1760 + i];
          CArima a1, a2;
          a1.Definir(1, 0, 0, false); a2.Definir(1, 0, 0, false);
          if(!a1.Ajustar(ult) || !a2.Ajustar(x)) continue;
          Acrescentar(pm, a1.Phi(0)); Acrescentar(pe, a2.Phi(0));
          FileWrite(he, StringFormat("%s,%d,%.6f,%.6f", c == 0 ? "estavel phi 0.1" : "quebra 0.2 -> -0.2 no dia 1500", r, a1.Phi(0), a2.Phi(0)));
         }
       if(c == 0)
         {
          double razao = Desvio(pe) / Desvio(pm);
          Linha(StringFormat("  processo estavel (phi 0.1): media movel %.4f (dp %.4f), expansiva %.4f (dp %.4f); dp teorico %.4f e %.4f",
                             Media(pm), Desvio(pm), Media(pe), Desvio(pe), MathSqrt((1 - 0.01) / 240), MathSqrt((1 - 0.01) / 2000)));
          Criterio("expansiva mais precisa sem mudanca (dp cai ~ raiz(240/2000) = 0.35)", razao > 0.25 && razao < 0.5, StringFormat("razao dos dp %.3f", razao));
         }
       else
         {
          Linha(StringFormat("  com quebra (0.2 -> -0.2 nos ultimos 500 dias): media movel %.4f, expansiva %.4f (verdade atual -0.2)", Media(pm), Media(pe)));
          Criterio("movel acompanha a quebra melhor que a expansiva", MathAbs(Media(pm) + 0.2) < MathAbs(Media(pe) + 0.2),
                   StringFormat("erro %.3f x %.3f", MathAbs(Media(pm) + 0.2), MathAbs(Media(pe) + 0.2)));
         }
      }
    FileClose(he);
   }

   Linha(StringFormat("\nFIM: %d criterio(s) falharam", g_falhas));
   FileClose(g_resumo);
   int fimh = FileOpen("valid_assim_fim.txt", FILE_WRITE | FILE_TXT | FILE_ANSI);
   FileWrite(fimh, "fim");
   FileClose(fimh);
  }
