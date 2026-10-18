#!/bin/bash
# recorte_ano.sh <ano> <prefixo da curva> <rotulo>...
#
# Retorno e queda máxima de cada robô dentro de UM ano civil, a partir das
# curvas diárias que o EA exporta (curva_<rotulo>.csv, coluna "estrategia" =
# patrimônio na camada 3, base 1; "buyhold" = compra e manutenção pelo preço).
# O ano começa no último fechamento do ano anterior (mesma base do anual.sh)
# e a queda máxima é medida só dentro do ano, a partir desse ponto.
#
# Exemplo (crise da pandemia, dentro do teste de 2017 a 2024):
#   cd dados/resultados/refeito_2026-10-05/testes
#   bash ../../../../ferramentas/scripts/recorte_ano.sh 2020 curva_R6 GS GSgemeo GC GCgemeo ARIMA MM
[ $# -ge 3 ] || { echo "uso: $0 <ano> <prefixo> <rotulo>..." >&2; exit 1; }
# COL=puro usa a camada 1 (sem custo e sem Selic) em vez da camada 3.
COL="${COL:-estrategia}"
ano=$1; pre=$2; shift 2
printf "%-10s %10s %10s\n" "robo" "retorno" "queda_max"
primeiro=1
for r in "$@"; do
  f="${pre}_${r}.csv"
  [ -s "$f" ] || { echo "falta $f" >&2; exit 1; }
  LC_ALL=C awk -F, -v ano="$ano" -v r="$r" -v bh="$primeiro" -v col="$COL" '
    BEGIN { e0 = 1; b0 = 1 }   # curva comeca no ano pedido: base = 1 (inicio da curva)
    NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; next }
    { a = substr($1, 1, 4) + 0 }
    a < ano { e0 = $h[col]; b0 = $h["buyhold"]; next }
    a == ano {
      e = $h[col]; b = $h["buyhold"]
      if(!ini) { ini = 1; pe = e0; pb = b0 }
      if(e > pe) pe = e; if(1 - e/pe > dd) dd = 1 - e/pe
      if(b > pb) pb = b; if(1 - b/pb > db) db = 1 - b/pb
      el = e; bl = b
    }
    END {
      if(!ini) { print "sem dados de " ano " ou do ano anterior em " FILENAME > "/dev/stderr"; exit 1 }
      printf "%-10s %9.2f%% %9.2f%%\n", r, 100*(el/e0 - 1), 100*dd
      if(bh) printf "%-10s %9.2f%% %9.2f%%\n", "PETR4", 100*(bl/b0 - 1), 100*db
    }' "$f" || exit 1
  primeiro=0
done
