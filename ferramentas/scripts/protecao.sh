#!/bin/bash
# protecao.sh <pasta testes> -- queda maxima e volatilidade (camada 3) de cada par GARCH x gemea,
# e teste de Pitman-Morgan (igualdade de variancias em amostras pareadas: correlacao entre
# soma e diferenca dos retornos diarios; r<0 = GARCH oscila menos). EXPLORATORIO (06/10/2026):
# nao esta no TG; so entra se o autor ler Pitman (1939) e Morgan (1939) e decidir usar.
cd "$1"
dd(){ awk -F';' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i} NR==2{printf "%.1f", $h["dd_selic"]*100}' metricas_$1.csv; }
vol(){ awk -F';' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i} NR==2{printf "%.1f", $h["vol_selic"]*100}' metricas_$1.csv; }
pm(){ paste -d, <(cut -d, -f1,2 curva_$1.csv) <(cut -d, -f1,2 curva_$2.csv) | awk -F, 'NR>1 && $1==$3 {if(pa){x=$2/pa-1; y=$4/pb-1; u=x+y; v=x-y; n++; su+=u; sv+=v; suu+=u*u; svv+=v*v; suv+=u*v} pa=$2; pb=$4}
  END{cuv=suv/n-(su/n)*(sv/n); r=cuv/sqrt((suu/n-(su/n)^2)*(svv/n-(sv/n)^2)); t=r*sqrt(n-2)/sqrt(1-r*r); printf "n=%d r=%.3f t=%.1f", n, r, t}'; }
printf "%-13s %8s %8s %7s %7s  %s\n" par dd_GARCH dd_gem vol_G vol_gem "Pitman-Morgan"
for p in "T1 R3_T1_GS R3_T1_GSgemeo" "T2-Sharpe R3_T2_GS R3_T2_GSgemeo" "T2-Calmar R3_T2_GC R3_T2_GCgemeo" "T3-Sharpe R3_T3_GS R3_T3_GSgemeo" "T3-Calmar R3_T3_GC R3_T3_GCgemeo" "1724-Sharpe R6_GS R6_GSgemeo" "1724-Calmar R6_GC R6_GCgemeo" "L1-Sharpe L1_GS L1_GSgemeo" "L1-Calmar L1_GC L1_GCgemeo" "L2-Sharpe L2_GS L2_GSgemeo" "L2-Calmar L2_GC L2_GCgemeo"; do
  set -- $p; printf "%-13s %8s %8s %7s %7s  %s\n" $1 $(dd $2) $(dd $3) $(vol $2) $(vol $3) "$(pm $2 $3)"; done
