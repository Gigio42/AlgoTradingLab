//+------------------------------------------------------------------+
//| CompararModelos.mq5 - teste pareado entre duas estrategias, a    |
//| partir das curvas diarias gravadas pelo Desempenho.mqh.          |
//|                                                                  |
//| Copia versionada (05/10/2026). Substitui CompararModelos e       |
//| CompararR6, que ficavam fora do repositorio com os pares escritos |
//| no codigo. Agora os pares vem de Common\Files\AlgoLab\pares.txt, |
//| uma linha por par:  grupo;rotulo_a;rotulo_b                      |
//| (le curva_<rotulo>.csv). Saida: AlgoLab\comparacoes.csv.         |
//| Para rodar: copiar para MQL5\Scripts e usar comparar.sh.         |
//|                                                                  |
//| A logica (Jobson-Korkie com a correcao de Memmel) esta em        |
//| CompararCurvas(), no Desempenho.mqh do EA.                       |
//+------------------------------------------------------------------+
#property script_show_inputs false
#include "..\Experts\AlgoTradingLab\Include\Desempenho.mqh"
#include "CompararModelos.mqh"

void OnStart() { CompararPares(); }
