#!/bin/bash
# comparar.sh <pares.txt> <saida.csv>
# Teste pareado (Jobson-Korkie com a correcao de Memmel) entre curvas que
# estao em Common/Files/AlgoLab (curva_<rotulo>.csv).
# pares.txt: uma linha por par, "grupo;rotulo_a;rotulo_b".
#
# Roda ferramentas/CompararModelosEA.mq5 no TESTADOR (uma passagem curta,
# qualquer periodo): o calculo acontece no OnInit e o agente le e grava
# Common/Files. Antes era um script pelo [StartUp], que precisa abrir um
# grafico; em 06/10/2026 o perfil Default chegou ao limite de 100 graficos
# ("open charts limit reached") e o script deixou de rodar.
source "$(dirname "$0")/comum.sh"
A="$(cd "$(dirname "$0")/../.." && pwd)"
[ -s "$1" ] && [ -n "$2" ] || { echo "uso: $0 <pares.txt> <saida.csv>"; exit 1; }
SAIDA="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
tr -d '\r' < "$1" > "$COMUM/pares.txt"; rm -f "$COMUM/comparacoes.csv"
cp "$A/ferramentas/CompararModelosEA.mq5" "$A/ferramentas/CompararModelos.mqh" "$N/MQL5/Experts/"
( cd "$N" && WINEPREFIX=~/.wine-mt5-novo wine MetaEditor64.exe /compile:"MQL5\Experts\CompararModelosEA.mq5" /log >/dev/null 2>&1 )
iconv -f UTF-16LE -t UTF-8 "$N/MQL5/Experts/CompararModelosEA.log" | grep -E "Result:"
ini="$TRAB/comparar.ini"
{ printf '%s[Tester]\r\n' "$CONTA"
  printf 'Expert=CompararModelosEA\r\nSymbol=PETR4_OFICIAL\r\nPeriod=D1\r\nModel=2\r\nFromDate=2024.01.02\r\nToDate=2024.01.31\r\nDeposit=100000\r\nCurrency=BRL\r\nLeverage=1:1\r\nOptimization=0\r\nVisual=0\r\nReport=rel_comparar\r\nReplaceReport=1\r\n'; } > "$ini"
matar; rm -f "$N"/rel_comparar.*; rodar_ini "$ini"; esperar "$COMUM/comparacoes.csv" 300 && sleep 2; matar
cp "$COMUM/comparacoes.csv" "$SAIDA" && echo "gravado $SAIDA ($(( $(wc -l < "$SAIDA") - 1 )) pares, esperados $(grep -c ';' "$1"))"
