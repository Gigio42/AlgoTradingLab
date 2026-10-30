//+------------------------------------------------------------------+
//| TestesFormulas.mq5 - testes que mostram que o codigo do robo     |
//| calcula o que as formulas dizem (30/10/2026, relatorio em        |
//| ia/relatorios/testes-do-codigo/).                                |
//|                                                                  |
//| Dois tipos de teste:                                             |
//|  - identidade: a mesma conta refeita aqui de forma independente, |
//|    a partir da formula, tem de dar o mesmo numero que o codigo   |
//|    do robo (diferenca no nivel do arredondamento da maquina);    |
//|  - simulacao: com dados gerados de propriedades conhecidas, o    |
//|    resultado tem de bater com a teoria (ex.: um teste a 5%       |
//|    rejeita cerca de 5% das vezes quando H0 e verdadeira).        |
//| Para rodar: ferramentas/scripts/testes_formulas.sh.              |
//+------------------------------------------------------------------+
#include "..\Experts\AlgoTradingLab\robos\Include\SelecaoModelo.mqh"
#include "..\Experts\AlgoTradingLab\robos\Include\Garch.mqh"
#include <Math\Stat\T.mqh>
#include <Math\Stat\ChiSquare.mqh>

#define PASTA       "AlgoLab_testes\\"
#define SIMBOLO     "PETR4_OFICIAL"
#define FIM_JANELA  D'2026.09.18'
#define TAMANHO     500
#define N_ROBO      240
#define SEMENTE     20261031

int g_resumo = INVALID_HANDLE, g_valores = INVALID_HANDLE, g_ident = INVALID_HANDLE;
int g_num_ident = 0;

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

//--- \vTNome = numero para o texto (virgula decimal); \pTNome = numero para coordenada
void Valor(const string nome, const double v, const int digitos)
  {
   string s = DoubleToString(v, digitos);
   string texto = s;
   StringReplace(texto, ".", "{,}");
   if(StringGetCharacter(texto, 0) == '-')
      texto = "\\ensuremath{-}" + StringSubstr(texto, 1);
   FileWriteString(g_valores, StringFormat("\\def\\vT%s{%s}\n\\def\\pT%s{%s}\n", nome, texto, nome, s));
  }

//--- Numero em notacao cientifica para o texto: 1,2 x 10^-15
void ValorCientifico(const string nome, const double v)
  {
   if(v == 0.0)
     {
      FileWriteString(g_valores, StringFormat("\\def\\vT%s{0}\n", nome));
      return;
     }
   int e = (int)MathFloor(MathLog10(MathAbs(v)));
   double m = v / MathPow(10.0, e);
   string s = DoubleToString(m, 1);
   StringReplace(s, ".", "{,}");
   FileWriteString(g_valores, StringFormat("\\def\\vT%s{\\ensuremath{%s\\times 10^{%d}}}\n", nome, s, e));
  }

//--- Registra uma identidade: o codigo do robo contra a formula refeita aqui
void Identidade(const string id, const string descricao, const double erro)
  {
   g_num_ident++;
   double e = MathAbs(erro);
   Log(StringFormat("  [%s] %s: diferenca = %.3e", id, descricao, e));
   //--- sem '%' no CSV: o pgfplots le '%' como comentario e corta a linha
   string sem_porcento = descricao;
   StringReplace(sem_porcento, "%", " por cento");
   FileWriteString(g_ident, StringFormat("%d;%s;%s;%.6e;%.4f\n", g_num_ident, id, sem_porcento, e,
                   (e > 0.0) ? MathLog10(e) : -17.0));
   ValorCientifico("Id" + id, e);
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

//--- Sistema linear pequeno por eliminacao de Gauss com pivoteamento parcial.
//--- Escrito aqui, sem a ALGLIB, para conferir o MQO do robo por outro caminho.
bool ResolverGauss(double &A[][20], double &b[], const int k, double &x[])
  {
   for(int c = 0; c < k; c++)
     {
      int piv = c;
      for(int r = c + 1; r < k; r++)
         if(MathAbs(A[r][c]) > MathAbs(A[piv][c]))
            piv = r;
      if(MathAbs(A[piv][c]) < 1e-300)
         return(false);
      if(piv != c)
        {
         for(int j = 0; j < k; j++) { double t = A[c][j]; A[c][j] = A[piv][j]; A[piv][j] = t; }
         double t = b[c]; b[c] = b[piv]; b[piv] = t;
        }
      for(int r = c + 1; r < k; r++)
        {
         double f = A[r][c] / A[c][c];
         for(int j = c; j < k; j++)
            A[r][j] -= f * A[c][j];
         b[r] -= f * b[c];
        }
     }
   ArrayResize(x, k);
   for(int r = k - 1; r >= 0; r--)
     {
      double s = b[r];
      for(int j = r + 1; j < k; j++)
         s -= A[r][j] * x[j];
      x[r] = s / A[r][r];
     }
   return(true);
  }

//--- MQO pelas equacoes normais, montadas e resolvidas aqui
bool MQOIndependente(CMatrixDouble &X, const double &y[], const int n, const int k, double &b[])
  {
   double A[][20], c[];
   ArrayResize(A, k);
   ArrayResize(c, k);
   for(int i = 0; i < k; i++)
     {
      c[i] = 0;
      for(int t = 0; t < n; t++) c[i] += X.Get(t, i) * y[t];
      for(int j = 0; j < k; j++)
        {
         A[i][j] = 0;
         for(int t = 0; t < n; t++) A[i][j] += X.Get(t, i) * X.Get(t, j);
        }
     }
   return(ResolverGauss(A, c, k, b));
  }

double MaxDifRel(const double &a[], const double &b[], const int k)
  {
   double m = 0;
   for(int i = 0; i < k; i++)
      m = MathMax(m, MathAbs(a[i] - b[i]) / MathMax(1.0, MathAbs(b[i])));
   return(m);
  }

//--- Autocorrelacao pela formula do livro, escrita aqui
double AutocorrelacaoIndependente(const double &x[], const int k)
  {
   int n = ArraySize(x);
   double m = 0;
   for(int i = 0; i < n; i++) m += x[i];
   m /= n;
   double num = 0, den = 0;
   for(int t = 0; t < n; t++) den += (x[t] - m) * (x[t] - m);
   for(int t = k; t < n; t++) num += (x[t] - m) * (x[t - k] - m);
   return(num / den);
  }

double TaxaPercentual(const int sucessos, const int total) { return(100.0 * sucessos / total); }

//--- Erro-padrao de uma proporcao estimada por simulacao, em pontos percentuais
double EpPercentual(const double p, const int total) { return(100.0 * MathSqrt(p * (1 - p) / total)); }

//--- Dados reais: a janela da validacao numerica (log-precos)
bool CarregarJanela(double &log_preco[])
  {
   double fech[];
   if(CopyClose(SIMBOLO, PERIOD_D1, FIM_JANELA, TAMANHO, fech) != TAMANHO)
      return(false);
   ArrayResize(log_preco, TAMANHO);
   for(int i = 0; i < TAMANHO; i++)
      log_preco[i] = MathLog(fech[i]);
   return(true);
  }

void Diferenca(const double &y[], double &z[])
  {
   int n = ArraySize(y);
   ArrayResize(z, n - 1);
   for(int i = 0; i < n - 1; i++)
      z[i] = y[i + 1] - y[i];
  }

void PasseioAleatorio(const int n, double &y[])
  {
   ArrayResize(y, n);
   y[0] = 0;
   for(int i = 1; i < n; i++)
      y[i] = y[i - 1] + Randn();
  }

void AR1(const double phi, const int n, double &y[])
  {
   ArrayResize(y, n);
   y[0] = Randn() / MathSqrt(MathMax(1e-6, 1 - phi * phi));
   for(int i = 1; i < n; i++)
      y[i] = phi * y[i - 1] + Randn();
  }

void ARMA11(const double phi, const double theta, const int n, double &z[])
  {
   int total = n + 200;
   double zz[], ee[];
   ArrayResize(zz, total); ArrayResize(ee, total);
   zz[0] = 0; ee[0] = Randn();
   for(int t = 1; t < total; t++)
     {
      ee[t] = Randn();
      zz[t] = phi * zz[t - 1] + ee[t] + theta * ee[t - 1];
     }
   ArrayResize(z, n);
   for(int i = 0; i < n; i++) z[i] = zz[200 + i];
  }

//+------------------------------------------------------------------+
//| A. Minimos quadrados (Numerico.mqh)                              |
//+------------------------------------------------------------------+
void TestesMQO(const double &z[])
  {
   Log("--- A. MQO");
   //--- A1: dados sem ruido, y = 2 + 3x - 0,5x^2: tem de recuperar exatamente
   int n = 50;
   CMatrixDouble X(n, 3);
   double y[], b[], ep[], sqr;
   ArrayResize(y, n);
   for(int t = 0; t < n; t++)
     {
      double x = t / 10.0;
      X.Set(t, 0, 1.0); X.Set(t, 1, x); X.Set(t, 2, x * x);
      y[t] = 2.0 + 3.0 * x - 0.5 * x * x;
     }
   MQO(X, y, n, 3, b, ep, sqr, true);
   double verdade[] = {2.0, 3.0, -0.5};
   Identidade("Aum", "MQO recupera y = 2 + 3x - 0,5x^2 sem ruido", MaxDifRel(b, verdade, 3));

   //--- A2: regressao simples nos retornos reais, contra a formula fechada b = Sxy/Sxx
   int m = ArraySize(z) - 1;
   CMatrixDouble X2(m, 2);
   double y2[];
   ArrayResize(y2, m);
   double mx = 0, my = 0;
   for(int t = 0; t < m; t++)
     {
      X2.Set(t, 0, 1.0); X2.Set(t, 1, z[t]); y2[t] = z[t + 1];
      mx += z[t]; my += z[t + 1];
     }
   mx /= m; my /= m;
   double sxx = 0, sxy = 0;
   for(int t = 0; t < m; t++) { sxx += (z[t] - mx) * (z[t] - mx); sxy += (z[t] - mx) * (z[t + 1] - my); }
   double bf = sxy / sxx, af = my - bf * mx;
   double ssr = 0;
   for(int t = 0; t < m; t++) { double r = z[t + 1] - af - bf * z[t]; ssr += r * r; }
   double s2 = ssr / (m - 2);
   double se_b = MathSqrt(s2 / sxx), se_a = MathSqrt(s2 * (1.0 / m + mx * mx / sxx));
   double b2[], ep2[], sqr2;
   MQO(X2, y2, m, 2, b2, ep2, sqr2, true);
   Identidade("Adois", "Coeficientes da regressao simples (formula fechada Sxy/Sxx)",
              MathMax(MathAbs(b2[1] - bf) / MathAbs(bf), MathAbs(b2[0] - af) / MathAbs(af)));
   Identidade("Atres", "Erros-padrao da regressao simples (formula fechada)",
              MathMax(MathAbs(ep2[1] - se_b) / se_b, MathAbs(ep2[0] - se_a) / se_a));
   Identidade("Aquatro", "Soma dos quadrados dos residuos", MathAbs(sqr2 - ssr) / ssr);

   //--- A3: AR(5) com constante: MQO do robo (ALGLIB) contra eliminacao de Gauss escrita aqui,
   //--- e ortogonalidade dos residuos (X'e = 0, a condicao que define o MQO)
   int k = 6, n5 = ArraySize(z) - 5;
   CMatrixDouble X5(n5, k);
   double y5[];
   ArrayResize(y5, n5);
   for(int t = 5; t < ArraySize(z); t++)
     {
      int l = t - 5;
      y5[l] = z[t];
      X5.Set(l, 0, 1.0);
      for(int i = 1; i <= 5; i++) X5.Set(l, i, z[t - i]);
     }
   double b5[], ep5[], sqr5, g5[];
   MQO(X5, y5, n5, k, b5, ep5, sqr5, false);
   MQOIndependente(X5, y5, n5, k, g5);
   Identidade("Acinco", "AR(5): ALGLIB contra eliminacao de Gauss independente", MaxDifRel(b5, g5, k));
   double pior = 0;
   for(int j = 0; j < k; j++)
     {
      double xe = 0, xx = 0, ee = 0;
      for(int t = 0; t < n5; t++)
        {
         double e = y5[t];
         for(int i = 0; i < k; i++) e -= X5.Get(t, i) * b5[i];
         xe += X5.Get(t, j) * e; xx += X5.Get(t, j) * X5.Get(t, j); ee += e * e;
        }
      pior = MathMax(pior, MathAbs(xe) / MathSqrt(xx * ee));
     }
   Identidade("Aseis", "Ortogonalidade X'e = 0 (cosseno entre cada coluna e o residuo)", pior);

   //--- A5: cobertura do intervalo de 95% (testa os erros-padrao em media)
   int R = 2000, cobre = 0, nn = 240;
   int erro = 0;
   double tq = MathQuantileT(0.975, nn - 2, erro);
   for(int r = 0; r < R; r++)
     {
      CMatrixDouble Xc(nn, 2);
      double yc[], bc[], ec[], sc;
      ArrayResize(yc, nn);
      for(int t = 0; t < nn; t++)
        {
         double x = Randn();
         Xc.Set(t, 0, 1.0); Xc.Set(t, 1, x);
         yc[t] = 1.0 + 0.5 * x + Randn();
        }
      MQO(Xc, yc, nn, 2, bc, ec, sc, true);
      if(MathAbs(bc[1] - 0.5) <= tq * ec[1]) cobre++;
     }
   double cob = TaxaPercentual(cobre, R);
   Log(StringFormat("  [A5] cobertura do IC 95%% em %d simulacoes: %.2f%% (ep %.2f p.p.)", R, cob, EpPercentual(0.95, R)));
   Valor("CoberturaR", R, 0); Valor("Cobertura", cob, 1); Valor("CoberturaEp", EpPercentual(0.95, R), 1);
  }

//+------------------------------------------------------------------+
//| B. ADF (Estatistica.mqh, SelecaoModelo.mqh)                      |
//+------------------------------------------------------------------+
void TestesADF(const double &log_preco[])
  {
   Log("--- B. ADF");
   //--- B1: sem defasagens, a estatistica e o t da regressao simples dy = a + g y(t-1)
   int n = ArraySize(log_preco), m = n - 1;
   double mx = 0, my = 0;
   for(int t = 1; t < n; t++) { mx += log_preco[t - 1]; my += log_preco[t] - log_preco[t - 1]; }
   mx /= m; my /= m;
   double sxx = 0, sxy = 0;
   for(int t = 1; t < n; t++)
     {
      double dy = log_preco[t] - log_preco[t - 1];
      sxx += (log_preco[t - 1] - mx) * (log_preco[t - 1] - mx);
      sxy += (log_preco[t - 1] - mx) * (dy - my);
     }
   double g = sxy / sxx, a = my - g * mx, ssr = 0;
   for(int t = 1; t < n; t++) { double r = log_preco[t] - log_preco[t - 1] - a - g * log_preco[t - 1]; ssr += r * r; }
   double t_formula = g / MathSqrt(ssr / (m - 2) / sxx);
   double estat = 0, aic = 0; int obs = 0;
   RegressaoADF(log_preco, ADF_CONSTANTE, 0, 1, estat, aic, obs);
   Identidade("Bum", "Estatistica de Dickey-Fuller sem defasagens (t da regressao simples)", MathAbs(estat - t_formula) / MathAbs(t_formula));

   //--- B2: valor critico de MacKinnon (2010) no limite T -> infinito e em T = 240
   Identidade("Bdois", "Valor critico 5% com constante, T infinito (tabela: -2,86154)",
              MathAbs(ValorCriticoADF5(ADF_CONSTANTE, 1000000000) - (-2.86154)));
   Valor("VcDuzentos", ValorCriticoADF5(ADF_CONSTANTE, 225), 3);

   //--- B3: tamanho do teste. Passeios aleatorios (H0 verdadeira): deve rejeitar ~5%
   int R = 5000, rej_auto = 0, rej_zero = 0;
   double estats[];
   ArrayResize(estats, R);
   int f = Abrir("adf_h0.csv");
   FileWriteString(f, "estatistica\n");
   for(int r = 0; r < R; r++)
     {
      double y[];
      PasseioAleatorio(N_ROBO, y);
      ResultadoADF res, res0;
      TesteADF(y, ADF_CONSTANTE, -1, res);
      TesteADF(y, ADF_CONSTANTE, 0, res0);
      estats[r] = res.estatistica;
      if(res.estacionaria) rej_auto++;
      if(res0.estacionaria) rej_zero++;
      FileWriteString(f, StringFormat("%.5f\n", res.estatistica));
     }
   FileClose(f);
   double q5 = Percentil(estats, 5.0);
   Log(StringFormat("  [B3] H0 verdadeira, %d passeios de %d: rejeitou %.2f%% (defasagens pelo AIC) e %.2f%% (sem defasagens); "
                    "quantil 5%% empirico = %.3f", R, N_ROBO, TaxaPercentual(rej_auto, R), TaxaPercentual(rej_zero, R), q5));
   Valor("AdfR", R, 0); Valor("AdfTamanho", TaxaPercentual(rej_auto, R), 1); Valor("AdfTamanhoZero", TaxaPercentual(rej_zero, R), 1);
   Valor("AdfEp", EpPercentual(0.05, R), 1); Valor("AdfQuantil", q5, 3);

   //--- B4: poder. AR(1) estacionario com phi perto de 1: deve rejeitar mais quanto menor o phi
   double phis[] = {0.80, 0.85, 0.90, 0.95, 0.98};
   int Rp = 2000;
   f = Abrir("adf_poder.csv");
   FileWriteString(f, "phi,rejeicao\n");
   for(int i = 0; i < ArraySize(phis); i++)
     {
      int rej = 0;
      for(int r = 0; r < Rp; r++)
        {
         double y[];
         AR1(phis[i], N_ROBO, y);
         ResultadoADF res;
         TesteADF(y, ADF_CONSTANTE, -1, res);
         if(res.estacionaria) rej++;
        }
      FileWriteString(f, StringFormat("%.2f,%.2f\n", phis[i], TaxaPercentual(rej, Rp)));
      Log(StringFormat("  [B4] phi=%.2f: rejeitou %.1f%%", phis[i], TaxaPercentual(rej, Rp)));
      string rotulos[] = {"Oitenta", "OitentaCinco", "Noventa", "NoventaCinco", "NoventaOito"};
      Valor("AdfPoder" + rotulos[i], TaxaPercentual(rej, Rp), 1);
     }
   FileWriteString(f, StringFormat("1.00,%.2f\n", TaxaPercentual(rej_auto, R)));
   FileClose(f);
   Valor("AdfPoderR", Rp, 0);

   //--- B5: o d escolhido pelo ADF em sequencia, para series I(0), I(1) e I(2) conhecidas
   int Rd = 1000;
   f = Abrir("adf_ordem_d.csv");
   FileWriteString(f, "serie,d0,d1,d2\n");
   string nomes[] = {"I(0)", "I(1)", "I(2)"};
   for(int tipo = 0; tipo < 3; tipo++)
     {
      int cont[3] = {0, 0, 0};
      for(int r = 0; r < Rd; r++)
        {
         double y[];
         if(tipo == 0) AR1(0.5, N_ROBO, y);
         else
           {
            PasseioAleatorio(N_ROBO, y);
            if(tipo == 2)
               for(int i = 1; i < N_ROBO; i++) y[i] += y[i - 1];
           }
         string rel;
         int d = DeterminarOrdemD(y, 2, ADF_CONSTANTE, rel);
         if(d >= 0 && d <= 2) cont[d]++;
        }
      FileWriteString(f, StringFormat("%d,%.1f,%.1f,%.1f\n", tipo, TaxaPercentual(cont[0], Rd), TaxaPercentual(cont[1], Rd), TaxaPercentual(cont[2], Rd)));
      Log(StringFormat("  [B5] %s: d=0 %.1f%%  d=1 %.1f%%  d=2 %.1f%%", nomes[tipo],
                       TaxaPercentual(cont[0], Rd), TaxaPercentual(cont[1], Rd), TaxaPercentual(cont[2], Rd)));
      string rotulos[] = {"Zero", "Um", "Dois"};
      Valor("DCerto" + rotulos[tipo], TaxaPercentual(cont[tipo], Rd), 1);
     }
   FileClose(f);
   Valor("DR", Rd, 0);
  }

//+------------------------------------------------------------------+
//| C. Ljung-Box (Estatistica.mqh)                                   |
//+------------------------------------------------------------------+
void TestesLjungBox(const double &residuos[])
  {
   Log("--- C. Ljung-Box");
   //--- C1: Q refeito pela formula, com autocorrelacao escrita aqui
   int n = ArraySize(residuos), h = 10;
   double soma = 0;
   for(int k = 1; k <= h; k++)
     {
      double r = AutocorrelacaoIndependente(residuos, k);
      soma += r * r / (n - k);
     }
   double q_formula = n * (n + 2.0) * soma;
   ResultadoLjungBox lb;
   TesteLjungBox(residuos, h, 2, lb);
   Identidade("Cum", "Estatistica Q de Ljung-Box (residuos reais do ARIMA(1,1,1))", MathAbs(lb.estatistica - q_formula) / q_formula);
   int erro = 0;
   double p_formula = 1.0 - MathCumulativeDistributionChiSquare(q_formula, 8.0, erro);
   Identidade("Cdois", "p-valor contra qui-quadrado com 10 - 2 graus de liberdade", MathAbs(lb.pvalor - p_formula));

   //--- C2: tamanho. Ruido branco: Q segue qui-quadrado(10), rejeita ~5%
   int R = 5000, rej = 0;
   int f = Abrir("lb_h0.csv");
   FileWriteString(f, "q\n");
   for(int r = 0; r < R; r++)
     {
      double x[];
      ArrayResize(x, N_ROBO - 1);
      for(int i = 0; i < N_ROBO - 1; i++) x[i] = Randn();
      ResultadoLjungBox l;
      TesteLjungBox(x, h, 0, l);
      if(!l.ruido_branco) rej++;
      FileWriteString(f, StringFormat("%.5f\n", l.estatistica));
     }
   FileClose(f);
   f = Abrir("lb_densidade.csv");
   FileWriteString(f, "q,densidade\n");
   for(double q = 0.1; q <= 40.0; q += 0.1)
      FileWriteString(f, StringFormat("%.2f,%.6f\n", q, MathProbabilityDensityChiSquare(q, 10.0, false, erro)));
   FileClose(f);
   Log(StringFormat("  [C3] ruido branco, %d series: rejeitou %.2f%% (ep %.2f p.p.)", R, TaxaPercentual(rej, R), EpPercentual(0.05, R)));
   Valor("LbR", R, 0); Valor("LbTamanho", TaxaPercentual(rej, R), 1); Valor("LbEp", EpPercentual(0.05, R), 1);

   //--- C3: residuos de um ARMA(1,1) ajustado: com o desconto de p+q graus de liberdade
   //--- o tamanho volta a ~5%; sem o desconto fica abaixo
   int Ra = 2000, rej_com = 0, rej_sem = 0, ok = 0;
   for(int r = 0; r < Ra; r++)
     {
      double z[];
      ARMA11(0.6, 0.4, N_ROBO - 1, z);
      CArima a;
      a.Definir(1, 0, 1, true);
      if(!a.Ajustar(z)) continue;
      double res[];
      a.ObterResiduos(res);
      ResultadoLjungBox l2, l0;
      TesteLjungBox(res, h, 2, l2);
      TesteLjungBox(res, h, 0, l0);
      ok++;
      if(!l2.ruido_branco) rej_com++;
      if(!l0.ruido_branco) rej_sem++;
     }
   Log(StringFormat("  [C4] residuos de ARMA(1,1) ajustado, %d series: rejeitou %.2f%% com gl = 8 e %.2f%% com gl = 10",
                    ok, TaxaPercentual(rej_com, ok), TaxaPercentual(rej_sem, ok)));
   Valor("LbArmaR", ok, 0); Valor("LbArmaCom", TaxaPercentual(rej_com, ok), 1); Valor("LbArmaSem", TaxaPercentual(rej_sem, ok), 1);

   //--- C4: poder. Serie com autocorrelacao (AR(1) com phi = 0,2): deve rejeitar quase sempre
   int Rp = 2000, rejp = 0;
   for(int r = 0; r < Rp; r++)
     {
      double y[];
      AR1(0.2, N_ROBO - 1, y);
      ResultadoLjungBox l;
      TesteLjungBox(y, h, 0, l);
      if(!l.ruido_branco) rejp++;
     }
   Log(StringFormat("  [C5] AR(1) phi=0,2: rejeitou %.1f%%", TaxaPercentual(rejp, Rp)));
   Valor("LbPoder", TaxaPercentual(rejp, Rp), 1); Valor("LbPoderR", Rp, 0);
  }

//+------------------------------------------------------------------+
//| D. Verossimilhanca e AIC do ARIMA, e a escolha das ordens        |
//+------------------------------------------------------------------+
void TestesAIC(const double &log_preco[])
  {
   Log("--- D. Verossimilhanca, AIC e selecao");
   CArima a;
   a.Definir(1, 1, 1, true);
   a.Ajustar(log_preco);
   double res[];
   a.ObterResiduos(res);
   int n = ArraySize(res);
   double ssr = 0;
   for(int i = 0; i < n; i++) ssr += res[i] * res[i];
   double s2 = ssr / n;
   double logl = -0.5 * n * (MathLog(2 * M_PI) + MathLog(s2) + 1.0);
   Identidade("Dum", "log L gaussiana do ARIMA(1,1,1): -n/2 [ln 2pi + ln sigma2 + 1]", MathAbs(a.LogVerossimilhanca() - logl) / MathAbs(logl));
   Identidade("Ddois", "AIC = -2 log L + 2k, com k = p + q + constante + variancia",
              MathAbs(a.AIC() - (-2 * logl + 2 * 4)) / MathAbs(a.AIC()));

   //--- D2: amostra comum: todos os 25 candidatos somam o mesmo numero de observacoes
   int minimo = INT_MAX, maximo = 0;
   for(int p = 0; p <= 4; p++)
      for(int q = 0; q <= 4; q++)
        {
         CArima c;
         c.Definir(p, 1, q, true);
         c.DefinirAquecimentoMinimo(4);
         if(!c.Ajustar(log_preco)) continue;
         minimo = MathMin(minimo, c.ObservacoesEfetivas());
         maximo = MathMax(maximo, c.ObservacoesEfetivas());
        }
   Identidade("Dtres", "Amostra comum: maior menos menor numero de observacoes entre os 25 candidatos", maximo - minimo);
   Valor("AmostraComum", minimo, 0);

   //--- D3: a grade do AIC em series com ordem verdadeira conhecida
   int R = 500;
   string casos[] = {"ar1", "passeio"};
   for(int caso = 0; caso < 2; caso++)
     {
      int freq[5][5];
      ArrayInitialize(freq, 0);
      int ok = 0;
      for(int r = 0; r < R; r++)
        {
         double z[];
         if(caso == 0) AR1(0.5, N_ROBO - 1, z);
         else
           {
            ArrayResize(z, N_ROBO - 1);
            for(int i = 0; i < N_ROBO - 1; i++) z[i] = Randn();
           }
         //--- vira log-preco (d = 1), como no robo
         double y[];
         ArrayResize(y, N_ROBO);
         y[0] = 0;
         for(int i = 1; i < N_ROBO; i++) y[i] = y[i - 1] + 0.01 * z[i - 1];
         ResultadoSelecao sel;
         string tabela;
         if(!BuscarMelhorPQ(y, 1, 4, 4, true, sel, tabela)) continue;
         freq[sel.p][sel.q]++;
         ok++;
        }
      int f = Abrir("aic_selecao_" + casos[caso] + ".csv");
      FileWriteString(f, "p,q,pct\n");
      for(int p = 0; p <= 4; p++)
        {
         for(int q = 0; q <= 4; q++)
            FileWriteString(f, StringFormat("%d,%d,%.1f\n", p, q, TaxaPercentual(freq[p][q], ok)));
         FileWriteString(f, "\n");
        }
      FileClose(f);
      int certo = (caso == 0) ? freq[1][0] : freq[0][0];
      Log(StringFormat("  [D3] %s: %d series, ordem verdadeira escolhida em %.1f%%", casos[caso], ok, TaxaPercentual(certo, ok)));
      string s = (caso == 0) ? "Ar" : "Passeio";
      Valor("Sel" + s + "Certo", TaxaPercentual(certo, ok), 1);
      Valor("Sel" + s + "R", ok, 0);
      //--- quantos ficaram a no maximo um termo da verdade (p + q da escolha <= verdade + 1)
      int perto = 0;
      for(int p = 0; p <= 4; p++)
         for(int q = 0; q <= 4; q++)
            if(p + q <= ((caso == 0) ? 2 : 1)) perto += freq[p][q];
      Valor("Sel" + s + "Perto", TaxaPercentual(perto, ok), 1);
     }
  }

//+------------------------------------------------------------------+
//| E. Hannan-Rissanen (Arima.mqh)                                   |
//+------------------------------------------------------------------+
void TestesHR(const double &z[])
  {
   Log("--- E. Hannan-Rissanen");
   //--- E1: sem MA, o ARIMA e um MQO comum: AR(2) do robo contra Gauss escrito aqui
   CArima a;
   a.Definir(2, 0, 0, true);
   a.Ajustar(z);
   int n = ArraySize(z) - 2;
   CMatrixDouble X(n, 3);
   double y[], b[];
   ArrayResize(y, n);
   for(int t = 2; t < ArraySize(z); t++)
     {
      X.Set(t - 2, 0, 1.0); X.Set(t - 2, 1, z[t - 1]); X.Set(t - 2, 2, z[t - 2]);
      y[t - 2] = z[t];
     }
   MQOIndependente(X, y, n, 3, b);
   double robo[];
   ArrayResize(robo, 3);
   robo[0] = a.Constante(); robo[1] = a.Phi(0); robo[2] = a.Phi(1);
   Identidade("Eum", "ARIMA(2,0,0) do robo contra MQO independente (Gauss)", MaxDifRel(robo, b, 3));

   //--- E2: recuperacao de coeficientes conhecidos (media e desvio em 500 series)
   double valores[] = {-0.6, -0.3, 0.0, 0.3, 0.6};
   int R = 500;
   int f = Abrir("hr_recuperacao.csv");
   FileWriteString(f, "tipo,verdadeiro,media,dp\n");
   for(int tipo = 0; tipo < 2; tipo++)
      for(int i = 0; i < ArraySize(valores); i++)
        {
         double s = 0, s2 = 0;
         int ok = 0;
         for(int r = 0; r < R; r++)
           {
            double zz[];
            if(tipo == 0) AR1(valores[i], N_ROBO - 1, zz);
            else ARMA11(0.0, valores[i], N_ROBO - 1, zz);
            CArima c;
            c.Definir(tipo == 0 ? 1 : 0, 0, tipo == 0 ? 0 : 1, true);
            if(!c.Ajustar(zz)) continue;
            double est = (tipo == 0) ? c.Phi(0) : c.Theta(0);
            s += est; s2 += est * est; ok++;
           }
         double media = s / ok, dp = MathSqrt(s2 / ok - media * media);
         FileWriteString(f, StringFormat("%d,%.2f,%.5f,%.5f\n", tipo, valores[i], media, dp));
         Log(StringFormat("  [E2] %s verdadeiro %.2f: media %.4f, desvio %.4f", tipo == 0 ? "AR(1) phi" : "MA(1) theta",
                          valores[i], media, dp));
        }
   FileClose(f);
   Valor("HrR", R, 0);
  }

//+------------------------------------------------------------------+
//| F. GARCH(1,1) (Garch.mqh)                                        |
//+------------------------------------------------------------------+
//--- log L do GARCH(1,1) escrita aqui: sigma2(0) = media de e^2, soma a partir de t = 1
double LogLGarchIndependente(const double &e[], const double omega, const double alfa, const double beta, double &ultima_var)
  {
   int n = ArraySize(e);
   double v0 = 0;
   for(int i = 0; i < n; i++) v0 += e[i] * e[i];
   v0 /= n;
   double s2 = v0, ll = 0;
   for(int t = 1; t < n; t++)
     {
      s2 = omega + alfa * e[t - 1] * e[t - 1] + beta * s2;
      ll += -0.5 * (MathLog(2 * M_PI) + MathLog(s2) + e[t] * e[t] / s2);
     }
   ultima_var = s2;
   return(ll);
  }

void TestesGarch(const double &residuos[])
  {
   Log("--- F. GARCH(1,1)");
   CGarch g;
   g.Definir(1, 1);
   g.DefinirOtimizador(300);
   g.Ajustar(residuos);
   double om = g.Omega(), al = g.Alfa(0), be = g.Beta(0), ult;
   double ll = LogLGarchIndependente(residuos, om, al, be, ult);
   Identidade("Fum", "log L do GARCH(1,1) refeita pela recursao sigma2 = w + a e^2 + b sigma2", MathAbs(g.LogVerossimilhanca() - ll) / MathAbs(ll));
   int n = ArraySize(residuos);
   double prox = MathSqrt(om + al * residuos[n - 1] * residuos[n - 1] + be * ult);
   Identidade("Fdois", "Previsao de um passo sqrt(w + a e(N)^2 + b sigma2(N))", MathAbs(g.VolatilidadeProximoPeriodo() - prox) / prox);
   Identidade("Ftres", "Variancia de longo prazo w / (1 - a - b)", MathAbs(g.VarianciaLongoPrazo() - om / (1 - al - be)) / (om / (1 - al - be)));
   Log(StringFormat("  estimado: omega=%.4e alfa=%.6f beta=%.6f logL=%.6f", om, al, be, g.LogVerossimilhanca()));
   Valor("GOmega", om * 1e5, 3); Valor("GAlfa", al, 4); Valor("GBeta", be, 4); Valor("GLogL", g.LogVerossimilhanca(), 3);

   //--- F2: o ponto do otimizador e o maximo? Grade 41 x 41 em alfa e beta (omega fixo) e
   //--- perturbacoes de cada parametro: nenhum vizinho viavel pode ter log L maior
   int f = Abrir("garch_grade.csv");
   FileWriteString(f, "alfa,beta,dl\n");
   int melhores = 0, viaveis = 0;
   double maior_ganho = -DBL_MAX;
   for(int i = 0; i <= 40; i++)
     {
      for(int j = 0; j <= 40; j++)
        {
         double a2 = al + (i - 20) * 0.005, b2 = be + (j - 20) * 0.005;
         double dl = -60;
         if(a2 >= 0 && b2 >= 0 && a2 + b2 < 0.9999)
           {
            double u;
            dl = LogLGarchIndependente(residuos, om, a2, b2, u) - ll;
            viaveis++;
            if(dl > 1e-6) melhores++;
            if(!(i == 20 && j == 20)) maior_ganho = MathMax(maior_ganho, dl);
            dl = MathMax(dl, -60);
           }
         FileWriteString(f, StringFormat("%.5f,%.5f,%.5f\n", a2, b2, dl));
        }
      FileWriteString(f, "\n");
     }
   FileClose(f);
   Log(StringFormat("  [F2] grade: %d pontos viaveis, %d com log L maior que o estimado; maior diferenca %.3e", viaveis, melhores, maior_ganho));
   Valor("GradeViaveis", viaveis, 0); Valor("GradeMelhores", melhores, 0); ValorCientifico("GradeGanho", maior_ganho);

   f = Abrir("garch_perturbacao.csv");
   FileWriteString(f, "parametro,passo,dl\n");
   string nomes[] = {"omega", "alfa", "beta"};
   double pior = -DBL_MAX;
   for(int k = 0; k < 3; k++)
      for(int s = -1; s <= 1; s += 2)
        {
         double o2 = om, a2 = al, b2 = be, u;
         if(k == 0) o2 = om * (1 + 0.01 * s);
         if(k == 1) a2 = al + 0.001 * s;
         if(k == 2) b2 = be + 0.001 * s;
         double dl = LogLGarchIndependente(residuos, o2, a2, b2, u) - ll;
         pior = MathMax(pior, dl);
         FileWriteString(f, StringFormat("%s,%d,%.6e\n", nomes[k], s, dl));
         Log(StringFormat("  [F2] %s %s: delta log L = %.3e", nomes[k], s > 0 ? "+" : "-", dl));
        }
   FileClose(f);
   ValorCientifico("PerturbMaior", pior);

   //--- F3: recuperacao de parametros conhecidos, com 240 e 1000 observacoes
   double w0 = 1.0e-5, a0 = 0.09, b0 = 0.89;
   int R = 300;
   int tam[] = {240, 1000};
   for(int c = 0; c < 2; c++)
     {
      int nn = tam[c], ok = 0, no_limite = 0;
      f = Abrir("garch_mc_" + IntegerToString(nn) + ".csv");
      FileWriteString(f, "n,omega,alfa,beta,persist\n");
      double sa = 0, sa2 = 0, sb = 0, sb2 = 0, sw = 0;
      uint t0 = GetTickCount();
      for(int r = 0; r < R; r++)
        {
         double e[], s2 = w0 / (1 - a0 - b0), eprev = 0;
         ArrayResize(e, nn);
         for(int t = -500; t < nn; t++)
           {
            s2 = w0 + a0 * eprev * eprev + b0 * s2;
            double x = MathSqrt(s2) * Randn();
            if(t >= 0) e[t] = x;
            eprev = x;
           }
         CGarch h;
         h.Definir(1, 1);
         h.DefinirOtimizador(300);
         if(!h.Ajustar(e)) continue;
         ok++;
         sa += h.Alfa(0); sa2 += h.Alfa(0) * h.Alfa(0);
         sb += h.Beta(0); sb2 += h.Beta(0) * h.Beta(0);
         sw += h.Omega();
         if(h.Persistencia() >= 0.9998) no_limite++;
         FileWriteString(f, StringFormat("%d,%.6e,%.6f,%.6f,%.6f\n", nn, h.Omega(), h.Alfa(0), h.Beta(0), h.Persistencia()));
        }
      double ma = sa / ok, mb = sb / ok;
      Log(StringFormat("  [F3] n=%d: %d ajustes (%.0f s); alfa %.4f (dp %.4f), beta %.4f (dp %.4f), omega medio %.3e; no limite %.1f%%",
                       nn, ok, (GetTickCount() - t0) / 1000.0, ma, MathSqrt(sa2 / ok - ma * ma), mb, MathSqrt(sb2 / ok - mb * mb),
                       sw / ok, TaxaPercentual(no_limite, ok)));
      string s = IntegerToString(nn);
      StringReplace(s, "1000", "Mil");
      StringReplace(s, "240", "Curto");
      Valor("Mc" + s + "R", ok, 0);
      Valor("Mc" + s + "Alfa", ma, 3); Valor("Mc" + s + "AlfaDp", MathSqrt(sa2 / ok - ma * ma), 3);
      Valor("Mc" + s + "Beta", mb, 3); Valor("Mc" + s + "BetaDp", MathSqrt(sb2 / ok - mb * mb), 3);
      Valor("Mc" + s + "Limite", TaxaPercentual(no_limite, ok), 1);
      FileClose(f);
     }
  }

//+------------------------------------------------------------------+
//| G. Previsao no nivel e percentil                                 |
//+------------------------------------------------------------------+
void TestesPrevisao(const double &log_preco[])
  {
   Log("--- G. Previsao e percentil");
   int n = ArraySize(log_preco);
   CArima a;
   a.Definir(1, 1, 1, true);
   a.Ajustar(log_preco);
   Identidade("Gum", "Previsao no nivel com d = 1: y(N) + z previsto",
              MathAbs(a.PreverNivel() - (log_preco[n - 1] + a.PreverDiferenciado())));
   CArima b;
   b.Definir(1, 2, 0, true);
   b.Ajustar(log_preco);
   Identidade("Gdois", "Previsao no nivel com d = 2: 2y(N) - y(N-1) + z previsto",
              MathAbs(b.PreverNivel() - (2 * log_preco[n - 1] - log_preco[n - 2] + b.PreverDiferenciado())));
   //--- percentil com interpolacao linear: em 1..10, o percentil 70 e 1 + 0,7 x 9 = 7,3
   double x[] = {7, 3, 10, 1, 5, 2, 9, 4, 8, 6};
   Identidade("Gtres", "Percentil 70 de 1..10 por interpolacao linear (7,3)", MathAbs(Percentil(x, 70.0) - 7.3));
  }

void OnStart()
  {
   FolderCreate("AlgoLab_testes");
   g_resumo  = Abrir("resumo.txt");
   g_valores = Abrir("valores.tex");
   g_ident   = Abrir("identidades.csv");
   FileWriteString(g_ident, "ordem;id;descricao;diferenca;log10\n");
   MathSrand(SEMENTE);
   uint t0 = GetTickCount();
   Log("================ TESTES DAS FORMULAS ================");

   double log_preco[], z[];
   if(!CarregarJanela(log_preco))
     {
      Log("ERRO: sem dados de " + SIMBOLO);
      return;
     }
   Diferenca(log_preco, z);
   //--- residuos reais: ARIMA(1,1,1) da validacao numerica
   CArima a;
   a.Definir(1, 1, 1, true);
   a.Ajustar(log_preco);
   double residuos[];
   a.ObterResiduos(residuos);

   TestesMQO(z);
   TestesADF(log_preco);
   TestesLjungBox(residuos);
   TestesAIC(log_preco);
   TestesHR(z);
   TestesGarch(residuos);
   TestesPrevisao(log_preco);

   Valor("NumIdent", g_num_ident, 0);
   Log(StringFormat("Tempo total: %.0f s", (GetTickCount() - t0) / 1000.0));
   Log("================ FIM ================");
   FileClose(g_ident);
   FileClose(g_valores);
   FileClose(g_resumo);
  }
