//+------------------------------------------------------------------+
//|                                            Import_B3_Custom.mq5  |
//|  Importa os CSVs de B3_Historical como SIMBOLOS PERSONALIZADOS   |
//+------------------------------------------------------------------+
//|                                                                  |
//|  POR QUE ESTA VERSAO EXISTE                                      |
//|                                                                  |
//|  O Import_B3_Historical.mq5 original criava o simbolo com o      |
//|  MESMO NOME do papel da corretora ("PETR4"). O MetaTrader        |
//|  recusa isso, porque PETR4 ja existe vindo da BOVESPA — e o      |
//|  tratamento de erro conferia o codigo 4302, que nao e o de       |
//|  "ja existe" (o correto e 5304). Resultado: falhava em silencio  |
//|  e a pasta Bases/Custom ficava vazia.                            |
//|                                                                  |
//|  Aqui o simbolo recebe o sufixo "_B3" (PETR4_B3), entao nao ha   |
//|  colisao. O simbolo personalizado le tudo do CSV local e NAO     |
//|  depende de conexao com a corretora — que e justamente o ponto:  |
//|  o testador para de exigir sincronizacao de historico com o      |
//|  servidor.                                                       |
//|                                                                  |
//|  Formato esperado do CSV (sem cabecalho):                        |
//|    data,hora,abertura,maxima,minima,fechamento,volume            |
//|    2021.04.26,00:00,23.85,24.05,23.61,23.78,33281000             |
//|                                                                  |
//+------------------------------------------------------------------+
//--- Sem "#property script_show_inputs" de proposito: rodando pela linha de
//--- comando ([StartUp] do /config) a janela de parametros abre e fica
//--- esperando um clique que ninguem da, e o OnStart nunca executa. Os
//--- inputs abaixo continuam editaveis pela aba "Entradas" se rodar a mao.
#property strict
#property description "Importa CSVs da B3 como simbolos personalizados (sufixo _B3)"

input string InpDataDir = "B3_Historical";   // Pasta dentro de MQL5/Files
input string InpSufixo  = "_B3";             // Sufixo para evitar colisao
input bool   InpApenasPETR4 = false;         // true = importa so o PETR4
input int    InpDigitos = 2;              // Casas decimais (4 para serie ajustada antiga)
input double InpLote = 100;               // Lote minimo e passo (1 para serie reescalada)

string g_tickers[] =
  {
   "PETR4","VALE3","ITUB4","BBDC4","ABEV3","MGLU3","WEGE3","B3SA3",
   "PRIO3","BBAS3","RENT3","RAIZ4","SUZB3","IBOV",
   "USIM5","POMO4","VLID3","CIEL3"
  };

//+------------------------------------------------------------------+
//| Cria (ou reaproveita) o simbolo personalizado                    |
//+------------------------------------------------------------------+
bool PrepararSimbolo(const string simbolo)
  {
   ResetLastError();

   if(!CustomSymbolCreate(simbolo, "Custom\\B3"))
     {
      int err = GetLastError();

      //--- 5304 = ERR_CUSTOM_SYMBOL_EXIST: ja existe, tudo bem,
      //--- so vamos atualizar as barras dele.
      if(err != 5304)
        {
         PrintFormat("  [%s] falha ao criar simbolo: erro %d", simbolo, err);
         return(false);
        }
      PrintFormat("  [%s] simbolo ja existia, atualizando barras", simbolo);
     }

   //--- Propriedades coerentes com uma acao da B3.
   //--- Volume minimo/passo = 100 espelha o PETR4 real (confirmado
   //--- na janela de Simbolos), para o backtest nao ficar mais
   //--- permissivo que o mercado.
   CustomSymbolSetString(simbolo, SYMBOL_DESCRIPTION, "B3 - " + simbolo);
   CustomSymbolSetString(simbolo, SYMBOL_CURRENCY_BASE,   "BRL");
   CustomSymbolSetString(simbolo, SYMBOL_CURRENCY_PROFIT, "BRL");
   CustomSymbolSetString(simbolo, SYMBOL_CURRENCY_MARGIN, "BRL");

   //--- ATENCAO: com mais de 2 casas o valor do tick (ex.: 0,0001) e
   //--- arredondado pela moeda da conta e vira ZERO: todo negocio sai com
   //--- lucro 0,00 (visto em 21/09/2026). Para serie ajustada antiga, melhor
   //--- reescalar os precos no CSV (x10) e manter 2 casas.
   //--- Modo de calculo ANTES do tick: definido depois, ele zerava o valor
   //--- do tick de um simbolo recem-criado e todo negocio saia com lucro
   //--- 0,00 na 1a importacao (visto em 21-22/09/2026).
   CustomSymbolSetInteger(simbolo, SYMBOL_TRADE_CALC_MODE, SYMBOL_CALC_MODE_EXCH_STOCKS);
   double ponto = MathPow(10.0, -InpDigitos);
   CustomSymbolSetInteger(simbolo, SYMBOL_DIGITS, InpDigitos);
   CustomSymbolSetDouble(simbolo, SYMBOL_POINT, ponto);
   CustomSymbolSetDouble(simbolo, SYMBOL_TRADE_TICK_SIZE,  ponto);
   CustomSymbolSetDouble(simbolo, SYMBOL_TRADE_TICK_VALUE, ponto);
   CustomSymbolSetDouble(simbolo, SYMBOL_TRADE_CONTRACT_SIZE, 1.0);

   CustomSymbolSetDouble(simbolo, SYMBOL_VOLUME_MIN,  InpLote);
   CustomSymbolSetDouble(simbolo, SYMBOL_VOLUME_STEP, InpLote);
   CustomSymbolSetDouble(simbolo, SYMBOL_VOLUME_MAX,  1000000);

   CustomSymbolSetInteger(simbolo, SYMBOL_TRADE_MODE, SYMBOL_TRADE_MODE_FULL);
   //--- BID, nao LAST: com LAST o testador so atualiza o preco "last" e
   //--- deixa bid/ask congelados no primeiro tick. Patrimonio e fechamento
   //--- de posicao usam bid, entao o backtest saia com lucro zero.
   //--- Visto em 21/09/2026 (PETR4_AJ: 3500 acoes o ano todo, lucro 0,00).
   CustomSymbolSetInteger(simbolo, SYMBOL_CHART_MODE, SYMBOL_CHART_MODE_BID);
   CustomSymbolSetInteger(simbolo, SYMBOL_TRADE_EXEMODE, SYMBOL_TRADE_EXECUTION_INSTANT);
   CustomSymbolSetInteger(simbolo, SYMBOL_SWAP_MODE, SYMBOL_SWAP_MODE_DISABLED);

   return(true);
  }

//+------------------------------------------------------------------+
//| Le o CSV e grava as barras no simbolo                            |
//+------------------------------------------------------------------+
bool ImportarCSV(const string simbolo, const string caminho)
  {
   int fh = FileOpen(caminho, FILE_READ | FILE_CSV | FILE_ANSI, ',');
   if(fh == INVALID_HANDLE)
     {
      PrintFormat("  [%s] nao abriu %s: erro %d", simbolo, caminho, GetLastError());
      return(false);
     }

   MqlRates barras[];
   ArrayResize(barras, 2000);
   int n = 0;

   while(!FileIsEnding(fh))
     {
      string s_data = FileReadString(fh);
      if(StringLen(s_data) == 0)
         break;

      string s_hora = FileReadString(fh);
      double o = StringToDouble(FileReadString(fh));
      double h = StringToDouble(FileReadString(fh));
      double l = StringToDouble(FileReadString(fh));
      double c = StringToDouble(FileReadString(fh));
      long   v = StringToInteger(FileReadString(fh));

      //--- Descarta linhas invalidas (cabecalho, feriado, dado furado)
      if(o <= 0.0 || h <= 0.0 || l <= 0.0 || c <= 0.0)
         continue;

      //--- Coerencia de OHLC: a maxima tem que ser o maior valor e a
      //--- minima o menor. Dado de fonte externa as vezes vem trocado,
      //--- e isso quebraria o backtest de forma silenciosa.
      if(h < l || h < o || h < c || l > o || l > c)
        {
         PrintFormat("  [%s] linha com OHLC inconsistente em %s - ignorada", simbolo, s_data);
         continue;
        }

      datetime dt = StringToTime(s_data + " " + s_hora);
      if(dt == 0)
         continue;

      if(n >= ArraySize(barras))
         ArrayResize(barras, n + 1000);

      barras[n].time        = dt;
      barras[n].open        = o;
      barras[n].high        = h;
      barras[n].low         = l;
      barras[n].close       = c;
      barras[n].tick_volume = v;
      barras[n].real_volume = v;
      barras[n].spread      = 1;
      n++;
     }

   FileClose(fh);

   if(n == 0)
     {
      PrintFormat("  [%s] nenhuma barra valida lida", simbolo);
      return(false);
     }

   ArrayResize(barras, n);

   ResetLastError();
   int gravadas = CustomRatesUpdate(simbolo, barras);

   if(gravadas < 0)
     {
      PrintFormat("  [%s] CustomRatesUpdate falhou: erro %d", simbolo, GetLastError());
      return(false);
     }

   PrintFormat("  [%s] %d barras gravadas (de %s ate %s)",
               simbolo, gravadas,
               TimeToString(barras[0].time, TIME_DATE),
               TimeToString(barras[n - 1].time, TIME_DATE));

   SymbolSelect(simbolo, true);
   return(true);
  }

//+------------------------------------------------------------------+
void OnStart()
  {
   Print("==========================================");
   Print(" Importador B3 -> simbolos personalizados");
   Print("==========================================");

   int ok = 0, falhas = 0;
   string importados = "";

   for(int i = 0; i < ArraySize(g_tickers); i++)
     {
      string ticker = g_tickers[i];

      if(InpApenasPETR4 && ticker != "PETR4")
         continue;

      string arquivo = InpDataDir + "\\" + ticker + ".csv";
      string simbolo = ticker + InpSufixo;

      if(!FileIsExist(arquivo))
        {
         PrintFormat("  [%s] CSV nao encontrado: %s", simbolo, arquivo);
         falhas++;
         continue;
        }

      if(PrepararSimbolo(simbolo) && ImportarCSV(simbolo, arquivo))
        {
         ok++;
         importados += simbolo + "  ";
        }
      else
         falhas++;
     }

   Print("------------------------------------------");
   PrintFormat(" Concluido: %d importados, %d falhas", ok, falhas);
   if(ok > 0)
     {
      Print(" Simbolos: ", importados);
      Print(" Veja em Market Watch (Ctrl+M) -> Custom\\B3");
      Print(" No testador, escolha PETR4_B3 (nao PETR4)");
     }
   Print("==========================================");

   //--- Resultado tambem em arquivo. Sem isto o script so poderia ser
   //--- conferido pela janela do terminal; com o arquivo ele pode rodar
   //--- pela linha de comando (secao [StartUp] do /config) e ainda assim
   //--- ser verificado. Nao ha MessageBox de proposito: uma caixa modal
   //--- trava o script quando ele roda sem ninguem na frente da tela.
   int fh = FileOpen("import_b3_resultado.txt", FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(fh != INVALID_HANDLE)
     {
      FileWriteString(fh, StringFormat("importados=%d falhas=%d\n", ok, falhas));
      FileWriteString(fh, "simbolos=" + importados + "\n");
      for(int i = 0; i < ArraySize(g_tickers); i++)
        {
         string sim = g_tickers[i] + InpSufixo;
         if(!SymbolSelect(sim, true))
            continue;
         FileWriteString(fh, StringFormat("%s barras=%d\n",
                                          sim, Bars(sim, PERIOD_D1)));
        }
      FileClose(fh);
     }
  }
//+------------------------------------------------------------------+
