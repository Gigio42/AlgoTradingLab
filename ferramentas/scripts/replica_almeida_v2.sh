#!/bin/bash
# Replica de Almeida (2016), rodada 2 (21/10/2026): ReplicaAlmeidaEA em
# varias series, logicas de entrada e modelos de tick. Protocolo em
# dados/resultados/replica_almeida_v2_2026-10-21/PROTOCOLO.md.
# Uso: bash replica_almeida_v2.sh   (grava rel_*.htm e resumo.txt na pasta de resultados)
source "$(dirname "$0")/comum.sh"
A="$(cd "$(dirname "$0")/../.." && pwd)"
R="$A/dados/resultados/replica_almeida_v2_2026-10-21"
S="$A/ferramentas/scripts"
B="$N/MQL5/Experts/AlgoTradingLab/ferramentas"
mkdir -p "$B" "$R/relatorios"
cp "$A/ferramentas/ReplicaAlmeidaEA.mq5" "$B/"
(cd "$N" && WINEPREFIX=~/.wine-mt5-novo wine MetaEditor64.exe /compile:"MQL5\Experts\AlgoTradingLab\ferramentas\ReplicaAlmeidaEA.mq5" /log >/dev/null 2>&1)
iconv -f UTF-16LE -t UTF-8 "$B/ReplicaAlmeidaEA.log" | grep "Result:"
printf 'RapidaMM_Periodo=10\nDevagarMM_Periodo=20\nVolume=100\nModoEntrada=0\nModoReversao=0\nPularPrimeiraBarra=true\n' > "$TRAB/in_replica.txt"

# teste: rotulo simbolo de ate volume alavancagem
TESTES=(
 "T1of PETR4_OFICIAL 2007.01.01 2011.12.31 100 1:100"
 "T2of PETR4_OFICIAL 2008.01.01 2010.12.31 100 1:100"
 "T3of PETR4_OFICIAL 2013.05.22 2016.05.24 1000 1:100"
 "T1d8 PETR4_DESDE2008 2007.01.01 2011.12.31 100 1:100"
 "T2d8 PETR4_DESDE2008 2008.01.01 2010.12.31 100 1:100"
 "T4ci CIEL3_ESTIMADO 2012.06.04 2016.06.04 1000 1:100"
 "T5vl VLID3_OFICIAL 2012.06.04 2016.06.04 1000 1:100"
)
for t in "${TESTES[@]}"; do
  set -- $t; rot=$1; sim=$2; de=$3; ate=$4; vol=$5; alav=$6
  for modelo in 2 0; do
    for ent in 0 1; do
      for rev in 0 1; do
        r="ra_${rot}_m${modelo}_e${ent}_r${rev}"
        limpar_cache "$sim"
        MODELO=$modelo bash "$S/rodar.sh" "$r" 'ferramentas\ReplicaAlmeidaEA' "$sim" "$de" "$ate" 50000 "$alav" \
          "$TRAB/in_replica.txt" Volume=$vol ModoEntrada=$ent ModoReversao=$rev >/dev/null 2>&1
        cp "$N/rel_$r.htm" "$R/relatorios/" 2>/dev/null || echo "SEM RELATORIO $r"
      done
    done
  done
done
bash "$S/resumo_replica_almeida.sh" "$R/relatorios" > "$R/resumo.txt"
cat "$R/resumo.txt"
