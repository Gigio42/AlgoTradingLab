#!/bin/bash
# rodar.sh <rotulo> <expert> <simbolo> <de> <ate> <deposito> <alavancagem> <arq_inputs> [chave=valor ...]
# Um backtest unico; grava metricas_<rotulo>.csv e curva_<rotulo>.csv em Common/Files/AlgoLab.
source "$(dirname "$0")/comum.sh"
rot=$1; exp=$2; sim=$3; de=$4; ate=$5; dep=$6; alav=$7; inp=$8; shift 8
[ -s "$inp" ] || { echo "ERRO: arquivo de inputs vazio ou inexistente: $inp"; exit 1; }
# Substitui a chave se ela existe no arquivo base; ACRESCENTA se nao existe.
# Sem o acrescimo, um input novo era silenciosamente ignorado (o .ini saia sem
# ele e o EA usava o padrao) -- foi assim que o Arquivo_Traco nao apareceu.
G=$(cat "$inp")
for kv in "$@"; do
  k=${kv%%=*}
  if echo "$G" | grep -q "^$k="; then G=$(echo "$G" | sed "s|^$k=.*|$kv|")
  else G="$G"$'\n'"$kv"; fi
done
G="$G"$'\n'"Rotulo=$rot"
ini="$TRAB/r_$rot.ini"
{ printf '%s[Tester]\r\n' "$CONTA"
  printf 'Expert=AlgoTradingLab\\%s\r\nSymbol=%s\r\nPeriod=D1\r\nModel=%s\r\nFromDate=%s\r\nToDate=%s\r\nDeposit=%s\r\nCurrency=BRL\r\nLeverage=%s\r\nOptimization=0\r\nVisual=0\r\nReport=rel_%s\r\nReplaceReport=1\r\n[TesterInputs]\r\n' "$exp" "$sim" "${MODELO:-2}" "$de" "$ate" "$dep" "$alav" "$rot"
  echo "$G" | sed 's/$/\r/'; } > "$ini"
matar; rm -f "$N/rel_$rot".*; rodar_ini "$ini"; esperar "$N/rel_$rot.htm" ${ESPERA:-600}; sleep 2; matar
mkdir -p "$TRAB/rel"; cp "$N/rel_$rot".htm "$N/rel_$rot".png "$TRAB/rel/" 2>/dev/null
f=$(ls -t "$N/Tester/"Agent*/logs/*.log | head -1)
iconv -f UTF-16LE -t UTF-8 "$f" | cut -f3- | grep -E "DESEMPENHO|camadas|referencias|camada 3|camada 4" | tail -5 | sed 's/^.*59   //;s/^.*00   //'
