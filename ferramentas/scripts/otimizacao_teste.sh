#!/bin/bash
# otimizacao_teste.sh [pasta_saida]
#
# Dados do gráfico "otimização × teste" do relatório de estudo
# ia/relatorios/otimizacao/ (02/11/2026, pedido do autor). Não roda nada no
# MetaTrader: só lê os pareados da refação de 05/10/2026
# (dados/resultados/refeito_2026-10-05/pareados/PETR4_C*_T*.csv), que juntam,
# configuração a configuração, a passagem da otimização (_c) e a do teste (_t).
#
# Recorte = a grade do TG: só compra e sem o intervalo de confiança
# (Estrategia=2 com GARCH), 312 configurações (304 com GARCH, 8 sem).
# Métricas = as dos critérios de escolha (Sharpe e Calmar com custos e caixa na
# Selic, colunas sharpe/calmar do OnTester).
#
# Saída:
#   pontos_T1.csv, pontos_T2.csv, pontos_T3.csv  (vírgula; um ponto por configuração)
#   valores.tex  (macros: escolhidas, posição delas no teste, medianas, Spearman)
#   resumo.txt   (o mesmo, legível)
# A escolha é refeita aqui com a regra do escolher.sh (maior valor; desempate
# por menos negócios) e conferida contra escolhas/r3_C*.txt.
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
ORIG="$RAIZ/dados/resultados/refeito_2026-10-05"
SAIDA="${1:-$RAIZ/dados/resultados/otimizacao_teste_2026-11-02}"
mkdir -p "$SAIDA"
: > "$SAIDA/valores.tex"
: > "$SAIDA/resumo.txt"

for par in 1 2 3; do
  arq="$ORIG/pareados/PETR4_C${par}_T${par}.csv"
  esc="$ORIG/escolhas/r3_C${par}.txt"
  L=$(echo "x ABC" | cut -c$((par + 2)))   # T1→A, T2→B, T3→C (macro sem dígito)
  LC_ALL=C gawk -F';' -v ic="${INCLUIR_IC:-0}" -v L="$L" -v T="T$par" -v saida="$SAIDA" -v escarq="$esc" '
  function col(n) { if(!(n in h)) { print "coluna ausente: " n > "/dev/stderr"; exit 1 } return $h[n] }
  # posto médio (empates recebem a média), 1 = menor
  function postos(v, r, n,   i, j, k, idx, tmp) {
    for(i = 1; i <= n; i++) idx[i] = i
    # ordenação por inserção nos índices (n = 312, custo irrelevante)
    for(i = 2; i <= n; i++) { k = idx[i]; j = i - 1
      while(j >= 1 && v[idx[j]] + 0 > v[k] + 0) { idx[j + 1] = idx[j]; j-- }
      idx[j + 1] = k }
    i = 1
    while(i <= n) { j = i
      while(j < n && v[idx[j + 1]] + 0 == v[idx[i]] + 0) j++
      for(k = i; k <= j; k++) r[idx[k]] = (i + j) / 2
      i = j + 1 }
  }
  function pearson(a, b, n,   i, ma, mb, sab, saa, sbb) {
    for(i = 1; i <= n; i++) { ma += a[i]; mb += b[i] } ma /= n; mb /= n
    for(i = 1; i <= n; i++) { sab += (a[i]-ma)*(b[i]-mb); saa += (a[i]-ma)^2; sbb += (b[i]-mb)^2 }
    return sab / sqrt(saa * sbb)
  }
  function mediana(v, n,   i, w) { for(i = 1; i <= n; i++) w[i] = v[i] + 0; asort(w)
    return (n % 2) ? w[(n + 1) / 2] : (w[n / 2] + w[n / 2 + 1]) / 2 }
  # quantas configurações tiveram resultado ESTRITAMENTE melhor no teste (+1 = posição)
  function posicao(v, n, x,   i, c) { for(i = 1; i <= n; i++) if(v[i] + 0 > x + 0) c++; return c + 1 }
  function chave() { return sprintf("E%s P%s V%s Z%s J%s K%s S%s", col("Estrategia"), col("Limiar_Percentil") + 0,
      col("Vol_Alvo") + 0, col("ZerarNoVeto"), col("Janela_Estimacao"), col("IncluirConstante"), col("Limiar_Sinal") + 0) }
  BEGIN {
    # as escolhas oficiais (GS e GC), lidas do arquivo do refazer_testes.sh
    while((getline lin < escarq) > 0) {
      if(lin !~ /^G[SC] /) continue
      tipo = substr(lin, 1, 2); split(lin, partes, "|"); s = partes[2]
      m = ""
      n2 = split(s, kv, " ")
      for(i = 1; i <= n2; i++) { split(kv[i], q, "="); P[q[1]] = q[2] }
      bo = (P["ZerarNoVeto"] == "true") ? 1 : 0; bk = (P["IncluirConstante"] == "true") ? 1 : 0
      oficial[tipo] = sprintf("E%s P%s V%s Z%s J%s K%s S%s", P["Estrategia"], P["Limiar_Percentil"] + 0,
                              P["Vol_Alvo"] + 0, bo, P["Janela_Estimacao"], bk, P["Limiar_Sinal"] + 0)
    }
  }
  NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i
            print "garch,sharpe_otim,sharpe_teste,calmar_otim,calmar_teste" > (saida "/pontos_" T ".csv"); next }
  col("SomenteCompra") + 0 != 1 { next }
  !ic && col("UsarGARCH") + 0 == 1 && col("Estrategia") + 0 == 2 { next }
  {
    n++; g = col("UsarGARCH") + 0
    sc[n] = col("sharpe_c"); st[n] = col("sharpe_t"); cc[n] = col("calmar_c"); ct[n] = col("calmar_t")
    ng[n] = col("negocios_c"); ch[n] = chave(); ga[n] = g
    if(g) ngarch++
    printf "%d,%s,%s,%s,%s\n", g, sc[n], st[n], cc[n], ct[n] > (saida "/pontos_" T ".csv")
    if(g) {
      if(!bs || sc[n] + 0 > sc[bs] + 0 || (sc[n] + 0 == sc[bs] + 0 && ng[n] + 0 < ng[bs] + 0)) bs = n
      if(!bc || cc[n] + 0 > cc[bc] + 0 || (cc[n] + 0 == cc[bc] + 0 && ng[n] + 0 < ng[bc] + 0)) bc = n
    }
  }
  END {
    if(ch[bs] != oficial["GS"] || ch[bc] != oficial["GC"]) {
      print "ERRO " T ": escolha refeita difere da oficial: " ch[bs] " / " oficial["GS"] " ; " ch[bc] " / " oficial["GC"] > "/dev/stderr"; exit 1 }
    postos(sc, rsc, n); postos(st, rst, n); postos(cc, rcc, n); postos(ct, rct, n)
    rhoS = pearson(rsc, rst, n); rhoC = pearson(rcc, rct, n)
    medS = mediana(st, n); medC = mediana(ct, n)
    posS = posicao(st, n, st[bs]); posC = posicao(ct, n, ct[bc])
    tex = saida "/valores.tex"; res = saida "/resumo.txt"
    printf "\\def\\n%s{%d}\\def\\ngarch%s{%d}\n", L, n, L, ngarch >> tex
    printf "\\def\\gsx%s{%s}\\def\\gsy%s{%s}\\def\\gcx%s{%s}\\def\\gcy%s{%s}\n", L, sc[bs], L, st[bs], L, cc[bc], L, ct[bc] >> tex
    printf "\\def\\posS%s{%d}\\def\\posC%s{%d}\n", L, posS, L, posC >> tex
    printf "\\def\\medS%s{%.4f}\\def\\medC%s{%.4f}\n", L, medS, L, medC >> tex
    printf "\\def\\rhoS%s{%.2f}\\def\\rhoC%s{%.2f}\n", L, rhoS, L, rhoC >> tex
    printf "%s: %d configurações (%d com GARCH)\n", T, n, ngarch >> res
    printf "  Sharpe: escolhida %s (otim. %s, teste %s), %dª de %d no teste; mediana do teste %.4f; Spearman %.2f\n", ch[bs], sc[bs], st[bs], posS, n, medS, rhoS >> res
    printf "  Calmar: escolhida %s (otim. %s, teste %s), %dª de %d no teste; mediana do teste %.4f; Spearman %.2f\n", ch[bc], cc[bc], ct[bc], posC, n, medC, rhoC >> res
  }' "$arq"
done
cat "$SAIDA/resumo.txt"
