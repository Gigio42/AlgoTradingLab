#!/bin/bash
# checar_ilustracoes.sh [main.pdf] [pagina_inicial]
#
# Depois de mexer no texto do TG: lista as ilustrações (Figura, Tabela, Gráfico,
# Quadro) que caíram no alto de uma página enquanto o parágrafo da página
# anterior ainda não terminou, isto é, que cortam um parágrafo ao meio. Sem saída
# = nenhum corte. Criado em 12/11/2026, a pedido do autor (INCERTEZAS item 100).
# Correção usual: mover o ambiente para depois do parágrafo cortado.
PDF="${1:-tg/main.pdf}"; INI="${2:-14}"; N=$(pdfinfo "$PDF" | awk '/Pages/{print $2}')
T=$(mktemp)
for p in $(seq $INI $N); do
  pdftotext -layout -f $p -l $p "$PDF" - | sed 's/\f//' | awk 'NF' | sed 's/^ *//' > $T
  first=$(sed -n 2p $T)
  if [ -n "$prev" ] && echo "$first" | grep -qE '^(Figura|Tabela|Gráfico|Quadro) [0-9]+ –'; then
    if ! echo "$prev" | grep -qE '[.:]$'; then echo "CORTE p$p: ${first:0:55} | anterior: ...${prev: -35}"; fi
  fi
  # última linha de texto da página (ignora o número da página no alto)
  prev=$(grep -vE '^[0-9]+$' $T | tail -1)
done; rm -f $T
