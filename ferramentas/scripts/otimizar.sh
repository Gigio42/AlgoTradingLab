#!/bin/bash
# otimizar.sh <janela> <simbolo> <de> <ate> <arq_grade>  -> otimizacao; CSVs vao para $TRAB/g/<simbolo>_<janela>
source "$(dirname "$0")/comum.sh"
nome=$1; sim=$2; sub=$(basename "$5" .txt); rel="rel_o_${sim}_${nome}_$sub"; ini="$TRAB/o_${sim}_${nome}_$sub.ini"
matar; rm -rf "$COMUM"/res_* "$N"/Tester/cache/*
{ printf '%s[Tester]\r\n' "$CONTA"
  printf 'Expert=AlgoTradingLab\\ARIMA-GARCH\\ARIMA_GARCH_EA\r\nSymbol=%s\r\nPeriod=D1\r\nModel=2\r\nFromDate=%s\r\nToDate=%s\r\nDeposit=100000\r\nCurrency=BRL\r\nLeverage=1:1\r\nOptimization=1\r\nOptimizationCriterion=6\r\nVisual=0\r\nReport=%s\r\nReplaceReport=1\r\n[TesterInputs]\r\n' "$sim" "$3" "$4" "$rel"
  sed 's/$/\r/' "$5"; } > "$ini"
rm -f "$N/$rel".*; t0=$(date +%s); rodar_ini "$ini"; esperar "$N/$rel.xml" 3600; sleep 3; matar
d="$TRAB/g/${sim}_${nome}"; mkdir -p "$d"; n=$(ls "$COMUM" | grep -c res_); mv "$COMUM"/res_* "$d"/ 2>/dev/null
echo "$sim $nome $sub: $n passagens em $(( $(date +%s)-t0 )) s"
