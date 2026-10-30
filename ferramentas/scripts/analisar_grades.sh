#!/bin/bash
# analisar_grades.sh <ATIVO:PERIODO:pareado.csv> ...
#
# Analise das grades pareadas (calibracao x teste), em awk. Substitui as
# analises em pandas das rodadas 3 e 4 (que ficavam fora do repositorio).
# Todas as medidas sao da camada 3 (custos + caixa na Selic), no TESTE:
#
#  1. Referencias de cada ativo e periodo (Selic, buy-and-hold).
#  2. Efeito pareado do GARCH: cada configuracao com GARCH contra a gemea
#     (mesmo ativo, periodo, janela, constante, limiar de sinal e sentido),
#     separando as variantes que REDUZEM a posicao (targeting, filtro+targeting
#     ou zerar no veto) das que so impedem novas entradas.
#  3. Venda a descoberto: mesma configuracao com e sem (long-short - so compra).
#  4. Ruina (patrimonio zerado: ret_selic <= -99%).
#  5. Persistencia: correlacao de postos (Spearman) entre a calibracao e o
#     teste, do Sharpe e do Calmar, so-compra e todas.
#  6. Volatilidade pareada (vol_selic, anualizada): GARCH - gemea, mesma
#     separacao do bloco 2 (acrescentado em 13/10/2026).
# CAMADA=puro (variavel de ambiente) troca dd, ret e vol da camada 3 pelos da
# camada 1 (crua); o padrao continua sendo a camada 3 (acrescentado em 19/10/2026).
# SEM_IC=1 descarta as passagens com intervalo de confianca (Estrategia=2),
# fora do escopo do TG desde 21/10/2026, a pedido do autor; o padrao (SEM_IC
# vazio) mantem todas e reproduz as saidas anteriores.
# Diferencas: dDD e dRet em fracao (0,10 = 10 p.p.), dSR em unidades de Sharpe.
ARQS=(); for a in "$@"; do ARQS+=("${a#*:*:}"); done
gawk -F';' -v cam="${CAMADA:-selic}" -v semic="${SEM_IC:-0}" -v rot="$(for a in "$@"; do printf '%s ' "${a%:*}"; done)" '
BEGIN { nrot = split(rot, ROT, " ") }
function col(c) { return (c in h) ? h[c] : ((c "_c") in h ? h[c "_c"] : 0) }
function med(a, n,   b, m) { if(n == 0) return "nan"; m = asort(a, b)
  return (m % 2) ? b[(m + 1) / 2] : (b[m / 2] + b[m / 2 + 1]) / 2 }
function postos(x, n, r,   i, j, k, ix, s) {   # postos medios (empates)
  for(i = 1; i <= n; i++) ix[i] = i
  # ordena indices pelo valor (insercao, n <= 700)
  for(i = 2; i <= n; i++) { k = ix[i]; j = i - 1
    while(j >= 1 && x[ix[j]] > x[k]) { ix[j + 1] = ix[j]; j-- } ix[j + 1] = k }
  i = 1
  while(i <= n) { j = i; while(j < n && x[ix[j + 1]] == x[ix[i]]) j++
    s = (i + j) / 2; for(k = i; k <= j; k++) r[ix[k]] = s; i = j + 1 }
}
function spearman(x, y, n,   rx, ry, i, mx, my, sxy, sxx, syy) {
  if(n < 3) return "nan"
  postos(x, n, rx); postos(y, n, ry)
  for(i = 1; i <= n; i++) { mx += rx[i]; my += ry[i] } mx /= n; my /= n
  for(i = 1; i <= n; i++) { sxy += (rx[i]-mx)*(ry[i]-my); sxx += (rx[i]-mx)^2; syy += (ry[i]-my)^2 }
  return sxy / sqrt(sxx * syy)
}
BEGINFILE { split(ROT[ARGIND], R, ":"); at = R[1]; pe = R[2]; ap = at " " pe
            if(!(ap in visto)) { visto[ap] = 1; lista[++na] = ap } }
FNR == 1 { delete h; for(i = 1; i <= NF; i++) h[$i] = i
           cG = col("UsarGARCH"); cE = col("Estrategia"); cZ = col("ZerarNoVeto")
           cS = col("SomenteCompra"); cJ = col("Janela_Estimacao"); cK = col("IncluirConstante")
           cL = col("Limiar_Sinal"); next }
{
  g = $cG + 0; e = $cE + 0; z = $cZ + 0; so = $cS + 0
  if(semic == 1 && g == 1 && e == 2) next
  dd = $h["dd_" cam "_t"]; rt = $h["ret_" cam "_t"]; sr = $h["sharpe_t"]; vo = $h["vol_" cam "_t"]
  ref[ap] = sprintf("%7.1f %7.1f %6.1f %7.2f", $h["selic_t"]*100, $h["bh_preco_t"]*100,
                    $h["dd_bh_preco_t"]*100, $h["sharpe_bh_t"])
  arima = ap SUBSEP ($cJ+0) SUBSEP ($cK+0) SUBSEP ($cL+0) SUBSEP so
  if(g == 0) { DDa[arima] = dd; RTa[arima] = rt; SRa[arima] = sr; VOa[arima] = vo }
  else { m = ++nG[ap]; Gk[ap, m] = arima; Gd[ap, m] = dd; Gr[ap, m] = rt; Gs[ap, m] = sr; Gv[ap, m] = vo
         Gred[ap, m] = (e == 1 || e == 3 || z == 1) }
  # venda a descoberto: chave = todos os parametros menos SomenteCompra
  kv = ap SUBSEP g SUBSEP e SUBSEP $h["ModoLimiar"] SUBSEP $h["Limiar_Percentil"] SUBSEP \
       $h["Limiar_Absoluto"] SUBSEP $h["K_Confianca"] SUBSEP $h["Vol_Alvo"] SUBSEP z SUBSEP \
       ($cJ+0) SUBSEP ($cK+0) SUBSEP ($cL+0)
  if(so == 1) { VLd[kv] = dd; VLr[kv] = rt; VLs[kv] = sr } else { VSd[kv] = dd; VSr[kv] = rt; VSs[kv] = sr }
  ruina[pe, so] += (rt <= -0.99); nr[pe, so]++
  # persistencia
  q = ++np[ap]; Sc[ap, q] = $h["sharpe_c"]; St[ap, q] = $h["sharpe_t"]
  Cc[ap, q] = $h["calmar_c"]; Ct[ap, q] = $h["calmar_t"]; Pso[ap, q] = so
}
END {
  print "=== 1. REFERENCIAS NO TESTE (camada 3) ==="
  print "ativo periodo   selic%    b&h%  dd_bh%  sharpe_bh"
  for(i = 1; i <= na; i++) printf "%-13s %s\n", lista[i], ref[lista[i]]

  print "\n=== 2. EFEITO PAREADO DO GARCH (com GARCH - gemea) ==="
  print "ativo periodo  reduz    n    dDD  reduziu_DD     dSR  melhorou_SR    dRet"
  for(i = 1; i <= na; i++) { ap = lista[i]
    for(red = 1; red >= 0; red--) {
      delete A; delete B; delete C; n = 0; rd = 0; ms = 0
      for(m = 1; m <= nG[ap]; m++) { if(Gred[ap, m] != red || !(Gk[ap, m] in DDa)) continue
        n++; A[n] = Gd[ap, m] - DDa[Gk[ap, m]]; B[n] = Gs[ap, m] - SRa[Gk[ap, m]]
        C[n] = Gr[ap, m] - RTa[Gk[ap, m]]; rd += (A[n] < 0); ms += (B[n] > 0) }
      printf "%-13s %5s %4d %7.3f %10.3f %8.3f %11.3f %8.3f\n", ap, red ? "sim" : "nao", n,
             med(A, n), n ? rd/n : 0, med(B, n), n ? ms/n : 0, med(C, n) } }

  print "\n=== 3. VENDA A DESCOBERTO (long-short - so compra, mesma configuracao) ==="
  print "ativo periodo    n    dRet  melhorou_ret     dSR  melhorou_SR     dDD"
  for(i = 1; i <= na; i++) { ap = lista[i]; delete A; delete B; delete C; n = 0; mr = 0; ms = 0
    for(kv in VSd) { split(kv, x, SUBSEP); if(x[1] != ap || !(kv in VLd)) continue
      n++; A[n] = VSr[kv] - VLr[kv]; B[n] = VSs[kv] - VLs[kv]; C[n] = VSd[kv] - VLd[kv]
      mr += (A[n] > 0); ms += (B[n] > 0) }
    if(n) printf "%-13s %4d %7.3f %13.3f %7.3f %12.3f %7.3f\n", ap, n, med(A, n), mr/n, med(B, n), ms/n, med(C, n) }

  print "\n=== 4. RUINA NO TESTE (ret_selic <= -99%) ==="
  for(k in nr) { split(k, x, SUBSEP); printf "%s so_compra=%d  %d de %d (%.1f%%)\n", x[1], x[2], ruina[k], nr[k], 100*ruina[k]/nr[k] }

  print "\n=== 5. PERSISTENCIA CALIBRACAO -> TESTE (Spearman) ==="
  print "ativo periodo   n_so  Sharpe  Calmar |  n_todas  Sharpe  Calmar"
  for(i = 1; i <= na; i++) { ap = lista[i]
    delete a; delete b; delete c; delete d; n1 = 0
    delete a2; delete b2; delete c2; delete d2; n2 = 0
    for(q = 1; q <= np[ap]; q++) {
      n2++; a2[n2] = Sc[ap, q]; b2[n2] = St[ap, q]; c2[n2] = Cc[ap, q]; d2[n2] = Ct[ap, q]
      if(Pso[ap, q] == 1) { n1++; a[n1] = Sc[ap, q]; b[n1] = St[ap, q]; c[n1] = Cc[ap, q]; d[n1] = Ct[ap, q] } }
    printf "%-13s %6d %7.2f %7.2f | %8d %7.2f %7.2f\n", ap, n1, spearman(a, b, n1), spearman(c, d, n1),
           n2, spearman(a2, b2, n2), spearman(c2, d2, n2) }

  print "\n=== 6. VOLATILIDADE PAREADA (com GARCH - gemea; acrescentado em 13/10/2026) ==="
  print "ativo periodo  reduz    n    dVol  reduziu_vol"
  for(i = 1; i <= na; i++) { ap = lista[i]
    for(red = 1; red >= 0; red--) {
      delete A; n = 0; rv = 0
      for(m = 1; m <= nG[ap]; m++) { if(Gred[ap, m] != red || !(Gk[ap, m] in VOa)) continue
        n++; A[n] = Gv[ap, m] - VOa[Gk[ap, m]]; rv += (A[n] < 0) }
      printf "%-13s %5s %4d %7.3f %12.3f\n", ap, red ? "sim" : "nao", n, med(A, n), n ? rv/n : 0 } }
}' "${ARQS[@]}"

