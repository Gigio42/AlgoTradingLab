#!/bin/bash
# Gera a listagem do Apendice A do TG a partir do EA que de fato roda:
#   1) aplica os marcadores (que no EA sao so comentarios):
#        //@omitir-inicio ... //@omitir-fim   bloco fora da listagem
#        linha terminada em //@omitir         linha fora da listagem
#        //@apendice: CODIGO                   CODIGO entra no lugar, mesma indentacao
#      O que fica de fora e log, diagnostico, traco e avaliacao no testador,
#      nada que participe da decisao de operar.
#   2) remove os comentarios (sem_comentarios.sh).
# A listagem resultante compila sozinha (conferido em 05/10/2026).
#   uso: codigo_apendice.sh EA.mq5 > saida.mq5
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
bash "$D/sem_comentarios.sh" "${TMPDIR:-/tmp}/apendice_$$.mq5"
rm -f "${TMPDIR:-/tmp}/apendice_$$.mq5"
