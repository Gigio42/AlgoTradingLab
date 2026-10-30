//+------------------------------------------------------------------+
//| MetodosIlustrados.mq5 - dados dos graficos que explicam os       |
//| metodos do robo (30/10/2026): MQO, Hannan-Rissanen,              |
//| verossimilhanca e otimizacao do GARCH, Ljung-Box, ADF e AIC.     |
//|                                                                  |
//| Usa as funcoes do proprio robo sobre a mesma janela da validacao |
//| numerica (PETR4_OFICIAL, 500 pregoes ate 18/09/2026), para que   |
//| o resumo possa ser conferido contra                              |
//| dados/verificacao/validacao_numerica_2026-10-05.txt.             |
//| Para rodar: ferramentas/scripts/metodos_ilustrados.sh.           |
//+------------------------------------------------------------------+
#include "..\Experts\AlgoTradingLab\robos\Include\SelecaoModelo.mqh"
#include "..\Experts\AlgoTradingLab\robos\Include\Garch.mqh"
#include <Math\Stat\ChiSquare.mqh>

#define PASTA        "AlgoLab_metodos\\"
#define SIMBOLO      "PETR4_OFICIAL"
#define FIM_JANELA   D'2026.09.18'
#define TAMANHO      500

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

//--- \vNome = numero para o texto (virgula decimal); \pNome = numero para coordenada
void Valor(const string nome, const double v, const int digitos)
  {
   string s = DoubleToString(v, digitos);
   string texto = s;
   StringReplace(texto, ".", "{,}");
   FileWriteString(g_valores, StringFormat("\\def\\v%s{%s}\n\\def\\p%s{%s}\n", nome, texto, nome, s));
  }

void Texto(const string nome, const string s)
  {
   FileWriteString(g_valores, StringFormat("\\def\\v%s{%s}\n", nome, s));
  }

string Data(const datetime t)
  {
   string s = TimeToString(t, TIME_DATE);
   StringReplace(s, ".", "-");
   return(s);
  }

string DataBR(const datetime t)
  {
   MqlDateTime d;
   TimeToStruct(t, d);
   return(StringFormat("%02d/%02d/%04d", d.day, d.mon, d.year));
  }

string Num(const double v, const int digitos = 8)
  {
   return(DoubleToString(v, digitos));
  }

//--- Ajuste de y = a + b x por MQO (a funcao do robo)
bool RetaMQO(const double &x[], const double &y[], double &a, double &b, double &sqr)
  {
   int n = ArraySize(x);
   CMatrixDouble X(n, 2);
   for(int i = 0; i < n; i++)
     {
      X.Set(i, 0, 1.0);
      X.Set(i, 1, x[i]);
     }
   double coef[], ep[];
   if(!MQO(X, y, n, 2, coef, ep, sqr, false))
      return(false);
   a = coef[0];
   b = coef[1];
   return(true);
  }

//--- Registra cada iteracao do MinBLEIC
class CRegistroCaminho : public CNDimensional_Rep
  {
public:
   double            omega_rel[];
   double            alfa[];
   double            beta[];
   double            menos_logl[];
   void              Guardar(const double o, const double a, const double b, const double f)
     {
      int k = ArraySize(alfa);
      ArrayResize(omega_rel, k + 1);
      ArrayResize(alfa, k + 1);
      ArrayResize(beta, k + 1);
      ArrayResize(menos_logl, k + 1);
      omega_rel[k] = o;
      alfa[k] = a;
      beta[k] = b;
      menos_logl[k] = f;
     }
   virtual void      Rep(CRowDouble &arg, double func, CObject &obj) { Guardar(arg[0], arg[1], arg[2], func); }
   virtual void      Rep(double &arg[], double func, CObject &obj)   { Guardar(arg[0], arg[1], arg[2], func); }
  };

//--- Conta as avaliacoes da funcao objetivo (inclui as do gradiente numerico)
class CObjetivoContado : public CObjetivoGarch
  {
public:
   int               avaliacoes;
                     CObjetivoContado(void) : avaliacoes(0) {}
   virtual void      Func(CRowDouble &x, double &func, CObject &obj)
     {
      avaliacoes++;
      CObjetivoGarch::Func(x, func, obj);
     }
  };

void OnStart()
  {
   g_resumo  = Abrir("resumo.txt");
   g_valores = Abrir("valores.tex");
   Log("================ METODOS ILUSTRADOS ================");

   //=================================================================
   // Janela
   //=================================================================
   double fechamento[];
   datetime tempo[];
   int n = CopyClose(SIMBOLO, PERIOD_D1, FIM_JANELA, TAMANHO, fechamento);
   int nt = CopyTime(SIMBOLO, PERIOD_D1, FIM_JANELA, TAMANHO, tempo);
   if(n != TAMANHO || nt != TAMANHO)
     {
      Log(StringFormat("ERRO: copiados %d precos e %d datas", n, nt));
      FileClose(g_resumo);
      FileClose(g_valores);
      return;
     }
   Log(StringFormat("Janela: %s a %s, %d pregoes (%s)", Data(tempo[0]), Data(tempo[n - 1]), n, SIMBOLO));
   Texto("Simbolo", "PETR4");
   Texto("Inicio", DataBR(tempo[0]));
   Texto("Fim", DataBR(tempo[n - 1]));
   Valor("N", n, 0);

   double lp[];
   ArrayResize(lp, n);
   for(int i = 0; i < n; i++)
      lp[i] = MathLog(fechamento[i]);

   //--- r[i] = log-retorno do pregao tempo[i+1]
   int nr = n - 1;
   double r[];
   ArrayResize(r, nr);
   for(int i = 0; i < nr; i++)
      r[i] = lp[i + 1] - lp[i];

   //=================================================================
   // 1) ADF: o nivel do log-preco e o log-retorno
   //=================================================================
   Log("");
   Log("--- ADF ---");
   ResultadoADF adf_nivel, adf_retorno;
   TesteADF(lp, ADF_CONSTANTE, -1, adf_nivel);
   TesteADF(r, ADF_CONSTANTE, -1, adf_retorno);
   Log(StringFormat("  log-preco : ADF=%.4f VC5=%.4f lags=%d n=%d estacionaria=%s",
                    adf_nivel.estatistica, adf_nivel.valor_critico_5, adf_nivel.defasagens,
                    adf_nivel.observacoes, adf_nivel.estacionaria ? "SIM" : "nao"));
   Log(StringFormat("  log-retorno: ADF=%.4f VC5=%.4f lags=%d n=%d estacionaria=%s",
                    adf_retorno.estatistica, adf_retorno.valor_critico_5, adf_retorno.defasagens,
                    adf_retorno.observacoes, adf_retorno.estacionaria ? "SIM" : "nao"));
   Valor("ADFnivel", adf_nivel.estatistica, 2);
   Valor("ADFret", adf_retorno.estatistica, 2);
   Valor("ADFvcNivel", adf_nivel.valor_critico_5, 2);
   Valor("ADFvcRet", adf_retorno.valor_critico_5, 2);
   Valor("ADFlagsNivel", adf_nivel.defasagens, 0);
   Valor("ADFlagsRet", adf_retorno.defasagens, 0);

   //--- Series no tempo
   int h = Abrir("adf_series.csv");
   FileWriteString(h, "data,preco,logpreco,retorno\n");
   for(int i = 0; i < n; i++)
      FileWriteString(h, StringFormat("%s,%s,%s,%s\n", Data(tempo[i]), Num(fechamento[i], 2), Num(lp[i]),
                                      (i == 0) ? "nan" : Num(100.0 * r[i - 1])));
   FileClose(h);

   //--- Dispersao da regressao de Dickey-Fuller sem defasagens: dy(t) contra y(t-1)
   double xn[], yn[], xr[], yr[];
   ArrayResize(xn, n - 1);
   ArrayResize(yn, n - 1);
   for(int t = 1; t < n; t++)
     {
      xn[t - 1] = lp[t - 1];
      yn[t - 1] = 100.0 * (lp[t] - lp[t - 1]);
     }
   ArrayResize(xr, nr - 1);
   ArrayResize(yr, nr - 1);
   for(int t = 1; t < nr; t++)
     {
      xr[t - 1] = 100.0 * r[t - 1];
      yr[t - 1] = 100.0 * (r[t] - r[t - 1]);
     }
   double an, gn, sn, ar_, gr, sr;
   RetaMQO(xn, yn, an, gn, sn);
   RetaMQO(xr, yr, ar_, gr, sr);
   //--- gamma em unidades de y: no nivel, y esta em % e x em log, entao divide por 100
   Log(StringFormat("  Dickey-Fuller simples: gamma nivel=%.5f  gamma retorno=%.5f", gn / 100.0, gr));
   Valor("GamaNivel", gn / 100.0, 3);
   Valor("GamaRet", gr, 3);
   h = Abrir("adf_dispersao_nivel.csv");
   FileWriteString(h, "x,y,ajuste\n");
   for(int i = 0; i < ArraySize(xn); i++)
      FileWriteString(h, StringFormat("%s,%s,%s\n", Num(xn[i]), Num(yn[i]), Num(an + gn * xn[i])));
   FileClose(h);
   h = Abrir("adf_dispersao_retorno.csv");
   FileWriteString(h, "x,y,ajuste\n");
   for(int i = 0; i < ArraySize(xr); i++)
      FileWriteString(h, StringFormat("%s,%s,%s\n", Num(xr[i]), Num(yr[i]), Num(ar_ + gr * xr[i])));
   FileClose(h);

   //=================================================================
   // 2) AIC: grade de p e q com a amostra comum
   //=================================================================
   Log("");
   Log("--- AIC ---");
   string relatorio_d;
   int d = DeterminarOrdemD(lp, 2, ADF_CONSTANTE, relatorio_d);
   Log("  d escolhido pelo ADF: " + IntegerToString(d));
   Valor("D", d, 0);
   double aic[5][5], logl[5][5];
   int    k_par[5][5];
   double melhor = DBL_MAX;
   int mp = -1, mq = -1;
   for(int p = 0; p <= 4; p++)
      for(int q = 0; q <= 4; q++)
        {
         aic[p][q] = DBL_MAX;
         logl[p][q] = 0.0;
         k_par[p][q] = 0;
         CArima c;
         c.Definir(p, d, q, true);
         c.DefinirAquecimentoMinimo(4);
         if(!c.Ajustar(lp))
            continue;
         aic[p][q] = c.AIC();
         logl[p][q] = c.LogVerossimilhanca();
         k_par[p][q] = c.NumParametros();
         if(aic[p][q] < melhor)
           {
            melhor = aic[p][q];
            mp = p;
            mq = q;
           }
        }
   ResultadoSelecao sel;
   string tabela;
   BuscarMelhorPQ(lp, d, 4, 4, true, sel, tabela);
   Log(tabela);
   Log(StringFormat("  melhor (grade deste script): (%d,%d) AIC=%.3f | BuscarMelhorPQ: (%d,%d)", mp, mq, melhor, sel.p, sel.q));
   Valor("MelhorP", mp, 0);
   Valor("MelhorQ", mq, 0);
   Valor("MelhorAIC", melhor, 1);
   Valor("MelhorLogL", logl[mp][mq], 1);
   Valor("MelhorK", k_par[mp][mq], 0);
   Valor("MaiorAIC", aic[4][4], 1);
   Valor("MaiorLogL", logl[4][4], 1);
   Valor("MaiorK", k_par[4][4], 0);
   h = Abrir("aic_grade.csv");
   FileWriteString(h, "p,q,aic,delta,logl,k\n");
   for(int p = 0; p <= 4; p++)
      for(int q = 0; q <= 4; q++)
         FileWriteString(h, StringFormat("%d,%d,%s,%s,%s,%d\n", p, q,
                                         (aic[p][q] == DBL_MAX) ? "nan" : Num(aic[p][q], 3),
                                         (aic[p][q] == DBL_MAX) ? "nan" : Num(aic[p][q] - melhor, 3),
                                         Num(logl[p][q], 3), k_par[p][q]));
   FileClose(h);

   //=================================================================
   // 3) MQO: AR(1) no log-retorno, o caminho q = 0 do CArima
   //=================================================================
   Log("");
   Log("--- MQO (AR(1) no log-retorno, em %) ---");
   int nm = nr - 1;
   double xm[], ym[];
   ArrayResize(xm, nm);
   ArrayResize(ym, nm);
   for(int t = 1; t < nr; t++)
     {
      xm[t - 1] = 100.0 * r[t - 1];
      ym[t - 1] = 100.0 * r[t];
     }
   double cm, phim, sqrm;
   RetaMQO(xm, ym, cm, phim, sqrm);
   CArima ar1;
   ar1.Definir(1, 1, 0, true);
   ar1.Ajustar(lp);
   Log(StringFormat("  MQO direto: c=%.6f%% phi=%.6f SQR=%.4f n=%d | CArima(1,1,0): c=%.6f%% phi=%.6f",
                    cm, phim, sqrm, nm, 100.0 * ar1.Constante(), ar1.Phi(0)));
   Valor("MqoC", cm, 4);
   Valor("MqoPhi", phim, 4);
   Valor("MqoSQR", sqrm, 1);
   Valor("MqoN", nm, 0);
   h = Abrir("mqo_dispersao.csv");
   FileWriteString(h, "x,y,ajuste\n");
   for(int i = 0; i < nm; i++)
      FileWriteString(h, StringFormat("%s,%s,%s\n", Num(xm[i]), Num(ym[i]), Num(cm + phim * xm[i])));
   FileClose(h);
   //--- Soma dos quadrados dos residuos para cada phi (com a melhor constante para aquele phi)
   double mx = Media(xm), my = Media(ym);
   h = Abrir("mqo_perfil.csv");
   FileWriteString(h, "phi,sqr\n");
   for(int k = 0; k <= 200; k++)
     {
      double phi = -0.5 + 0.005 * k;
      double c = my - phi * mx, s = 0.0;
      for(int i = 0; i < nm; i++)
        {
         double e = ym[i] - c - phi * xm[i];
         s += e * e;
        }
      FileWriteString(h, StringFormat("%s,%s\n", Num(phi, 4), Num(s, 4)));
     }
   FileClose(h);

   //=================================================================
   // 4) Hannan-Rissanen: os dois estagios do CArima, passo a passo
   //=================================================================
   Log("");
   Log("--- Hannan-Rissanen, ARIMA(1,1,1) ---");
   int nz = nr;   // z = serie diferenciada = log-retorno
   int m = (int)MathFloor(MathPow(MathLog((double)nz), 2.0));
   m = MathMax(m, 1 + 1 + 1);
   m = MathMin(m, nz / 5);
   //--- Estagio 1: AR(m) com constante
   int obs1 = nz - m;
   CMatrixDouble X1(obs1, m + 1);
   double y1[];
   ArrayResize(y1, obs1);
   for(int t = m, linha = 0; t < nz; t++, linha++)
     {
      y1[linha] = r[t];
      X1.Set(linha, 0, 1.0);
      for(int i = 1; i <= m; i++)
         X1.Set(linha, i, r[t - i]);
     }
   double c1[], ep1[], sqr1;
   MQO(X1, y1, obs1, m + 1, c1, ep1, sqr1, false);
   double e1[];
   ArrayResize(e1, nz);
   ArrayInitialize(e1, 0.0);
   for(int t = m; t < nz; t++)
     {
      double ajuste = c1[0];
      for(int i = 1; i <= m; i++)
         ajuste += c1[i] * r[t - i];
      e1[t] = r[t] - ajuste;
     }
   //--- Estagio 2: z(t) contra 1, z(t-1) e e1(t-1)
   int primeiro = MathMax(m + 1, 1);
   int obs2 = nz - primeiro;
   CMatrixDouble X2(obs2, 3);
   double y2[];
   ArrayResize(y2, obs2);
   for(int t = primeiro, linha = 0; t < nz; t++, linha++)
     {
      y2[linha] = r[t];
      X2.Set(linha, 0, 1.0);
      X2.Set(linha, 1, r[t - 1]);
      X2.Set(linha, 2, e1[t - 1]);
     }
   double c2[], ep2[], sqr2;
   MQO(X2, y2, obs2, 3, c2, ep2, sqr2, false);
   CArima a111;
   a111.Definir(1, 1, 1, true);
   a111.Ajustar(lp);
   Log(StringFormat("  m=%d obs1=%d obs2=%d | passo a passo: c=%.8f phi=%.6f theta=%.6f",
                    m, obs1, obs2, c2[0], c2[1], c2[2]));
   Log("  CArima: " + a111.Descricao());
   Valor("HrM", m, 0);
   Valor("HrObsUm", obs1, 0);
   Valor("HrObsDois", obs2, 0);
   Valor("HrC", 100.0 * c2[0], 4);
   Valor("HrPhi", c2[1], 4);
   Valor("HrTheta", c2[2], 4);
   h = Abrir("hr_ar_longo.csv");
   FileWriteString(h, "defasagem,coeficiente\n");
   for(int i = 1; i <= m; i++)
      FileWriteString(h, StringFormat("%d,%s\n", i, Num(c1[i])));
   FileClose(h);

   double residuos[];
   a111.ObterResiduos(residuos);   // residuos[j] = residuo do log-retorno r[j+1]
   int nres = ArraySize(residuos);
   h = Abrir("hr_erros.csv");
   FileWriteString(h, "data,retorno,erro_estagio1,residuo_final\n");
   for(int t = nz - 60; t < nz; t++)
      FileWriteString(h, StringFormat("%s,%s,%s,%s\n", Data(tempo[t + 1]), Num(100.0 * r[t]),
                                      Num(100.0 * e1[t]), Num(100.0 * residuos[t - 1])));
   FileClose(h);
   Texto("HrIniErros", DataBR(tempo[nz - 60 + 1]));

   //=================================================================
   // 5) GARCH: verossimilhanca e otimizacao
   //=================================================================
   Log("");
   Log("--- GARCH(1,1) sobre os residuos do ARIMA(1,1,1) ---");
   CGarch g;
   g.Definir(1, 1);
   g.DefinirOtimizador(500);
   if(!g.Ajustar(residuos))
     {
      Log("  GARCH FALHOU: " + g.UltimoErro());
      FileClose(g_resumo);
      FileClose(g_valores);
      return;
     }
   Log("  " + g.Descricao());
   Log(StringFormat("  Vol prevista = %.6f", g.VolatilidadeProximoPeriodo()));

   CDadosGarch dados;
   ArrayResize(dados.erros_quadrado, nres);
   double soma = 0.0;
   for(int i = 0; i < nres; i++)
     {
      dados.erros_quadrado[i] = residuos[i] * residuos[i];
      soma += dados.erros_quadrado[i];
     }
   dados.tamanho = nres;
   dados.p = 1;
   dados.q = 1;
   dados.inicio = 1;
   dados.variancia_amostral = soma / (double)nres;
   dados.distribuicao = DISTRIBUICAO_NORMAL;
   double omega_rel = g.Omega() / dados.variancia_amostral;
   double logl_max = g.LogVerossimilhanca();
   Valor("GOmega", g.Omega() * 1.0e5, 3);   // em 10^-5
   Valor("GOmegaRel", omega_rel, 3);
   Valor("GAlfa", g.Alfa(0), 3);
   Valor("GBeta", g.Beta(0), 3);
   Valor("GPersist", g.Persistencia(), 3);
   Valor("GLogL", logl_max, 1);
   Valor("GVolPrev", 100.0 * g.VolatilidadeProximoPeriodo(), 2);
   Valor("GSigAm", 100.0 * MathSqrt(dados.variancia_amostral), 2);

   //--- Superficie: log-verossimilhanca (relativa ao maximo) com omega fixado no estimado,
   //--- cortada em -60 para o desenho; fora da restricao (viavel = 0) vai o proprio corte
   h = Abrir("gv_superficie.csv");
   FileWriteString(h, "alfa,beta,rel,viavel\n");
   for(int j = 0; j <= 80; j++)
     {
      double beta = 0.0125 * j;
      for(int i = 0; i <= 40; i++)
        {
         double alfa = 0.0125 * i;
         double par[3];
         par[0] = omega_rel;
         par[1] = alfa;
         par[2] = beta;
         double v = MenosLogVerossimilhancaGarch(dados, par);
         bool viavel = (v < 1.0e9);
         string rel = viavel ? Num(MathMax(-v - logl_max, -60.0), 4) : Num(-60.0, 4);
         FileWriteString(h, StringFormat("%s,%s,%s,%d\n", Num(alfa, 4), Num(beta, 4), rel, viavel ? 1 : 0));
        }
      FileWriteString(h, "\n");
     }
   FileClose(h);

   //--- O mesmo otimizador do CGarch::Ajustar, agora registrando cada iteracao
   double x[3] = { 0.05, 0.10, 0.85 };
   double li[3] = { 1.0e-8, 0.0, 0.0 };
   double ls[3] = { 10.0, 1.0, 1.0 };
   CMatrixDouble restricao(1, 4);
   restricao.Set(0, 0, 0.0);
   restricao.Set(0, 1, 1.0);
   restricao.Set(0, 2, 1.0);
   restricao.Set(0, 3, 0.9999);
   int tipo[1] = { -1 };
   CMinBLEICStateShell estado;
   CMinBLEICReportShell relatorio;
   CObjetivoContado objetivo;
   CRegistroCaminho caminho;
   CAlglib::MinBLEICCreateF(3, x, 1.0e-6, estado);
   CAlglib::MinBLEICSetBC(estado, li, ls);
   CAlglib::MinBLEICSetLC(estado, restricao, tipo, 1);
   CAlglib::MinBLEICSetInnerCond(estado, 0.0, 0.0, 1.0e-8);
   CAlglib::MinBLEICSetOuterCond(estado, 1.0e-8, 1.0e-8);
   CAlglib::MinBLEICSetMaxIts(estado, 500);
   CAlglib::MinBLEICSetXRep(estado, true);
   CAlglib::MinBLEICOptimize(estado, objetivo, caminho, true, dados);
   double xf[];
   CAlglib::MinBLEICResults(estado, xf, relatorio);
   int iteracoes = ArraySize(caminho.alfa);
   Log(StringFormat("  Otimizador registrado: %d iteracoes reportadas, %d avaliacoes, codigo %d",
                    iteracoes, objetivo.avaliacoes, relatorio.GetTerminationType()));
   Log(StringFormat("  final: omega_rel=%.6f alfa=%.6f beta=%.6f | CGarch: omega_rel=%.6f alfa=%.6f beta=%.6f",
                    xf[0], xf[1], xf[2], omega_rel, g.Alfa(0), g.Beta(0)));
   Valor("OtIter", iteracoes - 1, 0);
   Valor("OtAval", objetivo.avaliacoes, 0);
   Valor("OtIniAlfa", 0.10, 2);
   Valor("OtIniBeta", 0.85, 2);
   Valor("OtIniLogL", -caminho.menos_logl[0], 1);
   h = Abrir("ot_caminho.csv");
   FileWriteString(h, "iteracao,omega_rel,alfa,beta,logl\n");
   for(int k = 0; k < iteracoes; k++)
      FileWriteString(h, StringFormat("%d,%s,%s,%s,%s\n", k, Num(caminho.omega_rel[k]), Num(caminho.alfa[k]),
                                      Num(caminho.beta[k]), Num(-caminho.menos_logl[k], 4)));
   FileClose(h);

   //--- Volatilidade ajustada e o dia de maior residuo
   double sigma[];
   g.ObterSerieVolatilidade(sigma);   // sigma[i] = desvio do residuo i+1
   h = Abrir("gv_volatilidade.csv");
   FileWriteString(h, "data,residuo,sigma\n");
   int dia = 1;
   for(int j = 1; j < nres; j++)
     {
      FileWriteString(h, StringFormat("%s,%s,%s\n", Data(tempo[j + 2]), Num(100.0 * residuos[j]), Num(100.0 * sigma[j - 1])));
      if(MathAbs(residuos[j]) > MathAbs(residuos[dia]))
         dia = j;
     }
   FileClose(h);
   double eps = 100.0 * residuos[dia];
   double s_am = 100.0 * MathSqrt(dados.variancia_amostral);
   double s_t = 100.0 * sigma[dia - 1];
   double ld_am = -0.5 * (MathLog(2.0 * M_PI) + 2.0 * MathLog(s_am) + eps * eps / (s_am * s_am));
   double ld_t  = -0.5 * (MathLog(2.0 * M_PI) + 2.0 * MathLog(s_t)  + eps * eps / (s_t * s_t));
   Log(StringFormat("  Maior residuo: %s eps=%.3f%% sigma_amostral=%.3f%% sigma_garch=%.3f%% | log f: %.3f x %.3f",
                    Data(tempo[dia + 2]), eps, s_am, s_t, ld_am, ld_t));
   Texto("DiaMax", DataBR(tempo[dia + 2]));
   Valor("EpsMax", eps, 2);
   Valor("SigT", s_t, 2);
   Valor("DensAm", MathExp(ld_am), 4);
   Valor("DensT", MathExp(ld_t), 4);
   Valor("LogDensAm", ld_am, 2);
   Valor("LogDensT", ld_t, 2);
   h = Abrir("gv_densidade.csv");
   FileWriteString(h, "x,amostral,garch\n");
   for(int k = 0; k <= 400; k++)
     {
      double xx = -10.0 + 0.05 * k;
      double fa = MathExp(-0.5 * xx * xx / (s_am * s_am)) / (s_am * MathSqrt(2.0 * M_PI));
      double fg = MathExp(-0.5 * xx * xx / (s_t * s_t)) / (s_t * MathSqrt(2.0 * M_PI));
      FileWriteString(h, StringFormat("%s,%s,%s\n", Num(xx, 2), Num(fa), Num(fg)));
     }
   FileClose(h);

   //=================================================================
   // 6) Ljung-Box: residuos, quadrados e quadrados padronizados
   //=================================================================
   Log("");
   Log("--- Ljung-Box (10 defasagens, 2 parametros ARMA, como na validacao) ---");
   double z[], e2[], z2[];
   g.ObterResiduosPadronizados(z);
   ArrayResize(e2, nres);
   for(int i = 0; i < nres; i++)
      e2[i] = residuos[i] * residuos[i];
   ArrayResize(z2, ArraySize(z));
   for(int i = 0; i < ArraySize(z); i++)
      z2[i] = z[i] * z[i];
   ResultadoLjungBox lb_e, lb_e2, lb_z2;
   TesteLjungBox(residuos, 10, 2, lb_e);
   TesteLjungBox(e2, 10, 2, lb_e2);
   TesteLjungBox(z2, 10, 2, lb_z2);
   int erro = 0;
   double critico = MathQuantileChiSquare(0.95, 8.0, erro);
   Log(StringFormat("  residuos      : Q=%.3f gl=%d p=%.4f", lb_e.estatistica, lb_e.graus_liberdade, lb_e.pvalor));
   Log(StringFormat("  residuos^2    : Q=%.3f gl=%d p=%.4f", lb_e2.estatistica, lb_e2.graus_liberdade, lb_e2.pvalor));
   Log(StringFormat("  padronizados^2: Q=%.3f gl=%d p=%.4f", lb_z2.estatistica, lb_z2.graus_liberdade, lb_z2.pvalor));
   Log(StringFormat("  valor critico qui-quadrado(8) a 5%%: %.3f", critico));
   Valor("LbQe", lb_e.estatistica, 1);
   Valor("LbPe", lb_e.pvalor, 3);
   Valor("LbQeq", lb_e2.estatistica, 1);
   Valor("LbPeq", lb_e2.pvalor, 4);
   Valor("LbQzq", lb_z2.estatistica, 1);
   Valor("LbPzq", lb_z2.pvalor, 2);
   Valor("LbCrit", critico, 2);
   Valor("LbGl", lb_e.graus_liberdade, 0);
   Valor("LbBanda", 1.96 / MathSqrt((double)nres), 3);
   h = Abrir("lb_acf.csv");
   FileWriteString(h, "k,residuo,quadrado,padronizado_quadrado\n");
   for(int k = 1; k <= 20; k++)
      FileWriteString(h, StringFormat("%d,%s,%s,%s\n", k, Num(Autocorrelacao(residuos, k)),
                                      Num(Autocorrelacao(e2, k)), Num(Autocorrelacao(z2, k))));
   FileClose(h);
   //--- Parcela de cada defasagem em Q = n(n+2) soma r_k^2/(n-k), acumulada
   h = Abrir("lb_parcelas.csv");
   FileWriteString(h, "k,residuo,quadrado,padronizado_quadrado\n");
   double ac_e = 0.0, ac_e2 = 0.0, ac_z2 = 0.0;
   int ne = nres, nzq = ArraySize(z2);
   for(int k = 1; k <= 10; k++)
     {
      double re = Autocorrelacao(residuos, k), re2 = Autocorrelacao(e2, k), rz = Autocorrelacao(z2, k);
      ac_e  += (double)ne * (ne + 2) * re * re / (double)(ne - k);
      ac_e2 += (double)ne * (ne + 2) * re2 * re2 / (double)(ne - k);
      ac_z2 += (double)nzq * (nzq + 2) * rz * rz / (double)(nzq - k);
      FileWriteString(h, StringFormat("%d,%s,%s,%s\n", k, Num(ac_e, 4), Num(ac_e2, 4), Num(ac_z2, 4)));
     }
   FileClose(h);

   Log("");
   Log("================ FIM ================");
   FileClose(g_resumo);
   FileClose(g_valores);
  }
