#!/bin/bash
# anual.sh <pasta> <prefixo> <nome:rotulo[:coluna]> ...  > anual.csv
# Retorno de cada ano civil (%) a partir das curvas diarias (curva_<rotulo>.csv,
# base 1): valor no ultimo pregao do ano / valor no ultimo pregao do ano
# anterior (ou 1, no primeiro ano) - 1. Coluna padrao: estrategia (camada 3);
# para buy-and-hold e Selic usar :buyhold ou :selic.
# Ex.: anual.sh testes R3_T1_ GS:GS BH:GS:buyhold Selic:GS:selic GC:GC AS:AS MM:MM
d=$1; pre=$2; shift 2
cab="ano"; arqs=()
for x in "$@"; do IFS=: read -r nome rot c <<< "$x"; cab="$cab,$nome"; arqs+=("$d/curva_$pre$rot.csv:${c:-estrategia}"); done
echo "$cab"
for a in "${arqs[@]}"; do
  f=${a%:*}; c=${a##*:}
  awk -F, -v c="$c" 'NR==1{for(i=1;i<=NF;i++)h[$i]=i; ant=1; next}
    {y=substr($1,1,4); if(y!=ya && ya!=""){printf "%s %.2f\n", ya, (ult/ant-1)*100; ant=ult} ya=y; ult=$h[c]}
    END{printf "%s %.2f\n", ya, (ult/ant-1)*100}' "$f"
done | awk -v n=${#arqs[@]} '{if(!($1 in v)){ord[++k]=$1} v[$1]=v[$1] "," $2; cnt[$1]++}
  END{for(i=1;i<=k;i++) print ord[i] v[ord[i]]}'
