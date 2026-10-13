#!/bin/bash
# escolher.sh <calibracao.csv> [so_compra]
#
# Aplica o criterio de escolha do protocolo (rodada 3, PROTOCOLO.md) as
# passagens de UMA janela de calibracao:
#   GS = ARIMA-GARCH de maior Sharpe     GC = ARIMA-GARCH de maior Calmar
#   AS = ARIMA puro de maior Sharpe      AC = ARIMA puro de maior Calmar
# Desempate: menos operacoes (negocios); depois, ordem alfabetica da linha de
# parametros (so para ser deterministico).
# Com "so_compra", considera so as passagens com SomenteCompra=1 (rodada 3).
#
# Saida, uma linha por escolha, pronta para o rodar.sh:
#   GS sharpe=... calmar=... negocios=... | UsarGARCH=true Estrategia=3 ...
#   GSgemeo | UsarGARCH=false Janela_Estimacao=... (o mesmo ARIMA, sem GARCH)
# O CSV de entrada tem o cabecalho do OnTester do EA (colunas por nome).
[ -s "$1" ] || { echo "uso: $0 <calibracao.csv> [so_compra]" >&2; exit 1; }
awk -F';' -v so="$2" '
NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; next }
function v(c) { return (c in h) ? $h[c] : "" }
function b(x) { return (x + 0 == 1) ? "true" : "false" }
function melhor(fam, crit, val,   k) {
  k = fam crit
  if(!(k in best) || val > best[k] + 0 ||
     (val == best[k] + 0 && (v("negocios") + 0 < neg[k] + 0 ||
                             (v("negocios") + 0 == neg[k] + 0 && par < lin[k])))) {
    best[k] = val; neg[k] = v("negocios"); lin[k] = par; gem[k] = gemeo
    met[k] = sprintf("sharpe=%s calmar=%s negocios=%s dd=%s ret=%s", v("sharpe"), v("calmar"),
                     v("negocios"), v("dd_selic"), v("ret_selic"))
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
  melhor(g, "S", v("sharpe") + 0)
  melhor(g, "C", v("calmar") + 0)
  n[g]++
}
END {
  if(!("GS" in best) || !("AS" in best)) { print "ERRO: faltam passagens de uma das familias" > "/dev/stderr"; exit 1 }
  printf "# passagens: ARIMA-GARCH %d, ARIMA %d\n", n["G"], n["A"]
  split("GS GC AS AC", ord, " ")
  for(i = 1; i <= 4; i++) { k = ord[i]; printf "%s %s | %s\n", k, met[k], lin[k] }
  printf "GSgemeo | %s\n", gem["GS"]
  printf "GCgemeo | %s\n", gem["GC"]
}' "$1"
