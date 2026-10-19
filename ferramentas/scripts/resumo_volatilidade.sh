#!/bin/bash
# resumo_volatilidade.sh <pasta testes> <metricas das medias moveis de Almeida> <pasta saida>
# (14/10/2026) Grava, para o Cap. III:
#  - volatilidade_grafico.csv: volatilidade (%) por janela de teste, para o
#    grafico de barras (versao A, gemea de A, versao B, gemea de B, medias moveis);
#  - reducao_volatilidade.txt: quanto o ARIMA-GARCH oscilou a menos (%) que a
#    gemea e que as medias moveis, com o t de Pitman-Morgan de comparacoes_risco.csv.
# Volatilidade: vol_selic das metricas (no cenario de Almeida, vol_puro, como na
# tabela das condicoes originais). Versao A = escolha por Sharpe (GS);
# versao B = escolha por Calmar (GC).
T="$1"; MMA="$2"; O="$3"
[ -s "$T/comparacoes_risco.csv" ] && [ -s "$MMA" ] && [ -d "$O" ] || { echo "uso: $0 <testes> <metricas_fl13of.csv> <saida>"; exit 1; }
export LC_ALL=C
vol(){ local f="$T/metricas_$1.csv" c=vol_selic; [ "$1" = fl13of ] && f="$MMA"; case $1 in cenA*|fl13of) c=vol_puro;; esac
  awk -F';' -v c=$c 'NR==1{for(i=1;i<=NF;i++)h[$i]=i;next} NR==2{printf "%.6f", $h[c]*100}' "$f"; }
tpm(){ awk -F';' -v a="$1" -v b="$2" '$2==a && $3==b {print $16 " " $17}' "$T/comparacoes_risco.csv"; }
f="$O/volatilidade_grafico.csv"; echo "janela,A,gemeaA,B,gemeaB,MM" > $f
for p in "2007-2011 R3_T1" "2013-2016 R3_T2" "2017-2024 R6" "2025-2026 R3_T3"; do set -- $p
  awk -v n=$1 -v a=$(vol $2_GS) -v ga=$(vol $2_GSgemeo) -v b=$(vol $2_GC) -v gb=$(vol $2_GCgemeo) -v m=$(vol $2_MM) \
    'BEGIN{printf "%s,%.1f,%.1f,%.1f,%.1f,%.1f\n", n, a, ga, b, gb, m}' >> $f
done
g="$O/reducao_volatilidade.txt"
printf "%-17s %10s %8s %10s %8s %10s\n" comparacao red_gemea t red_MM t maior_p > $g
for x in R3_T1_GS R3_T2_GS R3_T2_GC R3_T3_GS R3_T3_GC R6_GS R6_GC L1_GS L1_GC L2_GS L2_GC cenA_1316_GARCH; do
  if [ $x = cenA_1316_GARCH ]; then gm=cenA_1316_ARIMA; mm=fl13of; else gm=${x}gemeo; mm=${x%_G?}_MM; fi
  set -- $(tpm $x $gm) $(tpm $x $mm)
  awk -v x=$x -v v=$(vol $x) -v g=$(vol $gm) -v m=$(vol $mm) -v t1=$1 -v p1=$2 -v t2=$3 -v p2=$4 \
    'BEGIN{printf "%-17s %9.3f%% %8.1f %9.3f%% %8.1f %10.3g\n", x, 100*(1-v/g), t1, 100*(1-v/m), t2, (p1>p2)?p1:p2}' >> $g
done
cat $f $g
