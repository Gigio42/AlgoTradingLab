#!/bin/bash
# Calibracao 2014-2016 para teste fora da amostra em 2017-2024.
# Mesmo protocolo das rodadas 3 e 4: grade fixa, 3 anos anteriores ao teste,
# escolha por maior Sharpe e por maior Calmar na camada 3.
A="/home/dark/.wine-mt5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/AlgoTradingLab"
S="$A/ferramentas/scripts"; G="$A/dados/resultados/rodada3_b3_oficial/grades"
cd "$S" || exit 1
for g in arima filtro_abs filtro_pct ft_abs ft_pct ic targ; do
  bash otimizar.sh C4 PETR4_OFICIAL 2014.01.02 2016.12.30 "$G/$g.txt"
done
echo "--- passagens coletadas ---"
ls /tmp/algolab-trabalho/g/PETR4_OFICIAL_C4/ 2>/dev/null | wc -l
