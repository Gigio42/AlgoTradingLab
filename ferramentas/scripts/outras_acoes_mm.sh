#!/bin/bash
# outras_acoes_mm.sh
#
# Médias móveis reproduzidas (MediasMoveis2, 10/20, só compra, 95% do
# patrimônio) em VALE3, USIM5 e POMO4, nos mesmos três períodos de teste da
# seção "Outras ações" do Cap. III. Pedido do autor em 29/10/2026: a seção só
# tinha ARIMA e ARIMA-GARCH. Sem otimização: um teste por ação e período,
# com o mesmo in_mm.txt dos testes da PETR4 (refazer_testes.sh, rodada 3).
#
# Antes, refaz R3_T1_MM na PETR4 como conferência: tem de bater com
# refeito_2026-10-05/testes/metricas_R3_T1_MM.csv.
#
# Saída: refeito_2026-10-05/testes/{metricas,curva}_R4_<ATIVO>_T<k>_MM.csv,
#        relatorios_mt5/rel_R4_<ATIVO>_T<k>_MM.{htm,png} e testes/mm_outras.log
# Uso (da raiz do repositório): bash ferramentas/scripts/outras_acoes_mm.sh
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
OUT="$A/dados/resultados/refeito_2026-10-05"
M="$A/dados/resultados/rodada3_b3_oficial/testes/in_mm.txt"
MMEA='MediasMoveis2\MediasMoveis2'
LOG="$OUT/testes/mm_outras.log"; : > "$LOG"
JT=("" "2007.01.02 2011.12.30" "2013.01.02 2016.12.30" "2025.01.02 2026.09.19")

roda(){ local rot=$1 sim=$2 de=$3 ate=$4; shift 4
  echo "== $rot $sim $de $ate $*" >> "$LOG"
  bash "$S/rodar.sh" "$rot" "$MMEA" "$sim" "$de" "$ate" 100000 1:1 "$M" "$@" >> "$LOG" 2>&1
  cp "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv" "$OUT/testes/"
  cp "$TRAB/rel/rel_$rot.htm" "$TRAB/rel/rel_$rot.png" "$OUT/relatorios_mt5/" 2>/dev/null; }

echo "inicio $(date '+%F %T')" >> "$LOG"
roda R3_T1_MM_conf PETR4_OFICIAL 2007.01.02 2011.12.30
for a in VALE3 USIM5 POMO4; do
  for j in 1 2 3; do
    set -- ${JT[$j]}
    roda R4_${a}_T${j}_MM ${a}_OFICIAL $1 $2 Arquivo_Proventos=proventos_$a.csv
  done
done
echo "fim $(date '+%F %T')" >> "$LOG"
