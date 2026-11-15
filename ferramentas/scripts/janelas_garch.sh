#!/bin/bash
# janelas_garch.sh <pasta_de_saida> [grades] [traco]
#
# Estudo de 13/11/2026 (PROTOCOLO.md da pasta de saída): a mesma grade de 156
# configurações só-compra com o ARIMA em 240 e o GARCH sobre 120, 240, 500 e 1000
# resíduos, em quatro pares otimização -> teste da PETR4, e o traço por barra de
# uma configuração fixa (o GS de 2017-2024 do TG) nas quatro janelas e no TG.
# Mesmo molde do janela_garch_1000.sh (02/11). Aquecimento de quatro anos em tudo.
# JGS="120 240 500 1000" e PERIODOS="C4 R6 ..." restringem a bateria;
# PULAR="1000_C4 ..." retoma uma bateria interrompida.
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
OUT="$1"; [ -n "$OUT" ] || { echo "uso: $0 <pasta_de_saida> [grades] [traco]"; exit 1; }
shift; ETAPAS="${*:-grades traco}"
JGS="${JGS:-120 240 500 1000}"
mkdir -p "$OUT"/{grades,calibracao,traco,testes}
OUT="$(cd "$OUT" && pwd)"
R3="$A/dados/resultados/rodada3_b3_oficial/grades"
SUBS="arima filtro_abs filtro_pct targ ft_abs ft_pct"

epoca(){ date -u -d "${1//./-}" +%s; }

# nome  operação_de  operação_até  testador_de  símbolo
declare -A P=(
  [C4]="2014.01.02 2016.12.30 2010.01.04 PETR4_OFICIAL"   [R6]="2017.01.02 2024.12.30 2013.01.02 PETR4_OFICIAL"
  [C2]="2010.01.04 2012.12.29 2006.01.02 PETR4_OFICIAL"   [T2]="2013.01.02 2016.12.30 2009.01.02 PETR4_OFICIAL"
  [C3]="2022.01.03 2024.12.31 2018.01.02 PETR4_OFICIAL"   [T3]="2025.01.02 2026.09.19 2021.01.04 PETR4_OFICIAL"
  [C1]="2004.01.02 2006.12.29 2000.01.03 PETR4_DESDE1999" [T1]="2007.01.02 2011.12.30 2003.01.02 PETR4_DESDE1999")
PERIODOS="${PERIODOS:-C4 R6 C2 T2 C3 T3 C1 T1}"

fixos(){ printf 'Janela_GARCH=%s\nInicio_Operacao=%s\nMetodoARIMA=0\nSelecaoPorBIC=false\nDistribuicaoGARCH=0\nArquivo_Traco=\n' "$1" "$(epoca "$2")"; }
explicitar(){ awk -F= '!/\|\|/ && NF==2 && $2 ~ /^(-?[0-9.]+|true|false)$/ {
    if ($2=="true"||$2=="false") print $1"="$2"||false||0||true||N"; else print $1"="$2"||"$2"||1||"$2"||N"; next } { print }'; }
grade(){ # grade <arquivo_origem> <janela_garch> <data_inicio>
  { tr -d '\r' < "$1" | sed -e 's/^Janela_Estimacao=.*/Janela_Estimacao=240/' \
    -e "s|^Arquivo_Proventos=.*|Arquivo_Proventos=proventos_PETR4.csv|"
    fixos "$2" "$3"; } | explicitar; }
pular(){ [[ " $PULAR " == *" $1 "* ]]; }
otimiza(){ rm -f "$N/MQL5/Profiles/Tester/ARIMA_GARCH_EA.set"; bash "$S/otimizar.sh" "$@"; }

if [[ " $ETAPAS " == *" grades "* ]]; then
  echo "grades: inicio $(date '+%F %T')"
  mkdir -p "$TRAB/subjg"
  # o par principal (C4, R6) nas quatro janelas antes dos outros pares
  for per in $PERIODOS; do for jg in $JGS; do
    pular "${jg}_$per" && continue
    set -- ${P[$per]}
    G="$TRAB/g"; rm -rf "$G"
    for g in $SUBS; do
      f="$TRAB/subjg/${jg}_${per}_$g.txt"; grade "$R3/$g.txt" "$jg" "$1" > "$f"
      [ "$jg$per" = 240C4 ] && sed 's/^Janela_GARCH=.*/Janela_GARCH=<janela>||<janela>||1||<janela>||N/' "$f" > "$OUT/grades/r3_$g.txt"
      otimiza "$per" "$4" "$3" "$2" "$f"
    done
    d="$G/${4}_$per"; mkdir -p "$OUT/calibracao/$jg"
    f=$(ls "$d" | head -1)
    { head -1 "$d/$f"; for x in "$d"/res_*; do sed -n 2p "$x"; done; } | tr -d '\r' > "$OUT/calibracao/$jg/PETR4_$per.csv"
    echo "JG=$jg $per: $(( $(wc -l < "$OUT/calibracao/$jg/PETR4_$per.csv") - 1 )) passagens"
  done; done
  echo "grades: fim $(date '+%F %T')"
fi

if [[ " $ETAPAS " == *" traco "* ]]; then
  echo "traco: inicio $(date '+%F %T')"
  B="$TRAB/in_jg_base.txt"
  tr -d '\r' < "$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt" | sed 's/^Janela_Estimacao=.*/Janela_Estimacao=240/' > "$B"
  EA='robos\ARIMA-GARCH\ARIMA_GARCH_EA'
  LOG="$OUT/testes/execucao.log"; : > "$LOG"
  CFG=$(awk '$1 == "GS" { sub(/^[^|]*\| /, ""); print }' "$A/dados/resultados/refeito_2026-10-05/escolhas/r6_C4.txt")
  for jg in 0 $JGS; do
    rot="JG_$jg"
    echo "== $rot $CFG" >> "$LOG"
    rm -f "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv" "$COMUM/traco_$rot.csv"
    ESPERA=3600 bash "$S/rodar.sh" "$rot" "$EA" PETR4_OFICIAL 2013.01.02 2024.12.30 100000 1:1 "$B" \
      Janela_GARCH=$jg Inicio_Operacao=$(epoca 2017.01.02) MetodoARIMA=0 SelecaoPorBIC=false DistribuicaoGARCH=0 \
      Arquivo_Traco=$rot $CFG >> "$LOG" 2>&1
    cp "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv" "$OUT/testes/"
    cp "$COMUM/traco_$rot.csv" "$OUT/traco/"
  done
  echo "traco: fim $(date '+%F %T')"
fi
