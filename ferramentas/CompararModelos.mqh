//+------------------------------------------------------------------+
//| CompararModelos.mqh - teste pareado entre estrategias a partir   |
//| das curvas diarias gravadas pelo Desempenho.mqh.                  |
//| Le Common\Files\AlgoLab\pares.txt (grupo;rotulo_a;rotulo_b) e    |
//| grava AlgoLab\comparacoes.csv. Usado por CompararModelos.mq5     |
//| (script) e CompararModelosEA.mq5 (roda no testador, sem grafico). |
//| Quem inclui este arquivo inclui antes o Desempenho.mqh.           |
//+------------------------------------------------------------------+
void CompararPares()
  {
   int fp = FileOpen("AlgoLab\\pares.txt", FILE_READ | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(fp == INVALID_HANDLE)
     {
      Print("sem AlgoLab\\pares.txt");
      return;
     }
   int fh = FileOpen("AlgoLab\\comparacoes.tmp", FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   FileWriteString(fh, "grupo;modelo_a;modelo_b;n;sharpe_a;sharpe_b;rho;"
                       "z_sharpe;p_sharpe;dif_anual;t_dif;p_dif\n");
   int ok = 0, falhas = 0;
   while(!FileIsEnding(fp))
     {
      string linha = FileReadString(fp);
      string c3[];
      if(StringLen(linha) < 3 || StringGetCharacter(linha, 0) == '#' || StringSplit(linha, ';', c3) != 3)
         continue;
      ComparacaoModelos c;
      if(!CompararCurvas("AlgoLab\\curva_" + c3[1] + ".csv", "AlgoLab\\curva_" + c3[2] + ".csv", c))
        {
         PrintFormat("falhou: %s x %s", c3[1], c3[2]);
         falhas++;
         continue;
        }
      FileWriteString(fh, StringFormat("%s;%s;%s;%d;%.4f;%.4f;%.4f;%.4f;%.4f;%.6f;%.4f;%.4f\n",
                      c3[0], c3[1], c3[2], c.n, c.sharpe_a, c.sharpe_b, c.rho,
                      c.z_sharpe, c.p_sharpe, c.dif_anual, c.t_dif, c.p_dif));
      ok++;
     }
   FileClose(fp);
   FileClose(fh);
   //--- So aparece com o nome final quando terminou (o comparar.sh espera por ele)
   FileMove("AlgoLab\\comparacoes.tmp", FILE_COMMON, "AlgoLab\\comparacoes.csv", FILE_COMMON | FILE_REWRITE);
   PrintFormat("comparacoes.csv: %d pares, %d falhas", ok, falhas);
  }
