#!/bin/bash
# seletividade.sh <pasta testes> <rotulo> ...
# O GARCH oscilou menos so porque ficou menos tempo comprado, ou porque ficou
# fora nos dias mais agitados? (13/10/2026)
#
# Com w = exposicao do dia (fracao do patrimonio na acao, coluna exposicao da
# curva) e r = retorno diario da acao (coluna buyhold):
#   oscilacao observada  = raiz( media(w^2 * r^2) )
#   oscilacao sem escolha = raiz( media(w^2) * media(r^2) )   (a mesma exposicao
#                            espalhada por dias quaisquer)
#   razao = observada / sem escolha.  < 1: a exposicao ficou nos dias calmos.
# So a parte da acao; o caixa na Selic e os custos ficam de fora.
cd "$1" || exit 1; shift
export LC_ALL=C
printf "%-18s %7s %9s\n" rotulo razao exposicao
for r in "$@"; do
  awk -F, -v n="$r" 'NR > 2 { rb = $6 / pb - 1; w = $8; A += w*w*rb*rb; W += w*w; Q += rb*rb; k++ }
    NR > 1 { pb = $6 }
    END { printf "%-18s %7.3f %9.3f\n", n, sqrt((A/k) / ((W/k) * (Q/k))), sqrt(W/k) }' "curva_$r.csv"
done
