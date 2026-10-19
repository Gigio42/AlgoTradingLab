#!/bin/bash
# escolher_rf.sh <calibracao.csv> [so_compra]
#
# Criterio da bateria de 15/10/2026 (dados/resultados/bateria_2026-10-15/PROTOCOLO.md):
#   GR = ARIMA-GARCH de maior fator de recuperacao do testador
#        (coluna fator_recuperacao_mt5 = STAT_RECOVERY_FACTOR)
#   AR = ARIMA puro de maior fator de recuperacao
#   GRgemeo = a configuracao da GR com UsarGARCH=false
# So concorrem configuracoes com pelo menos 12 negociacoes encerradas (saidas)
# no periodo de otimizacao; se nenhuma da familia atingir, concorrem todas.
# Desempate: menos negociacoes; depois ordem alfabetica da linha de parametros.
# Saida no mesmo formato do escolher.sh (pronta para o rodar.sh).
[ -s "$1" ] || { echo "uso: $0 <calibracao.csv> [so_compra]" >&2; exit 1; }
MIN=12
awk -F';' -v so="$2" -v min="$MIN" '
NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i
          if(!("fator_recuperacao_mt5" in h)) { print "ERRO: sem coluna fator_recuperacao_mt5" > "/dev/stderr"; exit 1 }
          next }
function v(c) { return (c in h) ? $h[c] : "" }
function b(x) { return (x + 0 == 1) ? "true" : "false" }
function melhor(k, val) {
  if(!(k in best) || val > best[k] + 0 ||
     (val == best[k] + 0 && (v("negocios") + 0 < neg[k] + 0 ||
                             (v("negocios") + 0 == neg[k] + 0 && par < lin[k])))) {
    best[k] = val; neg[k] = v("negocios"); lin[k] = par; gem[k] = gemeo
    met[k] = sprintf("fr=%s saidas=%s negocios=%s ret_puro=%s dd_puro=%s", v("fator_recuperacao_mt5"),
                     v("saidas"), v("negocios"), v("ret_puro"), v("dd_puro"))
  }
}
{
  if(so == "so_compra" && v("SomenteCompra") + 0 != 1) next
  g = (v("UsarGARCH") + 0 == 1) ? "G" : "A"
  par = "UsarGARCH=" b(v("UsarGARCH"))
  if(g == "G")
    par = par " Estrategia=" v("Estrategia") " ModoLimiar=" v("ModoLimiar") \
          " Limiar_Percentil=" v("Limiar_Percentil") " Limiar_Absoluto=" v("Limiar_Absoluto") \
          " K_Confianca=" v("K_Confianca") " Vol_Alvo=" v("Vol_Alvo") " ZerarNoVeto=" b(v("ZerarNoVeto"))
  arima = "Janela_Estimacao=" v("Janela_Estimacao") " IncluirConstante=" b(v("IncluirConstante")) \
          " Limiar_Sinal=" v("Limiar_Sinal") " SomenteCompra=" b(v("SomenteCompra"))
  par = par " " arima
  gemeo = "UsarGARCH=false " arima
  fr = v("fator_recuperacao_mt5") + 0
  n[g]++
  melhor(g "todos", fr)
  if(v("saidas") + 0 >= min) { melhor(g "min", fr); nmin[g]++ }
}
END {
  if(!(("G" "todos") in best) || !(("A" "todos") in best)) { print "ERRO: faltam passagens de uma das familias" > "/dev/stderr"; exit 1 }
  printf "# passagens: ARIMA-GARCH %d (com >= %d negociacoes: %d), ARIMA %d (com >= %d: %d)\n", n["G"], min, nmin["G"], n["A"], min, nmin["A"]
  kg = (("G" "min") in best) ? "Gmin" : "Gtodos"
  ka = (("A" "min") in best) ? "Amin" : "Atodos"
  if(kg == "Gtodos") print "# AVISO: nenhuma ARIMA-GARCH com >= " min " negociacoes; concorreram todas"
  if(ka == "Atodos") print "# AVISO: nenhum ARIMA com >= " min " negociacoes; concorreram todos"
  printf "GR %s | %s\n", met[kg], lin[kg]
  printf "AR %s | %s\n", met[ka], lin[ka]
  printf "GRgemeo | %s\n", gem[kg]
}' "$1"
