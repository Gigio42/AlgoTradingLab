#!/bin/bash
# resumo_garch_t.sh <pasta_garch_t> <pasta_refacao>
# Tabela normal x t de Student x gemea para cada configuracao, com os testes
# pareados (comparacoes.csv: p do Sharpe por Jobson-Korkie-Memmel e p do t
# pareado dos retornos diarios). Camada 3 (custos + Selic); no cenario de
# Almeida, sem custos nem Selic (ret_puro, dd_puro), como no TG.
T="$1/testes"; R="$2/testes"
[ -s "$T/comparacoes.csv" ] && [ -d "$R" ] || { echo "uso: $0 <pasta_garch_t> <pasta_refacao>"; exit 1; }
export LC_ALL=C
get(){ awk -F';' -v c="$2" 'NR==1{for(i=1;i<=NF;i++)h[$i]=i;next} NR==2{print $h[c]}' "$1"; }
pp(){ awk -F';' -v a="$2" -v b="$3" '$2==a && $3==b {printf "%.3f %.3f %+.2f", $9, $12, $5-$6}' "$1"; }
printf "%-15s|%8s %8s %8s|%6s %6s %6s|%6s %6s|%4s %4s|%6s %6s|%6s %6s|%5s\n" \
  config ret_N ret_t ret_gem dd_N dd_t dd_gem SR_N SR_t opN opT p_SRtN p_tpar p_SRtG p_tpar nu
for x in R3_T1_GS R3_T2_GS R3_T2_GC R3_T3_GS R3_T3_GC R6_GS R6_GC L1_GS L1_GC L2_GS L2_GC cenA_1316_GARCH; do
  if [ $x = cenA_1316_GARCH ]; then g=cenA_1316_ARIMA; c=ret_puro; d=dd_puro; else g=${x}gemeo; c=ret_selic; d=dd_selic; fi
  N="$R/metricas_$x.csv"; S="$T/metricas_TS_$x.csv"; G="$R/metricas_$g.csv"
  set -- $(pp "$T/comparacoes.csv" TS_$x $x); a1=$1 a2=$2
  set -- $(pp "$T/comparacoes.csv" TS_$x $g); b1=$1 b2=$2
  awk -v x=$x -v rn=$(get $N $c) -v rt=$(get $S $c) -v rg=$(get $G $c) \
      -v dn=$(get $N $d) -v dt=$(get $S $d) -v dg=$(get $G $d) \
      -v sn=$(get $N sharpe) -v st=$(get $S sharpe) -v on=$(get $N saidas) -v ot=$(get $S saidas) \
      -v a1=$a1 -v a2=$a2 -v b1=$b1 -v b2=$b2 -v nu=$(get $S nu_medio) 'BEGIN{
    printf "%-15s|%8.1f %8.1f %8.1f|%6.1f %6.1f %6.1f|%6.2f %6.2f|%4d %4d|%6s %6s|%6s %6s|%5.1f\n",
      x, rn*100, rt*100, rg*100, dn*100, dt*100, dg*100, sn, st, on, ot, a1, a2, b1, b2, nu }'
done
echo
echo "ret/dd em %; SR = Sharpe sobre a Selic; op = operacoes encerradas;"
echo "p_SRtN/p_tpar = t x normal; p_SRtG/p_tpar = t x gemea; nu = media dos graus de liberdade estimados por barra (teto 200)"
