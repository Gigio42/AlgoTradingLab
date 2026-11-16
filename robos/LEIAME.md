# Robôs

O código que roda no MetaTrader 5. São dois robôs (Expert Advisors) que usam os
mesmos módulos, para que a comparação entre eles não dependa de diferença de
implementação.

| Pasta | Conteúdo |
|---|---|
| `ARIMA-GARCH/` | O robô do trabalho. `ARIMA_GARCH_EA.mq5` tem os inputs e a decisão a cada pregão; com `UsarGARCH=false` ele vira o ARIMA puro. `Diagnostico.mqh` (mensagens e traço por barra) e `Avaliacao.mqh` (métricas no testador) só observam, sem influenciar a decisão. |
| `MediasMoveis2/` | As médias móveis de 10 e 20 dias de Almeida (2016), reimplementadas para a comparação. |
| `Include/` | Os módulos compartilhados, descritos abaixo. |
| `legado/` | A primeira implementação, substituída. Não compila com o resto e fica só para consulta. |

## Módulos (`Include/`)

| Arquivo | O que faz |
|---|---|
| `Numerico.mqh` | Mínimos quadrados sobre a ALGLIB (a única porta para álgebra linear). |
| `Estatistica.mqh` | Teste ADF, Ljung-Box, AIC/BIC, média, variância, percentil. |
| `Arima.mqh` | O ARIMA, estimado por Hannan-Rissanen. |
| `SelecaoModelo.mqh` | Escolhe `d` pelo ADF em sequência e `p`, `q` pela grade no AIC. |
| `Garch.mqh` | O GARCH(1,1), por máxima verossimilhança com restrições. |
| `Estrategia.mqh` | Como o GARCH entra na decisão: filtro, ajuste da posição ou os dois juntos. |
| `Negociacao.mqh` | Ordens, posição e volume. Usado pelos dois robôs. |
| `Desempenho.mqh` | Métricas no testador e comparação entre curvas. Usado pelos dois robôs. |
| `ArimaVerossimilhanca.mqh`, `GarchDistribuicao.mqh` | Opções experimentais (ARIMA por máxima verossimilhança, GARCH com t de Student). Não fazem parte do TG. |

Os `#include` dos robôs apontam para `..\Include\`, então as três pastas
`ARIMA-GARCH/`, `MediasMoveis2/` e `Include/` precisam ficar juntas.

Para compilar, abra `ARIMA-GARCH/ARIMA_GARCH_EA.mq5` ou
`MediasMoveis2/MediasMoveis2.mq5` no MetaEditor. No testador, os robôs aparecem
em `AlgoTradingLab > robos`.
