#!/bin/bash
# Replica de Almeida, rodada 2, parte c (21/10/2026): mesmas series das partes a e b,
# com as medias arredondadas para _Digits antes da comparacao, como faz o
# CIndicator::Main do livro de Young (2013), de onde vem o Indicators.mqh do anexo
# de Almeida (codigo do livro: MQL5BookSourceCode.zip, ver INCERTEZAS item 74).
source "$(dirname "$0")/comum.sh"
A="$(cd "$(dirname "$0")/../.." && pwd)"
R="$A/dados/resultados/replica_almeida_v2_2026-10-21"
S="$A/ferramentas/scripts"
B="$N/MQL5/Experts/AlgoTradingLab/ferramentas"
cp "$A/ferramentas/ReplicaAlmeidaEA.mq5" "$B/"
(cd "$N" && WINEPREFIX=~/.wine-mt5-novo wine MetaEditor64.exe /compile:"MQL5\Experts\AlgoTradingLab\ferramentas\ReplicaAlmeidaEA.mq5" /log >/dev/null 2>&1)
iconv -f UTF-16LE -t UTF-8 "$B/ReplicaAlmeidaEA.log" | grep "Result:"
printf 'RapidaMM_Periodo=10\nDevagarMM_Periodo=20\nVolume=100\nModoEntrada=0\nModoReversao=0\nPularPrimeiraBarra=true\nArredondarMedias=true\n' > "$TRAB/in_replica_n.txt"
TESTES=(
 "T1of PETR4_OFICIAL 2007.01.01 2011.12.31 100"
 "T2of PETR4_OFICIAL 2008.01.01 2010.12.31 100"
 "T3of PETR4_OFICIAL 2013.05.22 2016.05.24 1000"
 "T1s7 PETR4_SET2007 2007.01.01 2011.12.31 100"
 "T2s7 PETR4_SET2007 2008.01.01 2010.12.31 100"
 "T1d8 PETR4_DESDE2008 2007.01.01 2011.12.31 100"
 "T2d8 PETR4_DESDE2008 2008.01.01 2010.12.31 100"
 "T1pb PETR4_PROVB3 2007.01.01 2011.12.31 100"
 "T2pb PETR4_PROVB3 2008.01.01 2010.12.31 100"
 "T3pb PETR4_PROVB3 2013.05.22 2016.05.24 1000"
 "T4ci CIEL3_ESTIMADO 2012.06.04 2016.06.04 1000"
 "T4pb CIEL3_PROVB3 2012.06.04 2016.06.04 1000"
 "T5vl VLID3_OFICIAL 2012.06.04 2016.06.04 1000"
 "T5pb VLID3_PROVB3 2012.06.04 2016.06.04 1000"
)
for t in "${TESTES[@]}"; do
  [ -n "$SO" ] && [[ $t != *$SO* ]] && continue
  set -- $t; rot=$1; sim=$2; de=$3; ate=$4; vol=$5
  r="ra_${rot}_m2_e0_r0_n1"
  limpar_cache "$sim"
  bash "$S/rodar.sh" "$r" 'ferramentas\ReplicaAlmeidaEA' "$sim" "$de" "$ate" 50000 1:100 \
    "$TRAB/in_replica_n.txt" Volume=$vol ModoEntrada=0 ModoReversao=0 ArredondarMedias=true >/dev/null 2>&1
  cp "$N/rel_$r.htm" "$R/relatorios/" 2>/dev/null || echo "SEM RELATORIO $r"
done
bash "$S/resumo_replica_almeida.sh" "$R/relatorios" > "$R/resumo.txt"
grep "_n1\|relatorio" "$R/resumo.txt"
