#!/bin/bash
# hannan_rissanen_exemplo.sh (02/11/2026): números das contas feitas à mão na
# versão 2 do relatório ia/relatorios/hannan-rissanen/. Só lê arquivos que o
# hannan_rissanen.sh já gravou em dados/resultados/hannan_rissanen_2026-10-30/
# (nada roda no MetaTrader) e grava, na mesma pasta:
#   exemplo.tex          macros \vHEx... (vírgula decimal)
#   real_pesos_ma.csv    pesos do "AR comprido" equivalente ao MA(1) do pregão
#                        real, pi_j = -(-theta)^j, com o theta estimado
# Fontes: real_serie.csv (z e resíduos finais, em %), resumo.txt (theta com 10
# algarismos, linha "passo a passo" do pregão de 13/05/2021) e valores.tex (N).
set -euo pipefail
D="$(cd "$(dirname "$0")/../.." && pwd)/dados/resultados/hannan_rissanen_2026-10-30"
SAIDA="$D/exemplo.tex"

N=$(tr -d '\r' < "$D/valores.tex" | sed -n 's/^\\def\\pHRealN{\([0-9]*\)}$/\1/p')
THETA=$(tr -d '\r' < "$D/resumo.txt" | grep -m1 "^  passo a passo: m=29 obs1=210 obs2=209 primeiro=30" |
        sed 's/.*theta1=\([-0-9.e]*\).*/\1/')
[ -n "$N" ] && [ -n "$THETA" ] || { echo "faltam N ou theta" >&2; exit 1; }

LC_ALL=C awk -v N="$N" -v th="$THETA" -v saida="$SAIDA" -v pesos="$D/real_pesos_ma.csv" '
function v(x, casas,   s) { s = sprintf("%." casas "f", x); sub(/\./, "{,}", s)
  if(s ~ /^-/) s = "\\ensuremath{-}" substr(s, 2); return s }
function data(s,   a) { split(s, a, "-"); return a[3] "/" a[2] "/" a[1] }
BEGIN { FS = "," }
NR == 1 { next }
{ i = $1; z[i] = $4; e[i] = $6; dt[i] = $2; n = i }
END {
  ln = log(N)
  printf "\\def\\vHExLnN{%s}\\def\\vHExLnNQuad{%s}\n", v(ln, 3), v(ln * ln, 2) > saida
  # recursão dos resíduos finais: previsto = z - e (o que o modelo esperava para o dia)
  split("1 2 3", ini, " "); nomes = "ABCDEFG"
  k = 0
  for(r = 1; r <= 3; r++) linha(ini[r])
  for(r = n - 2; r <= n; r++) linha(r)
  printf "\\def\\vHExTheta{%s}\n", v(th, 4) > saida
  print "j,pi" > pesos
  for(j = 1; j <= 30; j++) { p = -((-th) ^ j); print j "," sprintf("%.8f", p) > pesos
    if(j <= 3) printf "\\def\\vHExPi%s{%s}\n", substr("ABC", j, 1), v(p, 4) > saida }
}
function linha(t,   nome) { k++; nome = substr(nomes, k, 1)
  printf "\\def\\vHExRec%s{%s & %s & %s & %s & %s\\\\}\n", nome, data(dt[t]), v(z[t], 3), v(e[t-1], 3),
         v(z[t] - e[t], 3), v(e[t], 3) > saida }
' "$D/real_serie.csv"
cat "$SAIDA"
