#!/bin/bash
# parear.sh <calibracao.csv> <teste.csv>  > pareado.csv
#
# Junta, configuracao a configuracao, a passagem da calibracao e a do teste
# (as duas sairam da mesma grade). Chave = todos os parametros do modelo
# (colunas UsarGARCH ... Barras_Entre_Reselecao do OnTester). Colunas de
# metrica ganham o sufixo _c (calibracao) ou _t (teste), como nos pareados
# das rodadas 3 e 4.
[ -s "$1" ] && [ -s "$2" ] || { echo "uso: $0 <calibracao.csv> <teste.csv>" >&2; exit 1; }
awk -F';' -v OFS=';' '
BEGIN { np = split("UsarGARCH Estrategia ModoLimiar Limiar_Percentil Limiar_Absoluto K_Confianca " \
                   "Vol_Alvo Limiar_Sinal Janela_Estimacao SomenteCompra ZerarNoVeto ModoVolume " \
                   "Fracao_Capital Volume_Base ModoOrdens IncluirConstante Barras_Entre_Reselecao", P, " ")
        for(i = 1; i <= np; i++) ehpar[P[i]] = 1 }
FNR == 1 { arq++; delete h; for(i = 1; i <= NF; i++) h[$i] = i
           if(arq == 1) { nc = NF; for(i = 1; i <= NF; i++) cab[i] = $i }
           next }
{ k = ""; for(i = 1; i <= np; i++) k = k ";" $h[P[i]]
  m = ""; for(i = 1; i <= nc; i++) if(!(cab[i] in ehpar)) m = m ";" $h[cab[i]]
  if(arq == 1) { if(k in C) dup++; C[k] = m; ordem[++n] = k } else { if(k in T) dup++; T[k] = m } }
END {
  if(dup) print "AVISO: " dup " configuracoes repetidas" > "/dev/stderr"
  s = ""; for(i = 1; i <= np; i++) s = s (i > 1 ? ";" : "") P[i]
  for(i = 1; i <= nc; i++) if(!(cab[i] in ehpar)) s = s ";" cab[i] "_c"
  for(i = 1; i <= nc; i++) if(!(cab[i] in ehpar)) s = s ";" cab[i] "_t"
  print s
  for(j = 1; j <= n; j++) { k = ordem[j]
    if(!(k in T)) { falta++; continue }
    print substr(k, 2) C[k] T[k] }
  if(falta) print "AVISO: " falta " configuracoes da calibracao sem passagem no teste" > "/dev/stderr"
}' "$1" "$2"
