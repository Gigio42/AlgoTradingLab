#!/bin/bash
# resumo_exploratorio.sh <pasta_da_bateria>  > exploratorio_estimacao/resumo.txt
# Compara, para os mesmos robos e periodos, as quatro combinacoes de estimacao
# e criterio: HRAIC (testes N_* da bateria), HRBIC, MVAIC, MVBIC.
D="$1"; T="$D/testes"; X="$D/exploratorio_estimacao/testes"
export LC_ALL=C
m(){ local f="$1"; awk -F';' -v c="$2" 'NR==1{for(i=1;i<=NF;i++)h[$i]=i} NR==2{print (c in h)?$h[c]:"NA"}' "$f" 2>/dev/null; }
arq(){ [ "$1" = HRAIC ] && echo "$T/metricas_N_$2_$3.csv" || echo "$X/metricas_X_$1_$2_$3.csv"; }
echo "=== EXPLORATORIO: estimacao do ARIMA x criterio de ordens (camada 1 = cru; camada 3 = com Selic) ==="
echo "Robos escolhidos com HR + AIC (bateria de 15/10), sem reotimizar. Exploratorio: nao muda a decisao."
echo
printf "%-4s %-8s %-6s %9s %9s %9s %9s %7s %7s\n" per robo comb ret_cru queda vol ret_selic acerto oper
for n in T1 T2 R6 T3 T5; do
  for k in GR GRgemeo AR; do
    for c in HRAIC HRBIC MVAIC MVBIC; do
      f=$(arq $c $n $k); [ -s "$f" ] || { printf "%-4s %-8s %-6s %s\n" $n $k $c "(falta)"; continue; }
      awk -v n=$n -v k=$k -v c=$c -v r=$(m "$f" ret_puro) -v q=$(m "$f" dd_puro) -v v=$(m "$f" vol_puro) \
          -v s=$(m "$f" ret_selic) -v a=$(m "$f" taxa_acerto) -v o=$(m "$f" saidas) \
        'BEGIN{printf "%-4s %-8s %-6s %8.1f%% %8.1f%% %8.1f%% %8.1f%% %6.1f%% %7d\n", n,k,c,100*r,100*q,100*v,100*s,100*a,o}'
    done
  done
  echo
done
echo "--- Contagem: em quantos dos 15 casos (5 periodos x 3 robos) cada combinacao teve o melhor valor ---"
for met in "ret_puro:maior" "dd_puro:menor" "vol_puro:menor"; do
  col=${met%%:*}; sen=${met#*:}
  declare -A vit=([HRAIC]=0 [HRBIC]=0 [MVAIC]=0 [MVBIC]=0)
  for n in T1 T2 R6 T3 T5; do for k in GR GRgemeo AR; do
    best=""; bv=""
    for c in HRAIC HRBIC MVAIC MVBIC; do f=$(arq $c $n $k); [ -s "$f" ] || continue; v=$(m "$f" $col)
      if [ -z "$bv" ] || awk -v a=$v -v b=$bv -v s=$sen 'BEGIN{exit !((s=="maior")?(a>b):(a<b))}'; then bv=$v; best=$c; fi; done
    [ -n "$best" ] && vit[$best]=$((vit[$best]+1))
  done; done
  echo "  $col ($sen): HRAIC ${vit[HRAIC]} | HRBIC ${vit[HRBIC]} | MVAIC ${vit[MVAIC]} | MVBIC ${vit[MVBIC]}"
done
