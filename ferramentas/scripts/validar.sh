#!/bin/bash
# Roda o script de validacao numerica (ferramentas/ValidacaoAlgoLab.mq5) no
# terminal do prefixo novo e copia a saida para dados/verificacao/.
# Armadilhas (CLAUDE.md): [StartUp] precisa de Symbol/Period, [Experts] com
# AllowLiveTrading=1, sem ShutdownTerminal; encerrar com wineserver -k.
source "$(dirname "$0")/comum.sh"
A="/home/dark/.wine-mt5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/AlgoTradingLab"
OUT="$N/MQL5/Files/validacao_algolab.txt"
ini="$TRAB/validar.ini"
{ printf '%s' "$CONTA"
  printf '[StartUp]\r\nScript=ValidacaoAlgoLab\r\nSymbol=PETR4_OFICIAL\r\nPeriod=D1\r\n'; } > "$ini"
matar; rm -f "$OUT"; rodar_ini "$ini"; esperar "$OUT" 300 && sleep 5; matar
dest="$A/dados/verificacao/validacao_numerica_$(date +%Y-%m-%d).txt"
cp "$OUT" "$dest" && echo "gravado $dest" && cat "$dest"
