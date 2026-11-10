#!/bin/bash
# janela_garch_1000.sh <pasta_de_saida> [calibrar] [testar]
#
# Estudo de 02/11/2026: a parte principal do Cap. III (só PETR4) com o ARIMA em
# 240 pregões e o GARCH sobre os 1000 resíduos mais recentes. Mesmo molde do
# janelas_240_500.sh (26/10), com aquecimento de quatro anos e sem as outras
# ações. A otimização de 2004–2006, os testes de 2007–2011 e o período longo
# (desde 03/01/2005) usam PETR4_DESDE1999 (série oficial estendida a 1999,
# serie_petr4_desde1999.sh; decisão do autor em 02/11/2026): no PETR4_OFICIAL o
# 1000º pregão é 10/01/2007. Depois de 2003 os dois símbolos são idênticos.
# JG=<n> troca a janela do GARCH (padrão 1000).
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
OUT="$1"; [ -n "$OUT" ] || { echo "uso: $0 <pasta_de_saida> [calibrar] [testar]"; exit 1; }
shift; ETAPAS="${*:-calibrar testar}"
JG="${JG:-1000}"
mkdir -p "$OUT"/{grades,calibracao,escolhas,testes,relatorios_mt5}
OUT="$(cd "$OUT" && pwd)"
R3="$A/dados/resultados/rodada3_b3_oficial/grades"
REF="$A/dados/resultados/refeito_2026-10-05/testes"
SUBS="arima filtro_abs filtro_pct targ ft_abs ft_pct"

epoca(){ date -u -d "${1//./-}" +%s; }

# nome  operação_de  operação_até  testador_de  símbolo
JANELAS=("C4 2014.01.02 2016.12.30 2010.01.04 PETR4_OFICIAL" "C2 2010.01.04 2012.12.29 2006.01.02 PETR4_OFICIAL"
         "C3 2022.01.03 2024.12.31 2018.01.02 PETR4_OFICIAL" "C1 2004.01.02 2006.12.29 2000.01.03 PETR4_DESDE1999")

fixos(){ printf 'Janela_GARCH=%s\nInicio_Operacao=%s\nMetodoARIMA=0\nSelecaoPorBIC=false\nDistribuicaoGARCH=0\nArquivo_Traco=\n' "$JG" "$(epoca "$1")"; }
explicitar(){ awk -F= '!/\|\|/ && NF==2 && $2 ~ /^(-?[0-9.]+|true|false)$/ {
    if ($2=="true"||$2=="false") print $1"="$2"||false||0||true||N"; else print $1"="$2"||"$2"||1||"$2"||N"; next } { print }'; }
grade(){ # grade <arquivo_origem> <data_inicio>
  { tr -d '\r' < "$1" | sed -e 's/^Janela_Estimacao=.*/Janela_Estimacao=240/' \
    -e "s|^Arquivo_Proventos=.*|Arquivo_Proventos=proventos_PETR4.csv|"
    fixos "$2"; } | explicitar; }
pular(){ [[ " $PULAR " == *" $1 "* ]]; }
otimiza(){ rm -f "$N/MQL5/Profiles/Tester/ARIMA_GARCH_EA.set"; bash "$S/otimizar.sh" "$@"; }

if [[ " $ETAPAS " == *" calibrar "* ]]; then
  echo "calibrar: inicio $(date '+%F %T')"
  G="$TRAB/g"; [ -d "$G" ] && [ -z "$PULAR" ] && mv "$G" "$TRAB/g_antigo_$(date +%s)"
  mkdir -p "$TRAB/sub1000"
  for j in "${JANELAS[@]}"; do set -- $j
    for g in $SUBS; do
      f="$TRAB/sub1000/PETR4_$1_$g.txt"; grade "$R3/$g.txt" "$2" > "$f"
      [ "$1" = C4 ] && cp "$f" "$OUT/grades/r3_$g.txt"
      pular "PETR4_$1" || otimiza "$1" "$5" "$4" "$3" "$f"
    done
  done
  for d in "$TRAB"/g/PETR4_OFICIAL_* "$TRAB"/g/PETR4_DESDE1999_*; do
    [ -d "$d" ] || continue
    n=$(basename "$d" | sed 's/_OFICIAL//; s/_DESDE1999//')
    f=$(ls "$d" | head -1); [ -n "$f" ] || continue
    { head -1 "$d/$f"; for x in "$d"/res_*; do sed -n 2p "$x"; done; } | tr -d '\r' > "$OUT/calibracao/$n.csv"
    echo "$n: $(( $(wc -l < "$OUT/calibracao/$n.csv") - 1 )) passagens"
  done
  echo "calibrar: fim $(date '+%F %T')"
fi

if [[ " $ETAPAS " == *" testar "* ]]; then
  echo "testar: inicio $(date '+%F %T')"
  B="$TRAB/in_240_${JG}_base.txt"
  tr -d '\r' < "$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt" | sed 's/^Janela_Estimacao=.*/Janela_Estimacao=240/' > "$B"
  EA='robos\ARIMA-GARCH\ARIMA_GARCH_EA'
  LOG="$OUT/testes/execucao.log"; : > "$LOG"

  for j in 1 2 3; do bash "$S/escolher.sh" "$OUT/calibracao/PETR4_C$j.csv" so_compra > "$OUT/escolhas/r3_C$j.txt"; done
  bash "$S/escolher.sh" "$OUT/calibracao/PETR4_C4.csv" so_compra > "$OUT/escolhas/r6_C4.txt"
  cfg(){ awk -v k="$2" '$1 == k { sub(/^[^|]*\| /, ""); print }' "$1"; }
  roda(){ local rot=$1 de=$2 ate=$3 td=$4; shift 4
    echo "== $rot $*" >> "$LOG"
    # o rodar.sh não apaga o resultado anterior com o mesmo rótulo (o estudo de
    # 500 usou os mesmos): sem isto, um teste que falhe copiaria o antigo
    rm -f "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv"
    ESPERA=3600 bash "$S/rodar.sh" "$rot" "$EA" "${SIM:-PETR4_OFICIAL}" "$td" "$ate" 100000 1:1 "$B" \
      Janela_GARCH=$JG Inicio_Operacao=$(epoca "$de") MetodoARIMA=0 SelecaoPorBIC=false DistribuicaoGARCH=0 Arquivo_Traco= \
      "$@" >> "$LOG" 2>&1; }

  JT=("" "2007.01.02 2011.12.30 2003.01.02" "2013.01.02 2016.12.30 2009.01.02" "2025.01.02 2026.09.19 2021.01.04")
  for j in 1 2 3; do
    E="$OUT/escolhas/r3_C$j.txt"; SIM=PETR4_OFICIAL; [ $j = 1 ] && SIM=PETR4_DESDE1999
    for k in GS GSgemeo GC GCgemeo AS; do roda R3_T${j}_$k ${JT[$j]} $(cfg "$E" $k); done
  done
  SIM=PETR4_OFICIAL
  E="$OUT/escolhas/r6_C4.txt"
  rm -f "$COMUM/traco_R6_GS.csv"
  roda R6_GS 2017.01.02 2024.12.30 2013.01.02 $(cfg "$E" GS) Arquivo_Traco=R6_GS
  for k in GSgemeo GC GCgemeo; do roda R6_$k 2017.01.02 2024.12.30 2013.01.02 $(cfg "$E" $k); done
  roda R6_ARIMA 2017.01.02 2024.12.30 2013.01.02 $(cfg "$E" AS)
  E="$OUT/escolhas/r3_C2.txt"
  for k in GS GSgemeo GC GCgemeo; do
    SIM=PETR4_DESDE1999; roda L1_$k 2005.01.03 2026.09.18 2001.01.02 $(cfg "$E" $k); SIM=PETR4_OFICIAL
    roda L2_$k 2017.01.02 2024.12.30 2013.01.02 $(cfg "$E" $k)
  done

  rotulos=$(sed -n 's/^== \([^ ]*\).*/\1/p' "$LOG")
  for r in $rotulos; do
    cp "$COMUM/metricas_$r.csv" "$COMUM/curva_$r.csv" "$OUT/testes/"
    cp "$TRAB/rel/rel_$r.htm" "$TRAB/rel/rel_$r.png" "$OUT/relatorios_mt5/" 2>/dev/null
  done
  for r in R3_T1_MM R3_T2_MM R3_T3_MM R6_MM L2_MM; do cp "$REF/metricas_$r.csv" "$REF/curva_$r.csv" "$OUT/testes/"; done
  mkdir -p "$OUT/traco"; cp "$COMUM/traco_R6_GS.csv" "$OUT/traco/"
  echo "testar: fim $(date '+%F %T')"
fi
