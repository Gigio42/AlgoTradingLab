#!/bin/bash
# assimetricos.sh <pasta_de_saida> [grades] [escolhas] [testes]
#
# Estudo de 18/11/2026 (PROTOCOLO.md da pasta de saida): GARCH sobre 500
# residuos com GJR, EGARCH, t de Student, janela expansiva do ARIMA e BIC,
# um por vez e todos juntos. Para cada variante e cada calibracao, a grade de
# 156 configuracoes so compra da rodada 3 (ARIMA 240); GS, GC e a gemea do GS
# escolhidos pelo escolher.sh; e os testes fora da amostra, mais as medias
# moveis uma vez por periodo. Tudo no PETR4_DESDE1999, testador desde 03/01/2000
# e Inicio_Operacao no inicio de cada periodo.
# VARS="base gjr ..." e CALS="C4 C0 ..." restringem; PULAR="gjr_C4 ..." retoma
# uma bateria interrompida (grades ja gravadas tambem sao puladas).
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
OUT="$1"; [ -n "$OUT" ] || { echo "uso: $0 <pasta_de_saida> [grades] [escolhas] [testes]"; exit 1; }
shift; ETAPAS="${*:-grades escolhas testes}"
mkdir -p "$OUT"/{grades,calibracao,escolhas,testes}
OUT="$(cd "$OUT" && pwd)"
R3="$A/dados/resultados/rodada3_b3_oficial/grades"
SUBS="arima filtro_abs filtro_pct targ ft_abs ft_pct"
SIM=PETR4_DESDE1999; INICIO=2000.01.03
EA='robos\ARIMA-GARCH\ARIMA_GARCH_EA'; MMEA='robos\MediasMoveis2\MediasMoveis2'
VARS="${VARS:-base gjr egarch t bic exp gjr_tudo egarch_tudo}"
CALS="${CALS:-C4 C0 C1 C2 C3}"

epoca(){ date -u -d "${1//./-}" +%s; }

# calibracao: operacao_de operacao_ate
declare -A C=([C0]="2002.01.02 2004.12.30" [C1]="2004.01.02 2006.12.29" [C2]="2010.01.04 2012.12.28"
              [C4]="2014.01.02 2016.12.30" [C3]="2022.01.03 2024.12.31")
# teste: operacao_de operacao_ate calibracao
declare -A T=([P0510]="2005.01.03 2010.12.30 C0" [T1]="2007.01.02 2011.12.30 C1" [T2]="2013.01.02 2016.12.30 C2"
              [R6]="2017.01.02 2024.12.30 C4" [T3]="2025.01.02 2026.09.19 C3" [L1]="2005.01.03 2026.09.18 C2")
TESTES_DE(){ case $1 in C0) echo P0510;; C1) echo T1;; C2) echo "T2 L1";; C4) echo R6;; C3) echo T3;; esac; }

variante(){ # inputs fixos de cada variante (PROTOCOLO, secao 2)
  local m=0 d=0 b=false e=0
  case $1 in
    base) ;; gjr) m=1;; egarch) m=2;; t) d=1;; bic) b=true;; exp) e=$(epoca $INICIO);;
    gjr_tudo) m=1; d=1; b=true; e=$(epoca $INICIO);;
    egarch_tudo) m=2; d=1; b=true; e=$(epoca $INICIO);;
    *) echo "variante desconhecida: $1" >&2; exit 1;;
  esac
  echo "ModeloGARCH=$m DistribuicaoGARCH=$d SelecaoPorBIC=$b Inicio_Janela_Expansiva=$e"; }
fixos(){ # fixos <variante> <operacao_de>
  printf 'Janela_GARCH=500\nInicio_Operacao=%s\nMetodoARIMA=0\nArquivo_Traco=\n' "$(epoca "$2")"
  variante "$1" | tr ' ' '\n'; }
explicitar(){ awk -F= '!/\|\|/ && NF==2 && $2 ~ /^(-?[0-9.]+|true|false)$/ {
    if ($2=="true"||$2=="false") print $1"="$2"||false||0||true||N"; else print $1"="$2"||"$2"||1||"$2"||N"; next } { print }'; }
grade(){ # grade <sub-grade> <variante> <operacao_de>
  { tr -d '\r' < "$1" | grep -v '^K_Confianca=' | sed -e 's/^Janela_Estimacao=.*/Janela_Estimacao=240/' \
    -e "s|^Arquivo_Proventos=.*|Arquivo_Proventos=proventos_PETR4.csv|"
    fixos "$2" "$3"; } | explicitar; }
pular(){ [[ " $PULAR " == *" $1 "* ]]; }
otimiza(){ rm -f "$N/MQL5/Profiles/Tester/ARIMA_GARCH_EA.set"; bash "$S/otimizar.sh" "$@"; }
LOG="$OUT/execucao.log"
diz(){ echo "$*" | tee -a "$LOG"; }

rodar_grades(){ # rodar_grades <calibracao>
  local cal=$1 v; set -- ${C[$cal]}; local de=$1 ate=$2
  for v in $VARS; do
    local dest="$OUT/calibracao/$v/PETR4_$cal.csv"
    if pular "${v}_$cal" || [ -s "$dest" ]; then diz "grade $v $cal: ja existe, pulada"; continue; fi
    local G="$TRAB/g" t0=$(date +%s); rm -rf "$G"; mkdir -p "$TRAB/subas" "$OUT/calibracao/$v"
    for g in $SUBS; do
      local f="$TRAB/subas/${v}_${cal}_$g.txt"; grade "$R3/$g.txt" "$v" "$de" > "$f"
      [ "$v$cal" = baseC4 ] && cp "$f" "$OUT/grades/base_C4_$g.txt"
      otimiza "${v}_$cal" "$SIM" "$INICIO" "$ate" "$f" >> "$LOG" 2>&1
    done
    local d="$G/${SIM}_${v}_$cal" f1; f1=$(ls "$d" | head -1)
    { head -1 "$d/$f1"; for x in "$d"/res_*; do sed -n 2p "$x"; done; } | tr -d '\r' > "$dest"
    diz "grade $v $cal: $(( $(wc -l < "$dest") - 1 )) passagens em $(( $(date +%s)-t0 )) s"
  done; }

rodar_escolhas(){ local cal=$1 v
  for v in $VARS; do
    local f="$OUT/calibracao/$v/PETR4_$cal.csv"; [ -s "$f" ] || continue
    bash "$S/escolher.sh" "$f" so_compra > "$OUT/escolhas/${v}_$cal.txt"
  done; }

um_teste(){ # um_teste <rotulo> <variante> <teste> <configuracao...>
  local rot=$1 v=$2 tst=$3; shift 3; set -- ${T[$tst]} "$@"; local de=$1 ate=$2; shift 3
  [ -s "$OUT/testes/metricas_$rot.csv" ] && { diz "teste $rot: ja existe, pulado"; return; }
  rm -f "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv" "$N/MQL5/Profiles/Tester/ARIMA_GARCH_EA.set"
  local B="$TRAB/in_as_base.txt" t0=$(date +%s)
  tr -d '\r' < "$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt" | grep -v '^K_Confianca=' \
    | sed 's/^Janela_Estimacao=.*/Janela_Estimacao=240/' > "$B"
  echo "== $rot $v $tst $*" >> "$LOG"
  ESPERA=10800 bash "$S/rodar.sh" "$rot" "$EA" "$SIM" "$INICIO" "$ate" 100000 1:1 "$B" \
    Janela_GARCH=500 Inicio_Operacao=$(epoca "$de") MetodoARIMA=0 Arquivo_Traco= Arquivo_Proventos=proventos_PETR4.csv \
    $(variante "$v") $(printf '%s\n' "$@" | grep -v '^K_Confianca=') >> "$LOG" 2>&1
  cp "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv" "$OUT/testes/" 2>/dev/null || diz "SEM SAIDA $rot"
  diz "teste $rot: $(( $(date +%s)-t0 )) s"; }

teste_mm(){ local tst=$1; set -- ${T[$tst]}; local rot="AS_MM_$tst"
  [ -s "$OUT/testes/metricas_$rot.csv" ] && return
  rm -f "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv" "$N/MQL5/Profiles/Tester/MediasMoveis2.set"
  echo "== $rot" >> "$LOG"
  bash "$S/rodar.sh" "$rot" "$MMEA" "$SIM" "$1" "$2" 100000 1:1 "$A/dados/resultados/rodada3_b3_oficial/testes/in_mm.txt" \
    Volume_Fixo_Input=0 Fracao_Capital=0.95 SomenteCompra=true Custo_Por_Lado=0.0003 Arquivo_Proventos=proventos_PETR4.csv >> "$LOG" 2>&1
  cp "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv" "$OUT/testes/" 2>/dev/null || diz "SEM SAIDA $rot"; }

rodar_testes(){ local cal=$1 v tst esc
  for tst in $(TESTES_DE $cal); do
    teste_mm $tst
    for v in $VARS; do
      esc="$OUT/escolhas/${v}_$cal.txt"; [ -s "$esc" ] || continue
      for r in GS GC GSgemeo; do
        cfg=$(awk -v r=$r '$1 == r { sub(/^[^|]*\| /, ""); print }' "$esc")
        [ -n "$cfg" ] && um_teste "AS_${v}_${tst}_$r" "$v" "$tst" $cfg
      done
    done
  done; }

diz "inicio $(date '+%F %T') | etapas: $ETAPAS | variantes: $VARS | calibracoes: $CALS"
for cal in $CALS; do
  [[ " $ETAPAS " == *" grades "* ]] && rodar_grades $cal
  [[ " $ETAPAS " == *" escolhas "* ]] && rodar_escolhas $cal
  [[ " $ETAPAS " == *" testes "* ]] && rodar_testes $cal
done
diz "fim $(date '+%F %T')"
