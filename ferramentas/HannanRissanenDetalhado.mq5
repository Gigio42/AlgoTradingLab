//+------------------------------------------------------------------+
//| HannanRissanenDetalhado.mq5 - dados do relatorio sobre o         |
//| Hannan-Rissanen (30/10/2026, ia/relatorios/hannan-rissanen/).    |
//|                                                                  |
//| 1. Serie sintetica ARMA(1,1) com erros verdadeiros conhecidos:   |
//|    os dois estagios por dentro, o efeito da ordem do AR longo.   |
//| 2. Monte Carlo: HR x maxima verossimilhanca x AR(1) ingenuo, e   |
//|    um MA(1) com o theta que o robo estimou no pregao real.       |
//| 3. Pregoes reais do robo (traco da refacao de 05/10/2026):       |
//|    a mesma janela que o EA usou, refeita passo a passo, para     |
//|    conferir contra o traco.                                      |
//|                                                                  |
//| Os dois estagios sao refeitos aqui com as mesmas regras do       |
//| CArima::HannanRissanen, para expor os passos intermediarios; o   |
//| resultado e conferido contra o proprio CArima.                   |
//| Para rodar: ferramentas/scripts/hannan_rissanen.sh.              |
//+------------------------------------------------------------------+
#include "..\Experts\AlgoTradingLab\robos\Include\Arima.mqh"

#define PASTA      "AlgoLab_hr\\"
#define SIMBOLO    "PETR4_OFICIAL"
#define JANELA     240                 // Janela_Estimacao da configuracao do traco
#define N_SINT     239                 // mesmo tamanho da serie diferenciada do robo
#define PHI_SINT   0.6
#define THETA_SINT 0.4
#define REPLICAS   1000
#define SEMENTE    20261030

int g_resumo  = INVALID_HANDLE;
int g_valores = INVALID_HANDLE;

void Log(const string s)
  {
   Print(s);
   if(g_resumo != INVALID_HANDLE)
      FileWrite(g_resumo, s);
  }

int Abrir(const string nome)
  {
   int h = FileOpen(PASTA + nome, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
      Log("ERRO ao abrir " + nome);
   return(h);
  }

//--- \vHNome = numero para o texto (virgula decimal); \pHNome = numero para coordenada
void Valor(const string nome, const double v, const int digitos)
  {
   string s = DoubleToString(v, digitos);
   string texto = s;
   StringReplace(texto, ".", "{,}");
   if(StringGetCharacter(texto, 0) == '-')
      texto = "\\ensuremath{-}" + StringSubstr(texto, 1);
   FileWriteString(g_valores, StringFormat("\\def\\vH%s{%s}\n\\def\\pH%s{%s}\n", nome, texto, nome, s));
  }

void Texto(const string nome, const string s)
  {
   FileWriteString(g_valores, StringFormat("\\def\\vH%s{%s}\n", nome, s));
  }

string DataBR(const datetime t)
  {
   MqlDateTime d;
   TimeToStruct(t, d);
   return(StringFormat("%02d/%02d/%04d", d.day, d.mon, d.year));
  }

string DataISO(const datetime t)
  {
   string s = TimeToString(t, TIME_DATE);
   StringReplace(s, ".", "-");
   return(s);
  }

//--- Normal(0,1) por Box-Muller, com 30 bits por uniforme
double Uniforme()
  {
   return((MathRand() * 32768.0 + MathRand() + 1.0) / 1073741825.0);
  }

double Randn()
  {
   return(MathSqrt(-2.0 * MathLog(Uniforme())) * MathCos(2.0 * M_PI * Uniforme()));
  }

//--- ARMA(1,1) z(t) = phi z(t-1) + e(t) + theta e(t-1), com 200 de aquecimento descartados
void GerarARMA(const double phi, const double theta, const int n, double &z[], double &e[])
  {
   int total = n + 200;
   double zz[], ee[];
   ArrayResize(zz, total);
   ArrayResize(ee, total);
   zz[0] = 0.0;
   ee[0] = Randn();
   for(int t = 1; t < total; t++)
     {
      ee[t] = Randn();
      zz[t] = phi * zz[t - 1] + ee[t] + theta * ee[t - 1];
     }
   ArrayResize(z, n);
   ArrayResize(e, n);
   for(int i = 0; i < n; i++)
     {
      z[i] = zz[200 + i];
      e[i] = ee[200 + i];
     }
  }

//--- A ordem do AR longo, como no CArima::HannanRissanen
int OrdemLonga(const int tamanho, const int p, const int q)
  {
   int m = (int)MathFloor(MathPow(MathLog((double)tamanho), 2.0));
   m = MathMax(m, p + q + 1);
   return(MathMin(m, tamanho / 5));
  }

//--- Os dois estagios, com as regras do CArima, expondo os intermediarios.
//--- m_forcado > 0 troca a ordem do AR longo (so para o estudo da ordem).
struct PassosHR
  {
   int      m;
   int      obs1;
   int      obs2;
   int      primeiro;
   double   ar[];         // [0] = constante, [1..m] = coeficientes do AR longo
   double   eps1[];       // erros estimados no estagio 1 (zero antes de m)
   double   sqr1;
   double   c;
   double   phi[];
   double   theta[];
   double   sqr2;
  };

bool HRPassoAPasso(const double &z[], const int p, const int q, const bool cte, const int m_forcado, PassosHR &h)
  {
   int tamanho = ArraySize(z);
   h.m = (m_forcado > 0) ? m_forcado : OrdemLonga(tamanho, p, q);
   h.obs1 = tamanho - h.m;

   //--- estagio 1: z(t) contra 1, z(t-1), ..., z(t-m)
   CMatrixDouble X1(h.obs1, h.m + 1);
   double y1[];
   ArrayResize(y1, h.obs1);
   for(int t = h.m, linha = 0; t < tamanho; t++, linha++)
     {
      y1[linha] = z[t];
      X1.Set(linha, 0, 1.0);
      for(int i = 1; i <= h.m; i++)
         X1.Set(linha, i, z[t - i]);
     }
   double ep[];
   if(!MQO(X1, y1, h.obs1, h.m + 1, h.ar, ep, h.sqr1, false))
      return(false);
   ArrayResize(h.eps1, tamanho);
   ArrayInitialize(h.eps1, 0.0);
   for(int t = h.m; t < tamanho; t++)
     {
      double ajuste = h.ar[0];
      for(int i = 1; i <= h.m; i++)
         ajuste += h.ar[i] * z[t - i];
      h.eps1[t] = z[t] - ajuste;
     }

   //--- estagio 2: z(t) contra 1, z(t-1..p), eps1(t-1..q)
   h.primeiro = MathMax(h.m + q, p);
   h.obs2 = tamanho - h.primeiro;
   int k = p + q + (cte ? 1 : 0);
   CMatrixDouble X2(h.obs2, k);
   double y2[];
   ArrayResize(y2, h.obs2);
   for(int t = h.primeiro, linha = 0; t < tamanho; t++, linha++)
     {
      y2[linha] = z[t];
      int col = 0;
      if(cte)
         X2.Set(linha, col++, 1.0);
      for(int i = 1; i <= p; i++)
         X2.Set(linha, col++, z[t - i]);
      for(int j = 1; j <= q; j++)
         X2.Set(linha, col++, h.eps1[t - j]);
     }
   double b[];
   if(!MQO(X2, y2, h.obs2, k, b, ep, h.sqr2, false))
      return(false);
   int col = 0;
   h.c = cte ? b[col++] : 0.0;
   ArrayResize(h.phi, p);
   ArrayResize(h.theta, q);
   for(int i = 0; i < p; i++)
      h.phi[i] = b[col++];
   for(int j = 0; j < q; j++)
      h.theta[j] = b[col++];
   return(true);
  }

//--- Residuos recursivos com os coeficientes finais (CArima::CalcularResiduos)
void Recursivos(const double &z[], const PassosHR &h, double &r[])
  {
   int tamanho = ArraySize(z);
   int p = ArraySize(h.phi), q = ArraySize(h.theta);
   ArrayResize(r, tamanho);
   ArrayInitialize(r, 0.0);
   for(int t = MathMax(p, q); t < tamanho; t++)
     {
      double ajuste = h.c;
      for(int i = 0; i < p; i++)
         ajuste += h.phi[i] * z[t - 1 - i];
      for(int j = 0; j < q; j++)
         ajuste += h.theta[j] * r[t - 1 - j];
      r[t] = z[t] - ajuste;
     }
  }

double Correlacao(const double &a[], const double &b[], const int de)
  {
   int n = ArraySize(a) - de;
   double ma = 0, mb = 0;
   for(int i = de; i < ArraySize(a); i++) { ma += a[i]; mb += b[i]; }
   ma /= n; mb /= n;
   double sab = 0, saa = 0, sbb = 0;
   for(int i = de; i < ArraySize(a); i++)
     {
      sab += (a[i] - ma) * (b[i] - mb);
      saa += (a[i] - ma) * (a[i] - ma);
      sbb += (b[i] - mb) * (b[i] - mb);
     }
   return(sab / MathSqrt(saa * sbb));
  }

void MediaDP(const double &x[], double &media, double &dp)
  {
   int n = ArraySize(x);
   media = 0;
   for(int i = 0; i < n; i++) media += x[i];
   media /= n;
   dp = 0;
   for(int i = 0; i < n; i++) dp += (x[i] - media) * (x[i] - media);
   dp = MathSqrt(dp / (n - 1));
  }

//+------------------------------------------------------------------+
//| 1. Serie sintetica: os estagios por dentro                       |
//+------------------------------------------------------------------+
void Sintetico()
  {
   Log("--- 1. ARMA(1,1) sintetico: phi=" + DoubleToString(PHI_SINT, 2) + " theta=" + DoubleToString(THETA_SINT, 2) +
       " N=" + IntegerToString(N_SINT));
   double z[], e[];
   GerarARMA(PHI_SINT, THETA_SINT, N_SINT, z, e);

   PassosHR h;
   if(!HRPassoAPasso(z, 1, 1, true, 0, h))
     {
      Log("ERRO no HR sintetico");
      return;
     }
   double r[];
   Recursivos(z, h, r);

   CArima a;
   a.Definir(1, 0, 1, true);
   a.Ajustar(z);
   Log(StringFormat("  passo a passo: m=%d obs1=%d obs2=%d c=%.6f phi=%.6f theta=%.6f",
                    h.m, h.obs1, h.obs2, h.c, h.phi[0], h.theta[0]));
   Log(StringFormat("  CArima       : c=%.6f phi=%.6f theta=%.6f | iguais=%s", a.Constante(), a.Phi(0), a.Theta(0),
                    (MathAbs(a.Phi(0) - h.phi[0]) < 1e-12 && MathAbs(a.Theta(0) - h.theta[0]) < 1e-12) ? "SIM" : "NAO"));

   double corr1 = Correlacao(h.eps1, e, h.m);
   double corr2 = Correlacao(r, e, h.m);
   Log(StringFormat("  correlacao com o erro verdadeiro: estagio 1 = %.4f, residuo final = %.4f", corr1, corr2));

   Valor("SintPhi", PHI_SINT, 1); Valor("SintTheta", THETA_SINT, 1); Valor("SintN", N_SINT, 0);
   Valor("SintM", h.m, 0); Valor("SintObsUm", h.obs1, 0); Valor("SintObsDois", h.obs2, 0);
   Valor("SintPhiEst", h.phi[0], 3); Valor("SintThetaEst", h.theta[0], 3);
   Valor("SintCorrUm", corr1, 3); Valor("SintCorrFinal", corr2, 3);

   int f = Abrir("sint_serie.csv");
   FileWriteString(f, "t,z,eps,eps_est,eps_final\n");
   for(int t = 0; t < N_SINT; t++)
      FileWriteString(f, StringFormat("%d,%.6f,%.6f,%s,%.6f\n", t, z[t], e[t],
                      t >= h.m ? DoubleToString(h.eps1[t], 6) : "nan", r[t]));
   FileClose(f);

   //--- pesos do AR infinito equivalente, pi(j) = (phi + theta)(-theta)^(j-1), contra o AR longo
   f = Abrir("sint_pesos.csv");
   FileWriteString(f, "j,verdadeiro,estimado\n");
   for(int j = 1; j <= h.m; j++)
      FileWriteString(f, StringFormat("%d,%.6f,%.6f\n", j,
                      (PHI_SINT + THETA_SINT) * MathPow(-THETA_SINT, j - 1), h.ar[j]));
   FileClose(f);

   //--- efeito da ordem do AR longo
   f = Abrir("sint_ordem.csv");
   FileWriteString(f, "m,phi,theta,corr\n");
   int m_max = N_SINT / 5;
   for(int m = 1; m <= m_max; m++)
     {
      PassosHR g;
      if(!HRPassoAPasso(z, 1, 1, true, m, g))
         continue;
      FileWriteString(f, StringFormat("%d,%.6f,%.6f,%.6f\n", m, g.phi[0], g.theta[0], Correlacao(g.eps1, e, m_max)));
     }
   FileClose(f);
   Valor("SintMMax", m_max, 0);
  }

//+------------------------------------------------------------------+
//| 2. Monte Carlo                                                   |
//+------------------------------------------------------------------+
void MonteCarlo(const string nome, const double phi, const double theta, const int p)
  {
   double hr_phi[], hr_theta[], mv_phi[], mv_theta[], ing[];
   ArrayResize(hr_phi, REPLICAS); ArrayResize(hr_theta, REPLICAS);
   ArrayResize(mv_phi, REPLICAS); ArrayResize(mv_theta, REPLICAS); ArrayResize(ing, REPLICAS);
   int f = Abrir("mc_" + nome + ".csv");
   FileWriteString(f, "r,hr_phi,hr_theta,mv_phi,mv_theta,ingenuo\n");
   int ok = 0, sinal_certo = 0;
   uint t0 = GetTickCount();
   for(int r = 0; r < REPLICAS; r++)
     {
      double z[], e[];
      GerarARMA(phi, theta, N_SINT, z, e);
      CArima hr, mv, ar;
      hr.Definir(p, 0, 1, true);
      mv.Definir(p, 0, 1, true);
      mv.DefinirEstimacao(ESTIMACAO_VEROSSIMILHANCA);
      ar.Definir(1, 0, 0, true);   // ignora o MA: AR(1) por MQO
      if(!hr.Ajustar(z) || !mv.Ajustar(z) || !ar.Ajustar(z))
         continue;
      hr_phi[ok] = hr.Phi(0); hr_theta[ok] = hr.Theta(0);
      mv_phi[ok] = mv.Phi(0); mv_theta[ok] = mv.Theta(0); ing[ok] = ar.Phi(0);
      if(MathAbs(theta) > 0 && hr.Theta(0) * theta > 0)
         sinal_certo++;
      FileWriteString(f, StringFormat("%d,%.6f,%.6f,%.6f,%.6f,%.6f\n", r, hr.Phi(0), hr.Theta(0), mv.Phi(0), mv.Theta(0), ar.Phi(0)));
      ok++;
     }
   FileClose(f);
   ArrayResize(hr_phi, ok); ArrayResize(hr_theta, ok); ArrayResize(mv_phi, ok); ArrayResize(mv_theta, ok); ArrayResize(ing, ok);
   double m1, d1, m2, d2, m3, d3, m4, d4, m5, d5;
   MediaDP(hr_phi, m1, d1); MediaDP(hr_theta, m2, d2); MediaDP(mv_phi, m3, d3); MediaDP(mv_theta, m4, d4); MediaDP(ing, m5, d5);
   Log(StringFormat("--- 2. Monte Carlo %s (phi=%.4f theta=%.4f, %d de %d replicas, %.1f s)",
                    nome, phi, theta, ok, REPLICAS, (GetTickCount() - t0) / 1000.0));
   Log(StringFormat("  HR : phi %.4f (dp %.4f)  theta %.4f (dp %.4f)", m1, d1, m2, d2));
   Log(StringFormat("  MV : phi %.4f (dp %.4f)  theta %.4f (dp %.4f)", m3, d3, m4, d4));
   Log(StringFormat("  AR(1) ingenuo: phi %.4f (dp %.4f)", m5, d5));
   string s = (nome == "arma") ? "Arma" : "Ma";
   Valor("Mc" + s + "Replicas", ok, 0);
   Valor("Mc" + s + "HrPhi", m1, 3); Valor("Mc" + s + "HrPhiDp", d1, 3);
   Valor("Mc" + s + "HrTheta", m2, 3); Valor("Mc" + s + "HrThetaDp", d2, 3);
   Valor("Mc" + s + "MvPhi", m3, 3); Valor("Mc" + s + "MvPhiDp", d3, 3);
   Valor("Mc" + s + "MvTheta", m4, 3); Valor("Mc" + s + "MvThetaDp", d4, 3);
   Valor("Mc" + s + "Ingenuo", m5, 3); Valor("Mc" + s + "IngenuoDp", d5, 3);
   if(MathAbs(theta) > 0)
     {
      Valor("Mc" + s + "SinalCerto", 100.0 * sinal_certo / ok, 0);
      Log(StringFormat("  theta do HR com o sinal certo em %.1f%% das replicas", 100.0 * sinal_certo / ok));
     }
  }

//+------------------------------------------------------------------+
//| 3. Um pregao real do robo                                        |
//+------------------------------------------------------------------+
//--- A janela que o EA usou ao decidir no pregao 'dia': as JANELA barras fechadas antes dele
bool JanelaDoDia(const datetime dia, double &serie[], datetime &datas[], double &fech[])
  {
   int barra = iBarShift(SIMBOLO, PERIOD_D1, dia, true);
   if(barra < 0)
      return(false);
   if(CopyClose(SIMBOLO, PERIOD_D1, barra + 1, JANELA, fech) != JANELA ||
      CopyTime(SIMBOLO, PERIOD_D1, barra + 1, JANELA, datas) != JANELA)
      return(false);
   ArrayResize(serie, JANELA);
   for(int i = 0; i < JANELA; i++)
      serie[i] = MathLog(fech[i]);
   return(true);
  }

bool DiaReal(const string rotulo, const datetime dia, const int p, const int d, const int q, const bool detalhar)
  {
   double serie[], fech[];
   datetime datas[];
   if(!JanelaDoDia(dia, serie, datas, fech))
     {
      Log("ERRO: janela de " + DataBR(dia));
      return(false);
     }
   CArima a;
   a.Definir(p, d, q, true);
   if(!a.Ajustar(serie))
     {
      Log("ERRO no CArima em " + DataBR(dia));
      return(false);
     }
   double z[];
   ArrayResize(z, JANELA - d);
   for(int i = 0; i < JANELA - d; i++)
      z[i] = (d == 1) ? serie[i + 1] - serie[i] : serie[i];

   PassosHR h;
   if(!HRPassoAPasso(z, p, q, true, 0, h))
     {
      Log("ERRO no HR passo a passo em " + DataBR(dia));
      return(false);
     }
   double r[];
   Recursivos(z, h, r);

   //--- previsao como no EA (d = 1): c + phi z + theta e, com os residuos recursivos
   double prev = h.c, parte_ar = 0, parte_ma = 0;
   int n = ArraySize(z);
   for(int i = 0; i < p; i++) parte_ar += h.phi[i] * z[n - 1 - i];
   for(int j = 0; j < q; j++) parte_ma += h.theta[j] * r[n - 1 - j];
   prev += parte_ar + parte_ma;

   string coef = "";
   for(int i = 0; i < p; i++) coef += StringFormat(" phi%d=%.10g", i + 1, h.phi[i]);
   for(int j = 0; j < q; j++) coef += StringFormat(" theta%d=%.10g", j + 1, h.theta[j]);
   Log(StringFormat("--- 3. Pregao real %s, ARIMA(%d,%d,%d) com constante, janela %s a %s",
                    DataBR(dia), p, d, q, DataBR(datas[0]), DataBR(datas[JANELA - 1])));
   Log(StringFormat("  passo a passo: m=%d obs1=%d obs2=%d primeiro=%d c=%.10g%s prev=%.10g",
                    h.m, h.obs1, h.obs2, h.primeiro, h.c, coef, prev));
   Log(StringFormat("  CArima       : c=%.10g theta1=%.10g prev=%.10g", a.Constante(), a.Theta(0), a.PreverDiferenciado()));
   // linha para o script de conferencia: rotulo;data;c;theta1..q;prev
   string linha = StringFormat("CONFERIR;%s;%s;%.10g", rotulo, TimeToString(dia, TIME_DATE), h.c);
   for(int j = 0; j < q; j++) linha += StringFormat(";%.10g", h.theta[j]);
   linha += StringFormat(";%.10g", prev);
   Log(linha);

   if(!detalhar)
      return(true);

   //--- maxima verossimilhanca e AR ingenuo na mesma janela, para comparar
   CArima mv;
   mv.Definir(p, d, q, true);
   mv.DefinirEstimacao(ESTIMACAO_VEROSSIMILHANCA);
   mv.Ajustar(serie);
   Log(StringFormat("  MV na mesma janela: c=%.10g theta1=%.10g prev=%.10g", mv.Constante(), mv.Theta(0), mv.PreverDiferenciado()));

   double dp1 = MathSqrt(h.sqr1 / h.obs1);
   double corr = Correlacao(h.eps1, r, h.m);
   Log(StringFormat("  estagio 1: SQR=%.8g dp=%.6f%% | correlacao eps estagio 1 x residuo final = %.4f", h.sqr1, 100 * dp1, corr));
   Log(StringFormat("  previsao: c=%.6f%% + theta*e(N)=%.6f%% = %.6f%% (e(N)=%.6f%%)",
                    100 * h.c, 100 * parte_ma, 100 * prev, 100 * r[n - 1]));

   Texto("DiaReal", DataBR(dia));
   Texto("JanIni", DataBR(datas[0])); Texto("JanFim", DataBR(datas[JANELA - 1]));
   Valor("RealN", n, 0); Valor("RealM", h.m, 0); Valor("RealObsUm", h.obs1, 0); Valor("RealObsDois", h.obs2, 0);
   Valor("RealPrimeiro", h.primeiro, 0);
   Valor("RealC", 100 * h.c, 4); Valor("RealTheta", h.theta[0], 4);
   Valor("RealPrev", 100 * prev, 4); Valor("RealParteMa", 100 * parte_ma, 4); Valor("RealEN", 100 * r[n - 1], 3);
   Valor("RealDpUm", 100 * dp1, 2); Valor("RealCorr", corr, 3);
   Valor("RealMvTheta", mv.Theta(0), 4); Valor("RealMvC", 100 * mv.Constante(), 4); Valor("RealMvPrev", 100 * mv.PreverDiferenciado(), 4);
   Valor("RealFechUlt", fech[JANELA - 1], 2);

   int f = Abrir("real_serie.csv");
   FileWriteString(f, "i,data,fechamento,z,eps_est,eps_final\n");
   for(int i = 0; i < n; i++)
      FileWriteString(f, StringFormat("%d,%s,%.2f,%.6f,%s,%.6f\n", i, DataISO(datas[i + d]), fech[i + d], 100 * z[i],
                      i >= h.m ? DoubleToString(100 * h.eps1[i], 6) : "nan", 100 * r[i]));
   FileClose(f);

   f = Abrir("real_pesos.csv");
   FileWriteString(f, "j,coef\n");
   for(int j = 1; j <= h.m; j++)
      FileWriteString(f, StringFormat("%d,%.6f\n", j, h.ar[j]));
   FileClose(f);

   f = Abrir("real_estagio2.csv");
   FileWriteString(f, "eps_ant,z\n");
   for(int t = h.primeiro; t < n; t++)
      FileWriteString(f, StringFormat("%.6f,%.6f\n", 100 * h.eps1[t - 1], 100 * z[t]));
   FileClose(f);

   //--- as primeiras linhas das duas matrizes, para as tabelas do relatorio
   f = Abrir("real_matrizes.tex");
   for(int k = 0; k < 4; k++)
     {
      int t = h.m + k;
      FileWriteString(f, StringFormat("\\def\\vHMatUm%s{%s & %s & 1 & %s & %s & %s & $\\cdots$ & %s\\\\}\n",
                      CharToString((uchar)('a' + k)), DataBR(datas[t + d]), Num(100 * z[t]),
                      Num(100 * z[t - 1]), Num(100 * z[t - 2]), Num(100 * z[t - 3]), Num(100 * z[t - h.m])));
     }
   for(int k = 0; k < 4; k++)
     {
      int t = h.primeiro + k;
      FileWriteString(f, StringFormat("\\def\\vHMatDois%s{%s & %s & 1 & %s\\\\}\n",
                      CharToString((uchar)('a' + k)), DataBR(datas[t + d]), Num(100 * z[t]), Num(100 * h.eps1[t - 1])));
     }
   FileClose(f);
   return(true);
  }

string Num(const double v)
  {
   string s = DoubleToString(v, 3);
   StringReplace(s, ".", "{,}");
   if(StringGetCharacter(s, 0) == '-')
      s = "$-$" + StringSubstr(s, 1);
   return(s);
  }

void OnStart()
  {
   FolderCreate("AlgoLab_hr");
   g_resumo  = Abrir("resumo.txt");
   g_valores = Abrir("valores.tex");
   MathSrand(SEMENTE);
   Log("================ HANNAN-RISSANEN DETALHADO ================");

   Sintetico();

   //--- dias do traco (refeito_2026-10-05/traco_demo/traco_demo_GARCH.csv) com termo MA
   if(!DiaReal("MA1", D'2021.05.13', 0, 1, 1, true))
      Log("ERRO no dia detalhado");
   DiaReal("MA4", D'2020.06.05', 0, 1, 4, false);

   MonteCarlo("arma", PHI_SINT, THETA_SINT, 1);
   //--- MA(1) com o theta que o robo estimou no pregao detalhado
   CArima a;
   double serie[], fech[];
   datetime datas[];
   if(JanelaDoDia(D'2021.05.13', serie, datas, fech))
     {
      a.Definir(0, 1, 1, true);
      a.Ajustar(serie);
      MonteCarlo("ma", 0.0, a.Theta(0), 0);
     }

   Log("================ FIM ================");
   FileClose(g_valores);
   FileClose(g_resumo);
  }
