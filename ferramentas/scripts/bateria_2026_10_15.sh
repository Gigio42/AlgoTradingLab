#!/bin/bash
# Bateria de 15/10/2026 (protocolo: dados/resultados/bateria_2026-10-15/PROTOCOLO.md)
#
#   bash bateria_2026_10_15.sh <pasta_de_saida> <MetodoARIMA 0|1> [ativos]
#
#   0 = Hannan-Rissanen, 1 = maxima verossimilhanca condicional.
#   "ativos" = roda tambem a grade das quatro acoes (C1 T1 C2 T2 C3 T3); so e
#   necessario se a estimacao mudou (a analise por pares nao depende do
#   criterio de escolha).
#
# Etapas: otimizacoes (C1..C5) -> escolha pelo fator de recuperacao ->
# testes individuais (T1 T2 R6 T3 T5, fixas L1 L2, cenario de Almeida, MM) ->
# traco da GR de R6 -> copia -> comparacoes (camadas 3 e 1) -> anuais e recortes.
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
OUT="$1"; MET="$2"; ATIVOS="$3"
[ -n "$OUT" ] && [ "$MET" = 0 -o "$MET" = 1 ] || { echo "uso: $0 <saida> <0|1> [ativos]"; exit 1; }
mkdir -p "$OUT"/{calibracao,grades,escolhas,testes,relatorios_mt5,pareados}
OUT="$(cd "$OUT" && pwd)"
LOG="$OUT/execucao.log"; : > "$LOG"
FIX="MetodoARIMA=$MET DistribuicaoGARCH=0"
echo "inicio $(date '+%F %T') MetodoARIMA=$MET ativos=${ATIVOS:-nao}" | tee -a "$LOG"

# --- grades: as da rodada 3 (e da 4, para as acoes) + entradas fixadas ------
mkdir -p "$TRAB/sub15"
for g in arima filtro_abs filtro_pct targ ic ft_abs ft_pct; do
  { cat "$A/dados/resultados/rodada3_b3_oficial/grades/$g.txt"; echo "MetodoARIMA=$MET"; echo "DistribuicaoGARCH=0"; } \
    | tr -d '\r' > "$TRAB/sub15/r3_$g.txt"
  { cat "$A/dados/resultados/rodada4_multiativos/grades/$g.txt"; echo "MetodoARIMA=$MET"; echo "DistribuicaoGARCH=0"; } \
    | tr -d '\r' > "$TRAB/sub15/r4_$g.txt"
  cp "$TRAB/sub15/r3_$g.txt" "$TRAB/sub15/r4_$g.txt" "$OUT/grades/"
done
B="$TRAB/sub15/base.txt"
{ cat "$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"; echo "MetodoARIMA=$MET"; echo "DistribuicaoGARCH=0"; } | tr -d '\r' > "$B"
cp "$B" "$OUT/grades/base_testes.txt"
M="$A/dados/resultados/rodada3_b3_oficial/testes/in_mm.txt"

[ -d "$TRAB/g" ] && mv "$TRAB/g" "$TRAB/g_antigo_$(date +%s)"

# --- 1. otimizacoes ----------------------------------------------------------
otim(){ # otim <janela> <simbolo> <de> <ate> <prefixo_grade> [proventos]
  local j=$1 sim=$2 de=$3 ate=$4 pre=$5 prov=${6:-PETR4}
  for g in arima filtro_abs filtro_pct targ ic ft_abs ft_pct; do
    sed "s|^Arquivo_Proventos=.*|Arquivo_Proventos=proventos_${prov}.csv|" "$TRAB/sub15/${pre}_$g.txt" > "$TRAB/sub15/x_${prov}_$g.txt"
    bash "$S/otimizar.sh" "$j" "$sim" "$de" "$ate" "$TRAB/sub15/x_${prov}_$g.txt" >> "$LOG" 2>&1
  done
}
if [ "$ATIVOS" = ativos ]; then
  JAN=("C1 2004.01.02 2006.12.30" "T1 2007.01.02 2011.12.30" "C2 2010.01.04 2012.12.29"
       "T2 2013.01.02 2016.12.30" "C3 2022.01.03 2024.12.31" "T3 2025.01.02 2026.09.19")
  for at in PETR4 VALE3 USIM5 POMO4; do for j in "${JAN[@]}"; do set -- $j
    otim "$1" "${at}_OFICIAL" "$2" "$3" r4 "$at"; done; done
else
  otim C1 PETR4_OFICIAL 2004.01.02 2006.12.30 r3
  otim C2 PETR4_OFICIAL 2010.01.04 2012.12.29 r3
  otim C3 PETR4_OFICIAL 2022.01.03 2024.12.31 r3
fi
otim C4 PETR4_OFICIAL 2014.01.02 2016.12.30 r3
otim C5 PETR4_OFICIAL 2017.01.02 2019.12.30 r3
for d in "$TRAB"/g/*_OFICIAL_*; do
  n=$(basename "$d" | sed 's/_OFICIAL//')
  f=$(ls "$d" | head -1); [ -n "$f" ] || continue
  { head -1 "$d/$f"; for x in "$d"/res_*; do sed -n 2p "$x"; done; } | tr -d '\r' > "$OUT/calibracao/$n.csv"
  echo "$n: $(( $(wc -l < "$OUT/calibracao/$n.csv") - 1 )) passagens" | tee -a "$LOG"
done
echo "otimizacoes ok $(date '+%F %T')" | tee -a "$LOG"

# --- 2. escolhas ---------------------------------------------------------------
for j in 1 2 3 4 5; do
  bash "$S/escolher_rf.sh" "$OUT/calibracao/PETR4_C$j.csv" so_compra > "$OUT/escolhas/rf_C$j.txt"
  bash "$S/escolher.sh"    "$OUT/calibracao/PETR4_C$j.csv" so_compra > "$OUT/escolhas/sharpe_calmar_C$j.txt" 2>/dev/null
done
if [ "$ATIVOS" = ativos ]; then for at in PETR4 VALE3 USIM5 POMO4; do for j in 1 2 3; do
  bash "$S/parear.sh" "$OUT/calibracao/${at}_C$j.csv" "$OUT/calibracao/${at}_T$j.csv" > "$OUT/pareados/${at}_C${j}_T$j.csv"
done; done; fi
cfg(){ awk -v k="$2" '$1 == k { sub(/^[^|]*\| /, ""); print }' "$1"; }

# --- 3. testes individuais ------------------------------------------------------
EA='ARIMA-GARCH\ARIMA_GARCH_EA'; MMEA='MediasMoveis2\MediasMoveis2'
ROT=""
roda(){ local rot=$1 de=$2 ate=$3; shift 3; ROT="$ROT $rot"
  echo "== $rot $*" >> "$LOG"
  bash "$S/rodar.sh" "$rot" "$EA" PETR4_OFICIAL "$de" "$ate" 100000 1:1 "$B" $FIX "$@" >> "$LOG" 2>&1; }
mm(){ local rot=$1 de=$2 ate=$3; ROT="$ROT $rot"
  echo "== $rot" >> "$LOG"
  bash "$S/rodar.sh" "$rot" "$MMEA" PETR4_OFICIAL "$de" "$ate" 100000 1:1 "$M" \
    Volume_Fixo_Input=0 Fracao_Capital=0.95 SomenteCompra=true Custo_Por_Lado=0.0003 >> "$LOG" 2>&1; }
JT=("" "T1 2007.01.02 2011.12.30" "T2 2013.01.02 2016.12.30" "T3 2025.01.02 2026.09.19"
    "R6 2017.01.02 2024.12.30" "T5 2020.01.02 2021.12.30")
for j in 1 2 3 4 5; do
  set -- ${JT[$j]}; n=$1; de=$2; ate=$3; E="$OUT/escolhas/rf_C$j.txt"
  for k in GR GRgemeo AR; do roda N_${n}_$k $de $ate $(cfg "$E" $k); done
  mm N_${n}_MM $de $ate
done
E="$OUT/escolhas/rf_C2.txt"
for p in "L1 2005.01.03 2026.09.18" "L2 2017.01.02 2024.12.30"; do
  set -- $p; n=$1; de=$2; ate=$3
  for k in GR GRgemeo; do roda N_${n}_$k $de $ate $(cfg "$E" $k); done
  mm N_${n}_MM $de $ate
done

# cenario de Almeida (mesmas configuracoes fixas do cenario_almeida.sh)
COM="ModoVolume=0 Fracao_Capital=0 SomenteCompra=false Custo_Por_Lado=0 StopLoss_Points=0 TakeProfit_Points=0"
G1="UsarGARCH=true Estrategia=3 ModoLimiar=1 Limiar_Percentil=90 Vol_Alvo=0.01 ZerarNoVeto=true Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
A1="UsarGARCH=false Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
G2="UsarGARCH=true Estrategia=0 ModoLimiar=1 Limiar_Percentil=50 Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
cen(){ local rot=$1 de=$2 ate=$3 vol=$4; shift 4; ROT="$ROT $rot"; echo "== $rot" >> "$LOG"
  bash "$S/rodar.sh" "$rot" "$EA" PETR4_OFICIAL "$de" "$ate" 50000 1:100 "$B" $FIX $COM Volume_Base=$vol "$@" >> "$LOG" 2>&1; }
cen N_cenA_0711_GARCH 2007.01.01 2011.12.31  100 $G1
cen N_cenA_0711_ARIMA 2007.01.01 2011.12.31  100 $A1
cen N_cenA_1316_GARCH 2013.05.22 2016.05.24 1000 $G2
cen N_cenA_1316_ARIMA 2013.05.22 2016.05.24 1000 $A1
echo "testes ok $(date '+%F %T')" | tee -a "$LOG"

# --- 4. traco da GR de R6 (jul/2019 a jun/2021) ----------------------------------
GRR6=$(cfg "$OUT/escolhas/rf_C4.txt" GR | sed 's/UsarGARCH=[a-z]* *//')
for v in "GARCH true" "ARIMA false"; do set -- $v
  bash "$S/rodar.sh" "N_traco_$1" "$EA" PETR4_OFICIAL 2019.07.01 2021.06.30 100000 1:1 "$B" $FIX \
    UsarGARCH=$2 $GRR6 Arquivo_Traco=N_traco_$1 >> "$LOG" 2>&1
done
mkdir -p "$OUT/traco"; cp "$COMUM"/traco_N_traco_*.csv "$OUT/traco/" 2>/dev/null

# --- 5. copia (so os rotulos desta execucao) ----------------------------------
for r in $ROT; do
  cp "$COMUM/metricas_$r.csv" "$COMUM/curva_$r.csv" "$OUT/testes/" 2>>"$LOG"
  cp "$TRAB/rel/rel_$r.htm" "$TRAB/rel/rel_$r.png" "$OUT/relatorios_mt5/" 2>/dev/null
done

# --- 6. comparacoes: camada 3 (curva oficial) e camada 1 (curva pura) --------
# A curva "pura" troca a coluna estrategia pela coluna puro; o resto igual.
for r in $ROT; do
  [ -s "$COMUM/curva_$r.csv" ] || continue
  awk -F, 'BEGIN{OFS=","} NR==1{for(i=1;i<=NF;i++)h[$i]=i; print; next} {$h["estrategia"]=$h["puro"]; print}' \
    "$COMUM/curva_$r.csv" > "$COMUM/curva_${r}P.csv"
done
P3="$OUT/testes/pares.txt"; P1="$OUT/testes/pares_puro.txt"; : > "$P3"; : > "$P1"
for n in T1 T2 R6 T3 T5; do for x in GR:GRgemeo GR:AR GR:MM AR:MM GRgemeo:MM; do
  echo "$n;N_${n}_${x%:*};N_${n}_${x#*:}" >> "$P3"; echo "$n;N_${n}_${x%:*}P;N_${n}_${x#*:}P" >> "$P1"; done; done
for n in L1 L2; do for x in GR:GRgemeo GR:MM GRgemeo:MM; do
  echo "$n;N_${n}_${x%:*};N_${n}_${x#*:}" >> "$P3"; echo "$n;N_${n}_${x%:*}P;N_${n}_${x#*:}P" >> "$P1"; done; done
echo "cenA_1316;N_cenA_1316_GARCH;N_cenA_1316_ARIMA" >> "$P3"
bash "$S/comparar.sh" "$P3" "$OUT/testes/comparacoes_camada3.csv" >> "$LOG" 2>&1
bash "$S/comparar.sh" "$P1" "$OUT/testes/comparacoes_puro.csv" >> "$LOG" 2>&1

# --- 7. anuais e recortes (camada 1, pura) -------------------------------------
for n in T1 T2 R6 T3 T5; do
  bash "$S/anual.sh" "$OUT/testes" N_${n}_ GR:GR:puro GRgemeo:GRgemeo:puro AR:AR:puro MM:MM:puro BH:GR:buyhold Selic:GR:selic > "$OUT/testes/anual_$n.csv"
done
for n in L1 L2; do
  bash "$S/anual.sh" "$OUT/testes" N_${n}_ GR:GR:puro GRgemeo:GRgemeo:puro MM:MM:puro BH:GR:buyhold Selic:GR:selic > "$OUT/testes/anual_$n.csv"
done
( cd "$OUT/testes" && COL=puro bash "$S/recorte_ano.sh" 2008 curva_N_T1 GR GRgemeo AR MM > ../recorte_2008.txt
  COL=puro bash "$S/recorte_ano.sh" 2020 curva_N_R6 GR GRgemeo AR MM > ../recorte_2020_R6.txt
  COL=puro bash "$S/recorte_ano.sh" 2020 curva_N_T5 GR GRgemeo AR MM > ../recorte_2020_T5.txt
  COL=puro bash "$S/recorte_ano.sh" 2021 curva_N_T5 GR GRgemeo AR MM > ../recorte_2021_T5.txt )
echo "fim $(date '+%F %T')" | tee -a "$LOG"
