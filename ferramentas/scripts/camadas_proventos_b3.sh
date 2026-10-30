#!/bin/bash
# camadas_proventos_b3.sh (21/10/2026): refaz os 15 testes das tabelas de camadas
# do Cap. III com os proventos da B3 (proventos_b3.sh) no lugar dos do Yahoo.
# Mesmas configuracoes da refacao de 05/10 (refeito_2026-10-05/testes/execucao.log).
# So a camada 4 (ret_completo) e a compra e manutencao com proventos (bh_total)
# podem mudar; o resto tem de sair identico (conferir com comparar abaixo).
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
R="$A/dados/resultados/refeito_2026-10-05"; O="$R/proventos_b3"; mkdir -p "$O"
B="$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"
M="$A/dados/resultados/rodada3_b3_oficial/testes/in_mm.txt"
EA='ARIMA-GARCH\ARIMA_GARCH_EA'; MMEA='MediasMoveis2\MediasMoveis2'
cp "$N/MQL5/Files/proventos_PETR4.csv" "$TRAB/proventos_PETR4_yahoo_backup.csv"
cp "$A/dados/series/proventos_PETR4.csv" "$N/MQL5/Files/proventos_PETR4.csv"
LOG="$O/execucao.log"; : > "$LOG"
args(){ grep "^== $1 " "$R/testes/execucao.log" | head -1 | cut -d' ' -f3-; }
per(){ case $1 in R3_T1*) echo "2007.01.02 2011.12.30";; R3_T2*) echo "2013.01.02 2016.12.30";;
                  R3_T3*) echo "2025.01.02 2026.09.19";; R6*) echo "2017.01.02 2024.12.30";; esac; }
for rot in R3_T1_GS R3_T1_AS R3_T1_MM R3_T2_GS R3_T2_GC R3_T2_AS R3_T2_MM \
           R6_GS R6_GC R6_ARIMA R6_MM R3_T3_GS R3_T3_GC R3_T3_AS R3_T3_MM; do
  set -- $(per $rot); de=$1; ate=$2
  echo "== $rot" >> "$LOG"; limpar_cache PETR4_OFICIAL; rm -f "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv"
  case $rot in
    R6_MM) bash "$S/rodar.sh" $rot "$MMEA" PETR4_OFICIAL $de $ate 100000 1:1 "$M" \
             Volume_Fixo_Input=0 Fracao_Capital=0.95 SomenteCompra=true Custo_Por_Lado=0.0003 >> "$LOG" 2>&1 ;;
    *_MM)  bash "$S/rodar.sh" $rot "$MMEA" PETR4_OFICIAL $de $ate 100000 1:1 "$M" >> "$LOG" 2>&1 ;;
    *)     bash "$S/rodar.sh" $rot "$EA" PETR4_OFICIAL $de $ate 100000 1:1 "$B" $(args $rot) >> "$LOG" 2>&1 ;;
  esac
  cp "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv" "$O/" 2>/dev/null || echo "SEM SAIDA $rot" | tee -a "$LOG"
done
echo fim $(date '+%F %T') >> "$LOG"
