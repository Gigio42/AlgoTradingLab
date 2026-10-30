#!/bin/bash
# proventos_b3.sh (21/10/2026): proventos da PETR4 para a camada 4, a partir da
# lista OFICIAL da B3 (dados/fontes/b3/proventos_PETR_historico_api_b3_2026-10-21/,
# acao PN, dividendo + JCP + rendimento). Substitui a base do Yahoo (pedido do autor).
#
# Para cada provento com data-com a partir de 2003: valor ajustado = percentual
# publicado pela B3 (corporateActionPrice, = valor / fechamento da data-com) x
# fechamento da PETR4_OFICIAL na data-com. Assim o valor ja sai na unidade da
# serie corrigida por desdobramentos, sem dividir a mao. Data-ex = pregao
# seguinte a data-com. Proventos com a mesma data-ex sao somados.
# Saida: dados/series/proventos_PETR4.csv ("AAAA.MM.DD,valor", o formato do
# CDesempenho::CarregarProventos).
A="$(cd "$(dirname "$0")/../.." && pwd)"
F="$A/dados/fontes/b3/proventos_PETR_historico_api_b3_2026-10-21"; S="$A/dados/series"
{ echo "# data-ex e R\$ por acao na unidade da PETR4_OFICIAL - fonte B3 (API de proventos em dinheiro, acao PN) - baixado em 2026-10-21 - gerado por ferramentas/scripts/proventos_b3.sh - ver dados/FONTES.md item 3"
  jq -r '.results[] | select(.typeStock=="PN") | [.lastDatePriorEx,.corporateActionPrice] | @tsv' "$F"/p*.json |
  awk -F'\t' -v OFS=, '{split($1,x,"/"); p=$2; gsub(",",".",p); print x[3]"."x[2]"."x[1],p}' |
  LC_ALL=C sort |
  awk -F, 'NR==FNR{ if($0!~/^#/){n++; d[n]=$1; c[$1]=$6; i[$1]=n}; next}
           $1>="2003.01.01" { if(!($1 in c)){ print "SEM PREGAO NA DATA-COM " $1 > "/dev/stderr"; next }
             ex=d[i[$1]+1]; if(ex==""){ print "SEM DATA-EX " $1 > "/dev/stderr"; next }
             s[ex]+=$2/100*c[$1] }
           END{ for(e in s) printf "%s,%.6f\n", e, s[e] }' "$S/PETR4_OFICIAL.csv" - | LC_ALL=C sort
} > "$S/proventos_PETR4.csv"
