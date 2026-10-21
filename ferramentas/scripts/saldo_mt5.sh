#!/bin/bash
# saldo_mt5.sh <rel_X.htm>... [> saida.txt]
#
# Lê a lista de negócios do relatório do testador do MetaTrader 5 (UTF-16LE) e
# resume o saldo após cada negociação encerrada (negócio de saída, "out"), que
# é o que o gráfico "Balance" do relatório desenha, com o número da
# negociação no eixo horizontal. Para cada relatório: saldo final, mínimo e
# máximo (com o número da negociação e a data) e a data de cada 10ª negociação,
# para localizar no tempo os trechos do gráfico.
for f in "$@"; do
  iconv -f UTF-16LE -t UTF-8 "$f" | LC_ALL=C awk -v nome="$(basename "$f" .htm)" '
    /<b>Deals<\/b>/ { lista = 1; next }
    lista && /<td>out<\/td>/ {
      linha = $0; gsub(/<\/td><td[^>]*>/, "|", linha); gsub(/<[^>]*>/, "", linha)
      n = split(linha, c, "|"); data = substr(c[1], 1, 10); saldo = c[12]; gsub(/ /, "", saldo); saldo += 0
      k++; if(k == 1 || saldo < mn) { mn = saldo; kmn = k; dmn = data }
      if(k == 1 || saldo > mx) { mx = saldo; kmx = k; dmx = data }
      if(k % 10 == 0) marcas = marcas sprintf(" %d=%s", k, data)
      fim = saldo
    }
    END { printf "%s: %d negociações; final %.0f; mínimo %.0f (nº %d, %s); máximo %.0f (nº %d, %s)\n  datas:%s\n",
                 nome, k, fim, mn, kmn, dmn, mx, kmx, dmx, marcas }'
done
