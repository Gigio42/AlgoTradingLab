#!/bin/bash
# Efeito de trocar a distribuicao dos erros do GARCH (normal -> t de Student)
# nas configuracoes do TG, com tudo o mais fixo (sem nova calibracao).
# Protocolo: dados/resultados/garch_t_2026-10-13/PROTOCOLO.md
#
#  0. regressao: DistribuicaoGARCH=0 tem de reproduzir R6_GS da refacao
#  1. as 11 configuracoes com GARCH + cenario de Almeida 2013-2016, com t
#  2. testes pareados t x normal e t x gemea (comparar.sh)
#
# Uso: bash garch_t.sh <pasta_de_saida>
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
OUT="$1"; [ -n "$OUT" ] || { echo "uso: $0 <pasta_de_saida>"; exit 1; }
OUT="$(mkdir -p "$OUT" && cd "$OUT" && pwd)"
R="$A/dados/resultados/refeito_2026-10-05"
B="$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"
EA='ARIMA-GARCH\ARIMA_GARCH_EA'
mkdir -p "$OUT/testes"; LOG="$OUT/testes/execucao.log"; : > "$LOG"
cfg(){ awk -v k="$2" '$1 == k { sub(/^[^|]*\| /, ""); print }' "$R/escolhas/$1.txt"; }
roda(){ local rot=$1 de=$2 ate=$3; shift 3
  echo "== $rot $* [$(date +%T)]" >> "$LOG"
  bash "$S/rodar.sh" "$rot" "$EA" PETR4_OFICIAL "$de" "$ate" 100000 1:1 "$B" "$@" >> "$LOG" 2>&1; }
copia(){ cp "$COMUM/metricas_$1.csv" "$COMUM/curva_$1.csv" "$OUT/testes/"; }
echo "inicio $(date '+%F %T')"

# --- 0. regressao -----------------------------------------------------------
roda REG_R6_GS 2017.01.02 2024.12.30 $(cfg r6_C4 GS) DistribuicaoGARCH=0
copia REG_R6_GS
if cmp -s "$OUT/testes/curva_REG_R6_GS.csv" "$R/testes/curva_R6_GS.csv"; then
  echo "REGRESSAO OK: curva identica a refacao" | tee -a "$LOG"
else
  echo "REGRESSAO FALHOU: curva diferente da refacao; parando" | tee -a "$LOG"; exit 1
fi

# --- 1. t de Student ---------------------------------------------------------
JT=("" "2007.01.02 2011.12.30" "2013.01.02 2016.12.30" "2025.01.02 2026.09.19")
for j in 1 2 3; do set -- ${JT[$j]}; de=$1; ate=$2
  for k in GS GC; do roda TS_R3_T${j}_$k $de $ate $(cfg r3_C$j $k) DistribuicaoGARCH=1; done
done
for k in GS GC; do roda TS_R6_$k 2017.01.02 2024.12.30 $(cfg r6_C4 $k) DistribuicaoGARCH=1; done
for p in "L1 2005.01.03 2026.09.18" "L2 2017.01.02 2024.12.30"; do set -- $p
  for k in GS GC; do roda TS_${1}_$k $2 $3 $(cfg r3_C2 $k) DistribuicaoGARCH=1; done
done
# cenario de Almeida 2013-2016 (mesmos parametros do cenario_almeida.sh)
echo "== TS_cenA_1316_GARCH [$(date +%T)]" >> "$LOG"
bash "$S/rodar.sh" TS_cenA_1316_GARCH "$EA" PETR4_OFICIAL 2013.05.22 2016.05.24 50000 1:100 "$B" \
  ModoVolume=0 Fracao_Capital=0 SomenteCompra=false Custo_Por_Lado=0 StopLoss_Points=0 TakeProfit_Points=0 \
  Volume_Base=1000 UsarGARCH=true Estrategia=0 ModoLimiar=1 Limiar_Percentil=50 Janela_Estimacao=120 \
  IncluirConstante=false Limiar_Sinal=0 DistribuicaoGARCH=1 >> "$LOG" 2>&1

for r in $(sed -n 's/^== \(TS_[^ ]*\).*/\1/p' "$LOG"); do copia $r; done

# --- 2. comparacoes ------------------------------------------------------------
# As curvas normais e as gemeas vem da refacao (os numeros do TG).
for f in "$R"/testes/curva_*.csv; do cp "$f" "$COMUM/"; done
P="$OUT/testes/pares.txt"; : > "$P"
for x in R3_T1_GS R3_T2_GS R3_T2_GC R3_T3_GS R3_T3_GC R6_GS R6_GC L1_GS L1_GC L2_GS L2_GC; do
  echo "t_x_normal;TS_$x;$x" >> "$P"
  echo "t_x_gemea;TS_$x;${x}gemeo" >> "$P"
done
echo "t_x_normal;TS_cenA_1316_GARCH;cenA_1316_GARCH" >> "$P"
echo "t_x_gemea;TS_cenA_1316_GARCH;cenA_1316_ARIMA" >> "$P"
bash "$S/comparar.sh" "$P" "$OUT/testes/comparacoes.csv"
echo "fim $(date '+%F %T')"
