#!/bin/bash
# Segunda metade da refacao de 05/10/2026 (a primeira e refazer_calibracoes.sh).
# Protocolo: dados/resultados/refeito_2026-10-05/PROTOCOLO.md
#
#  1. pareia calibracao x teste de cada ativo e janela (parear.sh)
#  2. escolhe as configuracoes na calibracao (escolher.sh)
#  3. roda os testes individuais (com curva diaria):
#       rodada 3: T1, T2, T3 com GS, GC, gemeas, AS, AC e MM
#       rodada 6: 2017-2024 com as escolhas de C4
#       rodada 5: periodos longos com GS e GC de C2 (2010-2012) e gemeas
#       cenario de Almeida (configuracoes fixas do cenario_almeida.sh)
#       traco de demonstracao com a nova GS da rodada 6
#  4. testes pareados entre curvas (comparar.sh) e retornos anuais (anual.sh)
#
# Uso: bash refazer_testes.sh <pasta_de_saida>   (a mesma da 1a metade)
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
OUT="$1"; [ -d "$OUT/calibracao" ] || { echo "uso: $0 <pasta_de_saida com calibracao/>"; exit 1; }
B="$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"
M="$A/dados/resultados/rodada3_b3_oficial/testes/in_mm.txt"
EA='ARIMA-GARCH\ARIMA_GARCH_EA'; MMEA='MediasMoveis2\MediasMoveis2'
mkdir -p "$OUT/pareados" "$OUT/escolhas" "$OUT/testes" "$OUT/relatorios_mt5"
LOG="$OUT/testes/execucao.log"; : > "$LOG"
echo "inicio $(date '+%F %T')"

# --- 1. pareados ------------------------------------------------------------
for a in PETR4 VALE3 USIM5 POMO4; do for j in 1 2 3; do
  bash "$S/parear.sh" "$OUT/calibracao/${a}_C$j.csv" "$OUT/calibracao/${a}_T$j.csv" > "$OUT/pareados/${a}_C${j}_T$j.csv"
done; done

# --- 2. escolhas ------------------------------------------------------------
for j in 1 2 3; do bash "$S/escolher.sh" "$OUT/calibracao/PETR4_C$j.csv" so_compra > "$OUT/escolhas/r3_C$j.txt"; done
bash "$S/escolher.sh" "$OUT/calibracao/PETR4_C4.csv" so_compra > "$OUT/escolhas/r6_C4.txt"
for a in PETR4 VALE3 USIM5 POMO4; do for j in 1 2 3; do
  bash "$S/escolher.sh" "$OUT/calibracao/${a}_C$j.csv" > "$OUT/escolhas/r4_${a}_C$j.txt"
done; done
cfg(){ awk -v k="$2" '$1 == k { sub(/^[^|]*\| /, ""); print }' "$1"; }

roda(){ local rot=$1 de=$2 ate=$3; shift 3
  echo "== $rot $*" >> "$LOG"
  bash "$S/rodar.sh" "$rot" "$EA" PETR4_OFICIAL "$de" "$ate" 100000 1:1 "$B" "$@" >> "$LOG" 2>&1; }

# --- 3a. rodada 3 -----------------------------------------------------------
JT=("" "2007.01.02 2011.12.30" "2013.01.02 2016.12.30" "2025.01.02 2026.09.19")
for j in 1 2 3; do
  set -- ${JT[$j]}; de=$1; ate=$2; E="$OUT/escolhas/r3_C$j.txt"
  for k in GS GSgemeo GC GCgemeo AS AC; do roda R3_T${j}_$k $de $ate $(cfg "$E" $k); done
  echo "== R3_T${j}_MM" >> "$LOG"
  bash "$S/rodar.sh" R3_T${j}_MM "$MMEA" PETR4_OFICIAL $de $ate 100000 1:1 "$M" >> "$LOG" 2>&1
done

# --- 3b. rodada 6 (2017-2024, escolhas de C4) -------------------------------
E="$OUT/escolhas/r6_C4.txt"
for k in GS GSgemeo GC GCgemeo; do roda R6_$k 2017.01.02 2024.12.30 $(cfg "$E" $k); done
roda R6_ARIMA 2017.01.02 2024.12.30 $(cfg "$E" AS)
echo "== R6_MM" >> "$LOG"
bash "$S/rodar.sh" R6_MM "$MMEA" PETR4_OFICIAL 2017.01.02 2024.12.30 100000 1:1 "$M" \
  Volume_Fixo_Input=0 Fracao_Capital=0.95 SomenteCompra=true Custo_Por_Lado=0.0003 >> "$LOG" 2>&1

# --- 3c. rodada 5 (periodos longos, GS e GC de C2) --------------------------
E="$OUT/escolhas/r3_C2.txt"
for p in "L1 2005.01.03 2026.09.18" "L2 2017.01.02 2024.12.30"; do
  set -- $p; n=$1; de=$2; ate=$3
  for k in GS GSgemeo GC GCgemeo; do roda ${n}_$k $de $ate $(cfg "$E" $k); done
  echo "== ${n}_MM" >> "$LOG"
  bash "$S/rodar.sh" ${n}_MM "$MMEA" PETR4_OFICIAL $de $ate 100000 1:1 "$M" \
    Volume_Fixo_Input=0 Fracao_Capital=0.95 SomenteCompra=true Custo_Por_Lado=0.0003 >> "$LOG" 2>&1
done

# --- 3d. cenario de Almeida e traco -----------------------------------------
bash "$S/cenario_almeida.sh" > "$OUT/testes/cenario_almeida.txt" 2>&1
bash "$S/gerar_traco.sh" "$(cfg "$OUT/escolhas/r6_C4.txt" GS)" "$OUT/traco_demo" >> "$LOG" 2>&1

# --- copia o que o EA gravou ------------------------------------------------
# So os rotulos rodados AGORA: um glob como L1_* pegaria tambem os arquivos
# de rodadas antigas que ficaram em Common (aconteceu em 06/10 com L1_GF etc.)
rotulos=$(sed -n 's/^== \([^ ]*\).*/\1/p' "$LOG")
rotulos="$rotulos cenA_0711_GARCH cenA_0711_ARIMA cenA_0810_GARCH cenA_0810_ARIMA cenA_1316_GARCH cenA_1316_ARIMA"
for r in $rotulos; do
  cp "$COMUM/metricas_$r.csv" "$COMUM/curva_$r.csv" "$OUT/testes/"
  cp "$TRAB/rel/rel_$r.htm" "$TRAB/rel/rel_$r.png" "$OUT/relatorios_mt5/" 2>/dev/null
done

# --- 4. comparacoes e anuais ------------------------------------------------
P="$OUT/testes/pares.txt"; : > "$P"
for j in 1 2 3; do for x in GS:GSgemeo GC:GCgemeo GS:AS GC:AS GS:MM GC:MM AS:MM; do
  echo "T$j;R3_T${j}_${x%:*};R3_T${j}_${x#*:}" >> "$P"; done; done
for x in GS:GSgemeo GC:GCgemeo GS:ARIMA GC:ARIMA GS:MM GC:MM ARIMA:MM; do
  echo "2017-2024;R6_${x%:*};R6_${x#*:}" >> "$P"; done
for n in L1 L2; do for x in GS:GSgemeo GC:GCgemeo GS:MM GC:MM GSgemeo:MM; do
  echo "$n;${n}_${x%:*};${n}_${x#*:}" >> "$P"; done; done
echo "cenA_1316;cenA_1316_GARCH;cenA_1316_ARIMA" >> "$P"
bash "$S/comparar.sh" "$P" "$OUT/testes/comparacoes.csv"

for j in 1 2 3; do
  bash "$S/anual.sh" "$OUT/testes" R3_T${j}_ GS:GS BH:GS:buyhold Selic:GS:selic GC:GC AS:AS MM:MM > "$OUT/testes/anual_R3_T$j.csv"
done
for n in L1 L2; do
  bash "$S/anual.sh" "$OUT/testes" ${n}_ GS:GS GSgemeo:GSgemeo GC:GC GCgemeo:GCgemeo MM:MM BH:GS:buyhold Selic:GS:selic > "$OUT/testes/anual_$n.csv"
done
bash "$S/anual.sh" "$OUT/testes" R6_ GS:GS GSgemeo:GSgemeo GC:GC GCgemeo:GCgemeo ARIMA:ARIMA MM:MM BH:GS:buyhold Selic:GS:selic > "$OUT/testes/anual_R6.csv"
echo "fim $(date '+%F %T')"
