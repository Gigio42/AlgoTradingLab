#!/bin/bash
# Rascunhos de grafico da bateria de 15/10/2026 (para o autor decidir o texto).
# Gera os CSVs a partir de ../testes/metricas_N_*.csv (nada digitado) e
# compila os .tex standalone. Uso: bash gerar.sh (dentro desta pasta).
cd "$(dirname "$0")"; T=../testes; export LC_ALL=C
m(){ awk -F';' -v c="$2" 'NR==1{for(i=1;i<=NF;i++)h[$i]=i} NR==2{print $h[c]}' "$T/metricas_$1.csv"; }
# camadas do teste principal (2017-2024), em %
{ echo "robo,cru,custos,selic,proventos"
  for r in MM AR GR GRgemeo; do
    echo "$r,$(awk -v a=$(m N_R6_$r ret_puro) -v b=$(m N_R6_$r ret_custos) -v c=$(m N_R6_$r ret_selic) -v d=$(m N_R6_$r ret_completo) 'BEGIN{printf "%.1f,%.1f,%.1f,%.1f",100*a,100*b,100*c,100*d}')"
  done
  echo "PETR4,$(awk -v a=$(m N_R6_MM bh_preco) -v d=$(m N_R6_MM bh_total) 'BEGIN{printf "%.1f,nan,nan,%.1f",100*a,100*d}')"
} > camadas_R6.csv
# volatilidade e queda por periodo (camada 1), em %
{ echo "periodo,GR,GRgemeo,AR,MM,qGR,qGRgemeo,qAR,qMM"
  for n in T1 T2 R6 T3 T5; do
    l="$n"; for c in vol_puro dd_puro; do for r in GR GRgemeo AR MM; do l="$l,$(awk -v x=$(m N_${n}_$r $c) 'BEGIN{printf "%.1f",100*x}')"; done; done; echo "$l"
  done } > risco_periodos.csv
for f in curva_T5 camadas_R6 risco_periodos; do pdflatex -interaction=nonstopmode $f.tex >/dev/null 2>&1 && echo "ok $f.pdf" || echo "FALHOU $f"; done
rm -f *.aux *.log
