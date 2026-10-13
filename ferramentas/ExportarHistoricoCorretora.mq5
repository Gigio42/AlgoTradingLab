//+------------------------------------------------------------------+
//| ExportarHistoricoCorretora.mq5                                   |
//| Exporta o historico diario de um simbolo DA CORRETORA (servidor  |
//| conectado) para MQL5\Files\corretora_<simbolo>_D1.csv, para      |
//| conferencia contra outras fontes. Nao altera nada no terminal.   |
//+------------------------------------------------------------------+
input string InpSimbolo = "PETR4";

void OnStart()
  {
   if(!SymbolSelect(InpSimbolo, true))
     { Print("simbolo nao existe no servidor: ", InpSimbolo); return; }

   //--- O historico chega do servidor de forma assincrona: pede tudo e
   //--- repete ate a contagem estabilizar
   MqlRates r[];
   int ant = -1, n = 0;
   for(int i = 0; i < 60; i++)
     {
      n = CopyRates(InpSimbolo, PERIOD_D1, D'1990.01.01', TimeCurrent(), r);
      if(n > 0 && n == ant) break;
      ant = n;
      Sleep(2000);
     }

   string servidor = AccountInfoString(ACCOUNT_SERVER);
   datetime primeira_srv = (datetime)SeriesInfoInteger(InpSimbolo, PERIOD_D1, SERIES_SERVER_FIRSTDATE);
   PrintFormat("%s D1: %d barras de %s a %s | servidor %s, primeira data no servidor %s",
               InpSimbolo, n, n > 0 ? TimeToString(r[0].time, TIME_DATE) : "-",
               n > 0 ? TimeToString(r[n - 1].time, TIME_DATE) : "-", servidor,
               TimeToString(primeira_srv, TIME_DATE));

   int fh = FileOpen("corretora_" + InpSimbolo + "_D1.csv", FILE_WRITE | FILE_TXT | FILE_ANSI);
   FileWriteString(fh, StringFormat("# fonte: servidor %s, simbolo %s, exportado em %s (hora do servidor)\n",
                   servidor, InpSimbolo, TimeToString(TimeCurrent())));
   FileWriteString(fh, "data,abertura,maxima,minima,fechamento,volume_ticks,volume_real\n");
   for(int i = 0; i < n; i++)
      FileWriteString(fh, StringFormat("%s,%.4f,%.4f,%.4f,%.4f,%I64d,%I64d\n",
                      TimeToString(r[i].time, TIME_DATE), r[i].open, r[i].high, r[i].low,
                      r[i].close, r[i].tick_volume, r[i].real_volume));
   FileClose(fh);
  }
