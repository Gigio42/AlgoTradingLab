//+------------------------------------------------------------------+
//| CompararModelosEA.mq5 - a mesma comparacao do CompararModelos,    |
//| rodada como EA no testador de estrategias (06/10/2026).           |
//| Motivo: o script precisa abrir um grafico pelo [StartUp], e o     |
//| terminal recusa quando o perfil chega ao limite de 100 graficos.  |
//| O testador nao abre grafico e o agente le e grava Common\Files.   |
//| Para rodar: comparar.sh (copia este arquivo para MQL5\Experts).   |
//+------------------------------------------------------------------+
#include "AlgoTradingLab\Include\Desempenho.mqh"
#include "CompararModelos.mqh"

int OnInit()
  {
   CompararPares();
   return(INIT_SUCCEEDED);
  }

void OnTick() {}
