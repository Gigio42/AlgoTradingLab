#!/bin/bash
# filtro_ajuste_500.sh <pasta_de_saida> [grades] [testes]   (13/11/2026)
#
# Pedido do autor (PROTOCOLO.md da pasta de saída): todos os testes do TG com o
# GARCH sobre 500 resíduos (ARIMA fixo em 240), e todo robô com GARCH usando o
# filtro e o ajuste da posição juntos (Estrategia=3). Duas versões rodadas
# separadas, com a escolha feita dentro de cada uma:
#   M = mantém a posição no veto (ZerarNoVeto=false)
#   E = encerra a posição no veto (ZerarNoVeto=true)
# Grade só compra: sub-grades arima, ft_abs e ft_pct da rodada 3 (52 passagens).
# Mesmo molde do janelas_garch.sh (aquecimento de quatro anos, Inicio_Operacao).
# JG=1000 roda a mesma bateria com o GARCH sobre 1000 resíduos (padrão 500). Com
# 1000, as ações sem série antes de 2003 (todas menos a PETR4) não têm dados para
# o GARCH em 2004-2006 nem no começo de 2007: o par C1/T1 delas é pulado.
# VERSOES="M E", ATIVOS="PETR4 ..." e PULAR="M_PETR4_C1 ..." restringem a bateria.
# Retomar depois de parar: o mesmo comando (as janelas já gravadas com 52
# passagens são puladas; a que estava rodando é refeita do início).
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
OUT="$1"; [ -n "$OUT" ] || { echo "uso: $0 <pasta_de_saida> [grades] [testes]"; exit 1; }
shift; ETAPAS="${*:-grades testes}"
VERSOES="${VERSOES:-M E}"; ATIVOS="${ATIVOS:-PETR4 VALE3 USIM5 POMO4}"
JG="${JG:-500}"
mkdir -p "$OUT/grades"; OUT="$(cd "$OUT" && pwd)"
R3="$A/dados/resultados/rodada3_b3_oficial/grades"
SUBS="arima ft_abs ft_pct"
PERIODOS="C1 T1 C2 T2 C3 T3 C4 T4"

epoca(){ date -u -d "${1//./-}" +%s; }
zera(){ [ "$1" = E ] && echo true || echo false; }

# janela -> operação_de operação_até testador_de (PETR4; C1 e T1 no PETR4_DESDE1999)
declare -A P=(
  [C1]="2004.01.02 2006.12.29 2000.01.03" [T1]="2007.01.02 2011.12.30 2003.01.02"
  [C2]="2010.01.04 2012.12.29 2006.01.02" [T2]="2013.01.02 2016.12.30 2009.01.02"
  [C3]="2022.01.03 2024.12.31 2018.01.02" [T3]="2025.01.02 2026.09.19 2021.01.04"
  [C4]="2014.01.02 2016.12.30 2010.01.04" [T4]="2017.01.02 2024.12.30 2013.01.02")
periodo(){ # periodo <ativo> <janela> -> de ate testador simbolo
  set -- "$1" "$2" ${P[$2]}
  if [ "$1" = PETR4 ]; then
    case $2 in C1|T1) echo "$3 $4 $5 PETR4_DESDE1999";; *) echo "$3 $4 $5 PETR4_OFICIAL";; esac
  else
    # série desde 2003: o GARCH de 500 só tem dados a partir de fev/2005 (estudo de 26/10)
    case $2 in C1) echo "2005.02.01 $4 2003.01.02 ${1}_OFICIAL";; *) echo "$3 $4 $5 ${1}_OFICIAL";; esac
  fi; }

fixos(){ printf 'Janela_GARCH=%s\nInicio_Operacao=%s\nMetodoARIMA=0\nSelecaoPorBIC=false\nDistribuicaoGARCH=0\nArquivo_Traco=\n' "$JG" "$(epoca "$1")"; }
explicitar(){ awk -F= '!/\|\|/ && NF==2 && $2 ~ /^(-?[0-9.]+|true|false)$/ {
    if ($2=="true"||$2=="false") print $1"="$2"||false||0||true||N"; else print $1"="$2"||"$2"||1||"$2"||N"; next } { print }'; }
grade(){ # grade <sub_grade> <versão> <ativo> <data_inicio>
  { tr -d '\r' < "$R3/$1.txt" | sed -e 's/^Janela_Estimacao=.*/Janela_Estimacao=240/' \
      -e "s/^ZerarNoVeto=.*/ZerarNoVeto=$(zera "$2")/" \
      -e "s|^Arquivo_Proventos=.*|Arquivo_Proventos=proventos_$3.csv|"
    fixos "$4"; } | explicitar; }
pular(){ [[ " $PULAR " == *" $1 "* ]]; }
# janela já gravada com as 52 passagens: pulada (retomar = rodar o mesmo comando de novo)
pronta(){ local f="$OUT/$1/calibracao/$2_$3.csv"; [ -s "$f" ] && [ $(( $(wc -l < "$f") - 1 )) -eq 52 ]; }
otimiza(){ rm -f "$N/MQL5/Profiles/Tester/ARIMA_GARCH_EA.set"; bash "$S/otimizar.sh" "$@"; }

if [[ " $ETAPAS " == *" grades "* ]]; then
  echo "grades: inicio $(date '+%F %T')"
  mkdir -p "$TRAB/subfa"
  for v in $VERSOES; do for a in $ATIVOS; do for per in $PERIODOS; do
    pular "${v}_${a}_$per" && continue
    [ "$JG" -gt 500 ] && [ "$a" != PETR4 ] && [[ $per == ?1 ]] && continue
    pronta $v $a $per && { echo "$v $a $per: já feita, pulada"; continue; }
    set -- $(periodo "$a" "$per")
    rm -rf "$TRAB/g"
    for g in $SUBS; do
      f="$TRAB/subfa/${v}_${a}_${per}_$g.txt"; grade "$g" "$v" "$a" "$1" > "$f"
      [ "$a$per" = PETR4C4 ] && sed 's/^Inicio_Operacao=.*/Inicio_Operacao=<data>/' "$f" > "$OUT/grades/${v}_$g.txt"
      otimiza "$per" "$4" "$3" "$2" "$f"
    done
    d="$TRAB/g/${4}_$per"; mkdir -p "$OUT/$v/calibracao"
    f=$(ls "$d" | head -1)
    { head -1 "$d/$f"; for x in "$d"/res_*; do sed -n 2p "$x"; done; } | tr -d '\r' > "$OUT/$v/calibracao/${a}_$per.csv"
    echo "$v $a $per: $(( $(wc -l < "$OUT/$v/calibracao/${a}_$per.csv") - 1 )) passagens"
  done; done; done
  echo "grades: fim $(date '+%F %T')"
fi

if [[ " $ETAPAS " == *" testes "* ]]; then
  echo "testes: inicio $(date '+%F %T')"
  B="$TRAB/in_fa_base.txt"
  tr -d '\r' < "$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt" | sed 's/^Janela_Estimacao=.*/Janela_Estimacao=240/' > "$B"
  EA='robos\ARIMA-GARCH\ARIMA_GARCH_EA'
  cfg(){ awk -v k="$2" '$1 == k { sub(/^[^|]*\| /, ""); print }' "$1"; }
  for v in $VERSOES; do
    mkdir -p "$OUT/$v"/{escolhas,testes,relatorios_mt5}
    LOG="$OUT/$v/testes/execucao.log"; : > "$LOG"
    for k in 1 2 3 4; do bash "$S/escolher.sh" "$OUT/$v/calibracao/PETR4_C$k.csv" so_compra > "$OUT/$v/escolhas/PETR4_C$k.txt"; done
    # roda <rotulo> <símbolo> <operação_de> <operação_até> <testador_de> <parâmetros...>
    roda(){ local rot=$1 sim=$2 de=$3 ate=$4 td=$5; shift 5
      echo "== $rot $*" >> "$LOG"
      rm -f "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv"
      ESPERA=3600 bash "$S/rodar.sh" "$rot" "$EA" "$sim" "$td" "$ate" 100000 1:1 "$B" \
        Janela_GARCH=$JG Inicio_Operacao=$(epoca "$de") MetodoARIMA=0 SelecaoPorBIC=false DistribuicaoGARCH=0 Arquivo_Traco= \
        "$@" >> "$LOG" 2>&1; }
    for k in 1 2 3 4; do
      set -- $(periodo PETR4 T$k); E="$OUT/$v/escolhas/PETR4_C$k.txt"
      for r in GS GSgemeo GC GCgemeo AS; do roda ${v}_T${k}_$r "$4" "$1" "$2" "$3" $(cfg "$E" $r); done
    done
    E="$OUT/$v/escolhas/PETR4_C2.txt"
    for r in GS GSgemeo GC GCgemeo; do
      roda ${v}_L1_$r PETR4_DESDE1999 2005.01.03 2026.09.18 2001.01.02 $(cfg "$E" $r)
      roda ${v}_L2_$r PETR4_OFICIAL 2017.01.02 2024.12.30 2013.01.02 $(cfg "$E" $r)
    done
    for r in $(sed -n 's/^== \([^ ]*\).*/\1/p' "$LOG"); do
      cp "$COMUM/metricas_$r.csv" "$COMUM/curva_$r.csv" "$OUT/$v/testes/"
      cp "$TRAB/rel/rel_$r.htm" "$TRAB/rel/rel_$r.png" "$OUT/$v/relatorios_mt5/" 2>/dev/null
    done
  done
  echo "testes: fim $(date '+%F %T')"
fi
