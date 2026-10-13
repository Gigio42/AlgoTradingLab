#!/bin/bash
# Remove comentarios (// e /* */) de um arquivo MQL5, preservando strings,
# literais de caractere e a indentacao original. Linhas que ficam vazias sao
# reduzidas a no maximo uma em branco seguida. Usado para gerar o Apendice A
# do TG a partir do codigo que de fato roda, sem copia manual.
#   uso: sem_comentarios.sh entrada.mq5 > saida.mq5
awk '
BEGIN { bloco = 0; branco = 1 }
{
  linha = $0; out = ""; i = 1; n = length(linha); str = ""
  while (i <= n) {
    c = substr(linha, i, 1); d = substr(linha, i, 2)
    if (bloco) {
      if (d == "*/") { bloco = 0; i += 2 } else i++
      continue
    }
    if (str != "") {
      out = out c
      if (c == "\\") { out = out substr(linha, i + 1, 1); i += 2; continue }
      if (c == str) str = ""
      i++; continue
    }
    if (d == "//") break
    if (d == "/*") { bloco = 1; i += 2; continue }
    if (c == "\"" || c == "\x27") str = c
    out = out c; i++
  }
  sub(/[ \t]+$/, "", out)
  if (out == "") { if (!branco) print ""; branco = 1 }
  else { print out; branco = 0 }
}' "$1" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
