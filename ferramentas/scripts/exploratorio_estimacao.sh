#!/bin/bash
# EXPLORATORIO (15/10/2026, curiosidade do autor): a estimacao muda o resultado?
#
#   bash exploratorio_estimacao.sh <pasta_da_bateria_2026-10-15>
#
# Roda os MESMOS robos da bateria de 15/10 (GR, GRgemeo e AR escolhidos com
# Hannan-Rissanen + AIC, sem reotimizar) em T1 T2 R6 T3 T5, trocando so a
# estimacao do ARIMA e o criterio de escolha das ordens:
#   MVAIC = maxima verossimilhanca + AIC
#   MVBIC = maxima verossimilhanca + BIC
#   HRBIC = Hannan-Rissanen + BIC
# A referencia (HR + AIC) sao os testes N_* da propria bateria.
# Ressalva: as configuracoes foram escolhidas com HR + AIC, o que favorece essa
# combinacao. Nao muda a decisao registrada no PROTOCOLO da bateria.
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"
D="$(cd "$1" && pwd)"; [ -d "$D/escolhas" ] || { echo "uso: $0 <pasta da bateria>"; exit 1; }
OUT="$D/exploratorio_estimacao"; mkdir -p "$OUT/testes"
LOG="$OUT/execucao.log"; : > "$LOG"
B="$TRAB/sub15/base.txt"; [ -s "$B" ] || { echo "falta $B (rode a bateria antes)"; exit 1; }
EA='robos\ARIMA-GARCH\ARIMA_GARCH_EA'
export ESPERA=5400
cfg(){ awk -v k="$2" '$1 == k { sub(/^[^|]*\| /, ""); print }' "$1"; }
JT=("" "T1 2007.01.02 2011.12.30" "T2 2013.01.02 2016.12.30" "T3 2025.01.02 2026.09.19"
    "R6 2017.01.02 2024.12.30" "T5 2020.01.02 2021.12.30")
COMBOS=("HRBIC:MetodoARIMA=0 SelecaoPorBIC=true" "MVAIC:MetodoARIMA=1 SelecaoPorBIC=false" "MVBIC:MetodoARIMA=1 SelecaoPorBIC=true")
echo "inicio $(date '+%F %T')" | tee -a "$LOG"
ROT=""
for c in "${COMBOS[@]}"; do
  nome=${c%%:*}; opc=${c#*:}
  for j in 1 2 3 4 5; do
    set -- ${JT[$j]}; n=$1; de=$2; ate=$3; E="$D/escolhas/rf_C$j.txt"
    for k in GR GRgemeo AR; do
      rot="X_${nome}_${n}_$k"; ROT="$ROT $rot"; t0=$(date +%s)
      bash "$S/rodar.sh" "$rot" "$EA" PETR4_OFICIAL "$de" "$ate" 100000 1:1 "$B" \
        DistribuicaoGARCH=0 $opc $(cfg "$E" $k) >> "$LOG" 2>&1
      echo "$rot $(( $(date +%s)-t0 )) s $([ -s "$COMUM/metricas_$rot.csv" ] && echo ok || echo FALTOU)" | tee -a "$LOG"
    done
  done
done
for r in $ROT; do cp "$COMUM/metricas_$r.csv" "$COMUM/curva_$r.csv" "$OUT/testes/" 2>>"$LOG"; done
echo "fim $(date '+%F %T')" | tee -a "$LOG"
