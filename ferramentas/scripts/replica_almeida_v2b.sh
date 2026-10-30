#!/bin/bash
# Replica de Almeida, rodada 2, parte b (21/10/2026): PETR4 com historico desde
# 04/09/2007 (PETR4_SET2007) e ajustada por proventos ate 06/2016 (PETR4_DIVAJ2016, Yahoo) ou pelos
# proventos oficiais da B3 com historico desde 02/01/2008 (PETR4_PROVB3). Mesmo EA e mesmo resumo da parte a.
source "$(dirname "$0")/comum.sh"
A="$(cd "$(dirname "$0")/../.." && pwd)"
R="$A/dados/resultados/replica_almeida_v2_2026-10-21"
S="$A/ferramentas/scripts"
printf 'RapidaMM_Periodo=10\nDevagarMM_Periodo=20\nVolume=100\nModoEntrada=0\nModoReversao=0\nPularPrimeiraBarra=true\n' > "$TRAB/in_replica.txt"
TESTES=(
 "T1s7 PETR4_SET2007 2007.01.01 2011.12.31 100"
 "T2s7 PETR4_SET2007 2008.01.01 2010.12.31 100"
 "T1pb PETR4_PROVB3 2007.01.01 2011.12.31 100"
 "T2pb PETR4_PROVB3 2008.01.01 2010.12.31 100"
 "T3pb PETR4_PROVB3 2013.05.22 2016.05.24 1000"
 "T4pb CIEL3_PROVB3 2012.06.04 2016.06.04 1000"
 "T5pb VLID3_PROVB3 2012.06.04 2016.06.04 1000"
 "T1dv PETR4_DIVAJ2016 2007.01.01 2011.12.31 100"
 "T2dv PETR4_DIVAJ2016 2008.01.01 2010.12.31 100"
 "T3dv PETR4_DIVAJ2016 2013.05.22 2016.05.24 1000"
)
for t in "${TESTES[@]}"; do
  [ -n "$SO" ] && [[ $t != *$SO* ]] && continue
  set -- $t; rot=$1; sim=$2; de=$3; ate=$4; vol=$5
  for ent in 0 1; do
    r="ra_${rot}_m2_e${ent}_r0"
    limpar_cache "$sim"
    bash "$S/rodar.sh" "$r" 'ferramentas\ReplicaAlmeidaEA' "$sim" "$de" "$ate" 50000 1:100 \
      "$TRAB/in_replica.txt" Volume=$vol ModoEntrada=$ent ModoReversao=0 >/dev/null 2>&1
    cp "$N/rel_$r.htm" "$R/relatorios/" 2>/dev/null || echo "SEM RELATORIO $r"
  done
done
bash "$S/resumo_replica_almeida.sh" "$R/relatorios" > "$R/resumo.txt"
