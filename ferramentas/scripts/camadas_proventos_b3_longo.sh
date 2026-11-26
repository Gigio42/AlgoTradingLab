#!/bin/bash
# camadas_proventos_b3_longo.sh (17/11/2026, pergunta do autor): o periodo mais
# longo (2005-2026, rotulos L1 da refacao de 05/10) com os proventos da B3, como o
# camadas_proventos_b3.sh fez para as tabelas do Cap. III. Mesmas configuracoes de
# refeito_2026-10-05/testes/execucao.log (GS e GC de C2, gemea, MM).
# So a camada 4 (ret_completo) e bh_total podem mudar em relacao a testes/.
# A gemea do GC e identica a do GS (mesma linha no execucao.log), roda uma vez.
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
R="$A/dados/resultados/refeito_2026-10-05"; O="$R/proventos_b3"; mkdir -p "$O"
B="$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"
M="$A/dados/resultados/rodada3_b3_oficial/testes/in_mm.txt"
EA='robos\ARIMA-GARCH\ARIMA_GARCH_EA'; MMEA='robos\MediasMoveis2\MediasMoveis2'
cmp -s "$A/dados/series/proventos_PETR4.csv" "$N/MQL5/Files/proventos_PETR4.csv" \
  || cp "$A/dados/series/proventos_PETR4.csv" "$N/MQL5/Files/proventos_PETR4.csv"
LOG="$O/execucao_longo.log"; [ -n "${ROTULOS:-}" ] || : > "$LOG"
args(){ grep "^== $1 " "$R/testes/execucao.log" | head -1 | cut -d' ' -f3-; }
de=2005.01.03; ate=2026.09.18
for rot in ${ROTULOS:-L1_GS L1_GC L1_GSgemeo L1_MM}; do
  echo "== $rot" >> "$LOG"; limpar_cache PETR4_OFICIAL; rm -f "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv"
  case $rot in
    *_MM) bash "$S/rodar.sh" $rot "$MMEA" PETR4_OFICIAL $de $ate 100000 1:1 "$M" \
            Volume_Fixo_Input=0 Fracao_Capital=0.95 SomenteCompra=true Custo_Por_Lado=0.0003 >> "$LOG" 2>&1 ;;
    *)    bash "$S/rodar.sh" $rot "$EA" PETR4_OFICIAL $de $ate 100000 1:1 "$B" $(args $rot) >> "$LOG" 2>&1 ;;
  esac
  cp "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv" "$O/" 2>/dev/null || echo "SEM SAIDA $rot" | tee -a "$LOG"
done
echo fim $(date '+%F %T') >> "$LOG"
