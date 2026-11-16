//+------------------------------------------------------------------+
//| ModeloCompleto.mq5 - dados dos relatorios "o modelo inteiro" e   |
//| "o GARCH funcionando" (06/11/2026, ia/relatorios/).              |
//|                                                                  |
//| Refaz, com as funcoes do proprio robo, a decisao de dois pregoes |
//| do traco da refacao de 05/10/2026 (configuracao GS de C4:        |
//| janela 240, com constante, reselecao a cada 21 pregoes, GARCH    |
//| filtro no percentil 70): 19/02/2021 (liberado) e 22/02/2021      |
//| (vetado). Grava a janela inteira de cada dia (precos, retornos,  |
//| residuos, sigma do GARCH e as tres parcelas da variancia), a     |
//| grade de AIC e o ADF da ultima reselecao, e os numeros num       |
//| valores.tex. A conferencia contra o traco e feita pelo script    |
//| ferramentas/scripts/modelo_completo.sh.                          |
//+------------------------------------------------------------------+
#include "..\Experts\AlgoTradingLab\robos\Include\SelecaoModelo.mqh"
#include "..\Experts\AlgoTradingLab\robos\Include\Garch.mqh"
#include "..\Experts\AlgoTradingLab\robos\Include\Estrategia.mqh"

#define PASTA          "AlgoLab_modelo\\"
#define SIMBOLO        "PETR4_OFICIAL"
#define INICIO_TESTE   D'2019.07.01'   // primeiro pregao do traco (gerar_traco.sh, DE=)
#define JANELA         240             // Janela_Estimacao e Janela_Selecao da GS
#define ENTRE_SELECOES 21              // Barras_Entre_Reselecao
#define PERCENTIL      70.0            // Limiar_Percentil da GS
#define ITERACOES      300             // Iteracoes_GARCH

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
   StringReplace(texto, "-", "\\ensuremath{-}");
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

string Num(const double v, const int digitos = 8) { return(DoubleToString(v, digitos)); }

//--- 240 fechamentos ate o pregao anterior a 'dia', como o CopyClose(...,1,...) do EA
bool Janela(const datetime dia, double &fech[], datetime &tempo[])
  {
   int s = iBarShift(SIMBOLO, PERIOD_D1, dia, true);
   if(s < 0)
      return(false);
   int n = CopyClose(SIMBOLO, PERIOD_D1, s + 1, JANELA, fech);
   int nt = CopyTime(SIMBOLO, PERIOD_D1, s + 1, JANELA, tempo);
   return(n == JANELA && nt == JANELA);
  }

//--- Indice do pregao no teste (0 = INICIO_TESTE) e o pregao da ultima reselecao
datetime UltimaSelecao(const datetime dia, int &indice)
  {
   int s0 = iBarShift(SIMBOLO, PERIOD_D1, INICIO_TESTE, true);
   int s  = iBarShift(SIMBOLO, PERIOD_D1, dia, true);
   indice = s0 - s;
   int k = indice - (indice % ENTRE_SELECOES);
   return(iTime(SIMBOLO, PERIOD_D1, s0 - k));
  }

void Selecao(const datetime dia, const string rotulo, int &p, int &d, int &q)
  {
   int indice;
   datetime sel = UltimaSelecao(dia, indice);
   double fech[];
   datetime tempo[];
   if(!Janela(sel, fech, tempo))
     {
      Log("ERRO: janela da selecao");
      return;
     }
   double lp[];
   ArrayResize(lp, JANELA);
   for(int i = 0; i < JANELA; i++)
      lp[i] = MathLog(fech[i]);

   ResultadoSelecao r;
   string relatorio;
   SelecionarModelo(lp, 2, 4, 4, true, ADF_CONSTANTE, r, relatorio);
   p = r.p;
   d = r.d;
   q = r.q;
   Log(StringFormat("Selecao valida para %s: pregao %d do teste, ultima reselecao em %s (janela %s a %s)",
                    Data(dia), indice, Data(sel), Data(tempo[0]), Data(tempo[JANELA - 1])));
   Log(relatorio);
   Texto(rotulo + "Sel", DataBR(sel));
   Texto(rotulo + "SelIni", DataBR(tempo[0]));
   Texto(rotulo + "SelFim", DataBR(tempo[JANELA - 1]));
   Valor(rotulo + "P", p, 0);
   Valor(rotulo + "D", d, 0);
   Valor(rotulo + "Q", q, 0);

   //--- ADF do log-preco e do log-retorno (as duas etapas do DeterminarOrdemD)
   double ret[];
   ArrayResize(ret, JANELA - 1);
   for(int i = 0; i < JANELA - 1; i++)
      ret[i] = lp[i + 1] - lp[i];
   ResultadoADF a0, a1;
   TesteADF(lp, ADF_CONSTANTE, -1, a0);
   TesteADF(ret, ADF_CONSTANTE, -1, a1);
   Valor(rotulo + "ADFnivel", a0.estatistica, 2);
   Valor(rotulo + "ADFret", a1.estatistica, 2);
   Valor(rotulo + "ADFvc", a0.valor_critico_5, 2);

   //--- grade de AIC com a amostra comum, como o BuscarMelhorPQ
   int h = Abrir("aic_" + rotulo + ".csv");
   FileWriteString(h, "p,q,aic,delta\n");
   double aic[5][5];
   double melhor = DBL_MAX;
   for(int pp = 0; pp <= 4; pp++)
      for(int qq = 0; qq <= 4; qq++)
        {
         aic[pp][qq] = DBL_MAX;
         CArima c;
         c.Definir(pp, d, qq, true);
         c.DefinirAquecimentoMinimo(4);
         if(c.Ajustar(lp))
            aic[pp][qq] = c.AIC();
         if(aic[pp][qq] < melhor)
            melhor = aic[pp][qq];
        }
   for(int pp = 0; pp <= 4; pp++)
      for(int qq = 0; qq <= 4; qq++)
         FileWriteString(h, StringFormat("%d,%d,%s,%s\n", pp, qq,
                                         (aic[pp][qq] == DBL_MAX) ? "nan" : Num(aic[pp][qq], 3),
                                         (aic[pp][qq] == DBL_MAX) ? "nan" : Num(aic[pp][qq] - melhor, 3)));
   FileClose(h);
  }

void Pregao(const datetime dia, const string rotulo)
  {
   Log("");
   Log("================ " + Data(dia) + " (" + rotulo + ") ================");
   int p = 0, d = 1, q = 0;
   Selecao(dia, rotulo, p, d, q);

   double fech[];
   datetime tempo[];
   if(!Janela(dia, fech, tempo))
     {
      Log("ERRO: janela de estimacao");
      return;
     }
   Texto(rotulo + "Dia", DataBR(dia));
   Texto(rotulo + "Ini", DataBR(tempo[0]));
   Texto(rotulo + "Fim", DataBR(tempo[JANELA - 1]));
   Valor(rotulo + "Fech", fech[JANELA - 1], 2);

   double lp[];
   ArrayResize(lp, JANELA);
   for(int i = 0; i < JANELA; i++)
      lp[i] = MathLog(fech[i]);

   //--- ARIMA: o mesmo caminho do OnTick
   CArima arima;
   arima.Definir(p, d, q, true);
   if(!arima.Ajustar(lp))
     {
      Log("ERRO ARIMA: " + arima.UltimoErro());
      return;
     }
   double previsao = (arima.D() == 1) ? arima.PreverDiferenciado()
                                      : arima.PreverNivel() - lp[JANELA - 1];
   double res[];
   arima.ObterResiduos(res);
   int nres = ArraySize(res);

   //--- GARCH(1,1) nos residuos, limiar no percentil
   CGarch garch;
   garch.Definir(1, 1);
   garch.DefinirOtimizador(ITERACOES);
   if(!garch.Ajustar(res))
     {
      Log("ERRO GARCH: " + garch.UltimoErro());
      return;
     }
   double vol = garch.VolatilidadeProximoPeriodo();
   double sig[];
   garch.ObterSerieVolatilidade(sig);
   double limiar = Percentil(sig, PERCENTIL);
   int nsig = ArraySize(sig);   // = nres - 1: comeca no 2o residuo

   DecisaoOperacao dec;
   DecidirOperacao(previsao, vol, true, FILTRO_VOLATILIDADE, limiar, 0.01, 100, 0.25, 2.0, 0.0, dec);

   double om = garch.Omega(), al = garch.Alfa(0), be = garch.Beta(0);
   Log(StringFormat("ARIMA(%d,%d,%d): const=%.6f phi1=%.6f phi2=%.6f phi3=%.6f phi4=%.6f theta1=%.6f",
                    p, d, q, arima.Constante(), arima.Phi(0), arima.Phi(1), arima.Phi(2), arima.Phi(3), arima.Theta(0)));
   Log(StringFormat("previsao=%.8f  vol=%.8f  limiar=%.8f  sinal=%d  vetada=%d",
                    previsao, vol, limiar, dec.sinal, dec.vetada_pelo_garch ? 1 : 0));
   Log(StringFormat("GARCH: omega=%.6e alfa=%.6f beta=%.6f persist=%.6f  residuos=%d  sigmas=%d",
                    om, al, be, garch.Persistencia(), nres, nsig));

   //--- Refaz a recursao fora do CGarch e confere: sigma2(t) = omega + alfa e2(t-1) + beta sigma2(t-1)
   //--- sig[i] e o sigma do residuo res[i+1]
   double max_dif = 0.0;
   for(int i = 1; i < nsig; i++)
     {
      double s2 = om + al * res[i] * res[i] + be * sig[i - 1] * sig[i - 1];
      max_dif = MathMax(max_dif, MathAbs(MathSqrt(s2) - sig[i]));
     }
   double s2n = om + al * res[nres - 1] * res[nres - 1] + be * sig[nsig - 1] * sig[nsig - 1];
   Log(StringFormat("Conferencia da recursao: maior diferenca de sigma = %.3e; previsao refeita = %.8f",
                    max_dif, MathSqrt(s2n)));

   //--- Arquivo da janela: uma linha por pregao, em %, e variancias em %^2
   int h = Abrir("janela_" + rotulo + ".csv");
   FileWriteString(h, "data,fechamento,retorno,ajustado,residuo,sigma,v_omega,v_alfa,v_beta,limiar\n");
   int off_res = JANELA - nres;        // res[j] e o pregao tempo[off_res + j]
   for(int i = 0; i < JANELA; i++)
     {
      string ret = (i == 0) ? "nan" : Num(100.0 * (lp[i] - lp[i - 1]), 6);
      int j = i - off_res;
      string aj = "nan", rr = "nan", ss = "nan", vo = "nan", va = "nan", vb = "nan";
      if(j >= 0 && i > 0)
        {
         rr = Num(100.0 * res[j], 6);
         aj = Num(100.0 * (lp[i] - lp[i - 1] - res[j]), 6);
        }
      if(j >= 1)
        {
         ss = Num(100.0 * sig[j - 1], 6);
         if(j >= 2)
           {
            vo = Num(1.0e4 * om, 6);
            va = Num(1.0e4 * al * res[j - 1] * res[j - 1], 6);
            vb = Num(1.0e4 * be * sig[j - 2] * sig[j - 2], 6);
           }
        }
      FileWriteString(h, StringFormat("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n", Data(tempo[i]), Num(fech[i], 2),
                                      ret, aj, rr, ss, vo, va, vb, Num(100.0 * limiar, 6)));
     }
   //--- a linha do proprio dia: so a previsao e as parcelas dela
   FileWriteString(h, StringFormat("%s,nan,nan,%s,nan,%s,%s,%s,%s,%s\n", Data(dia), Num(100.0 * previsao, 6),
                                   Num(100.0 * vol, 6), Num(1.0e4 * om, 6),
                                   Num(1.0e4 * al * res[nres - 1] * res[nres - 1], 6),
                                   Num(1.0e4 * be * sig[nsig - 1] * sig[nsig - 1], 6), Num(100.0 * limiar, 6)));
   FileClose(h);

   Valor(rotulo + "Const", 100.0 * arima.Constante(), 3);
   Valor(rotulo + "PhiUm", arima.Phi(0), 3);
   Valor(rotulo + "PhiDois", arima.Phi(1), 3);
   Valor(rotulo + "PhiTres", arima.Phi(2), 3);
   Valor(rotulo + "Prev", 100.0 * previsao, 2);
   Valor(rotulo + "Vol", 100.0 * vol, 2);
   Valor(rotulo + "Lim", 100.0 * limiar, 2);
   Valor(rotulo + "Alfa", al, 3);
   Valor(rotulo + "Beta", be, 3);
   Valor(rotulo + "Omega", 1.0e4 * om, 4);
   Valor(rotulo + "Persist", garch.Persistencia(), 3);
   Valor(rotulo + "VolLP", 100.0 * MathSqrt(garch.VarianciaLongoPrazo()), 2);
   Valor(rotulo + "UltRes", 100.0 * res[nres - 1], 2);
   Valor(rotulo + "UltSig", 100.0 * sig[nsig - 1], 2);
   Valor(rotulo + "POmega", 1.0e4 * om, 2);
   Valor(rotulo + "PAlfa", 1.0e4 * al * res[nres - 1] * res[nres - 1], 2);
   Valor(rotulo + "PBeta", 1.0e4 * be * sig[nsig - 1] * sig[nsig - 1], 2);
   Valor(rotulo + "VarPrev", 1.0e4 * vol * vol, 2);
   Valor(rotulo + "Sinal", dec.sinal, 0);
   Valor(rotulo + "Vetada", dec.vetada_pelo_garch ? 1 : 0, 0);
   Valor(rotulo + "NRes", nres, 0);
  }

void OnStart()
  {
   FolderCreate(PASTA);
   g_resumo  = Abrir("resumo.txt");
   g_valores = Abrir("valores.tex");
   Log("================ MODELO COMPLETO ================");
   Pregao(D'2021.02.19', "Sex");
   Pregao(D'2021.02.22', "Seg");
   Log("FIM");
   FileClose(g_resumo);
   FileClose(g_valores);
  }
