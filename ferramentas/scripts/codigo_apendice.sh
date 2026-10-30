#!/bin/bash
# Gera as listagens dos Apendices A e B do TG a partir do codigo que de fato
# roda (o EA e, desde 27/10/2026, Arima, SelecaoModelo, Garch e Estrategia):
#   1) aplica os marcadores (que no EA sao so comentarios):
#        //@omitir-inicio ... //@omitir-fim   bloco fora da listagem
#        linha terminada em //@omitir         linha fora da listagem
#        //@apendice: CODIGO                   CODIGO entra no lugar, mesma indentacao
#      O que fica de fora e log, diagnostico, traco, avaliacao no testador e as
#      opcoes experimentais (t de Student, BIC, maxima verossimilhanca, janela
#      propria do GARCH), nada que participe da decisao de operar no TG.
#   2) remove os comentarios (sem_comentarios.sh).
#   3) bloco de if/else que ficou com uma instrucao so vira a forma sem chaves,
#      e some a linha em branco logo depois de { ou antes de }.
# A listagem resultante compila sozinha (conferido em 18/10/2026; EA mais os
# quatro .mqh reduzidos, 0 erros e 0 avisos, em 27/10/2026).
#   uso: codigo_apendice.sh arquivo.mq5|.mqh > saida
D=$(dirname "$0")
awk '
/\/\/@omitir-inicio/ { pula = 1; next }
/\/\/@omitir-fim/    { pula = 0; next }
pula                 { next }
/\/\/@omitir[ \t]*$/ { next }
/^[ \t]*\/\/@apendice: / {
  match($0, /^[ \t]*/); ind = substr($0, 1, RLENGTH)
  sub(/^[ \t]*\/\/@apendice: /, ""); print ind $0; next
}
{ print }' "$1" > "${TMPDIR:-/tmp}/apendice_$$.mq5"
bash "$D/sem_comentarios.sh" "${TMPDIR:-/tmp}/apendice_$$.mq5" | perl -0pe '
  s/^([ ]*(?:if|else)\b[^\n]*\n)([ ]*)\{\n([ ]*[^\n{}]+\n)\2\}\n/$1$3/mg;
  s/\{\n\n/{\n/g; s/\n\n([ ]*\})/\n$1/g'
rm -f "${TMPDIR:-/tmp}/apendice_$$.mq5"
