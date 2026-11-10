#!/bin/bash
# Roda o script de validacao numerica (ferramentas/ValidacaoAlgoLab.mq5) no
# terminal do prefixo novo e copia a saida para dados/verificacao/.
# Armadilhas (CLAUDE.md): [StartUp] precisa de Symbol/Period, [Experts] com
# AllowLiveTrading=1, sem ShutdownTerminal; encerrar com wineserver -k.
# 06/11/2026: compila no prefixo deste repositorio (~/.wine-mt5, onde os
# #include de robos/ resolvem), copia so o .ex5 para o prefixo em uso e roda com
# o perfil de graficos AlgoLab (INCERTEZAS item 54), como o testes_formulas.sh.
# A copia antiga em MQL5\Scripts do prefixo novo ainda apontava para Include\
# (sem robos\). Semente fixa: rodar de novo da os mesmos numeros.
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
V="$HOME/.wine-mt5/drive_c/Program Files/MetaTrader 5"
OUT="$N/MQL5/Files/validacao_algolab.txt"

cp "$A/ferramentas/ValidacaoAlgoLab.mq5" "$V/MQL5/Scripts/"
( cd "$V" && WINEPREFIX=~/.wine-mt5 wine MetaEditor64.exe /compile:"MQL5\Scripts\ValidacaoAlgoLab.mq5" /log >/dev/null 2>&1 )
iconv -f UTF-16LE -t UTF-8 "$V/MQL5/Scripts/ValidacaoAlgoLab.log" | grep -E "error|warning|Result:"
cp "$V/MQL5/Scripts/ValidacaoAlgoLab.ex5" "$N/MQL5/Scripts/" || exit 1

ini="$TRAB/validar.ini"
cp -p "$N/Config/common.ini" "$TRAB/common.ini.antes"
printf '[Charts]\r\nProfileLast=AlgoLab\r\n%s[StartUp]\r\nScript=ValidacaoAlgoLab\r\nSymbol=PETR4_OFICIAL\r\nPeriod=D1\r\n' "$CONTA" > "$ini"
matar; rm -f "$OUT"; rodar_ini "$ini"
for i in $(seq 1 200); do sleep 3; grep -q "FIM" "$OUT" 2>/dev/null && break; done
sleep 3; matar
cp -p "$TRAB/common.ini.antes" "$N/Config/common.ini"

dest="$A/dados/verificacao/validacao_numerica_$(date +%Y-%m-%d).txt"
cp "$OUT" "$dest" && echo "gravado $dest" && cat "$dest"
