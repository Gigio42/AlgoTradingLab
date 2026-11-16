#!/bin/bash
# heterocedasticidade.sh [pasta_saida] -> dados do gráfico de heterocedasticidade do Cap. I
#
# Pedido do autor em 02/11/2026: ilustrar a diferença entre uma série
# homocedástica e uma heterocedástica com a PETR4.
#   - PETR4: log-retorno diário (%) do fechamento de dados/series/PETR4_OFICIAL.csv
#     (campo 6), pregões de 2019-01-02 a 2021-12-30; o primeiro retorno usa o
#     fechamento de 2018-12-28.
#   - Simulada: mesma quantidade de pregões, normal (Box-Muller sobre o rand()
#     do gawk, semente fixa 20261102), média zero e desvio-padrão igual ao
#     desvio-padrão amostral dos retornos da PETR4 no período. Variância
#     constante por construção. O rand() depende da implementação do awk:
#     o CSV gravado é o registro (gerado com GNU Awk 5.4.1).
# Saída: <pasta>/serie.csv (data,petr4,simulada) e <pasta>/resumo.txt (desvio-padrão
# do período, de cada ano e de cada mês).
set -e
raiz="$(cd "$(dirname "$0")/../.." && pwd)"
out="${1:-$raiz/dados/resultados/heterocedasticidade_2026-11-02}"
mkdir -p "$out"
serie="$raiz/dados/series/PETR4_OFICIAL.csv"
LC_ALL=C gawk -F, -v semente=20261102 -v out="$out" '
  { d = $1; gsub(/\./, "-", d) }
  d >= "2019-01-01" && d <= "2021-12-31" && ant > 0 {
    n++; data[n] = d; r[n] = 100 * log($6 / ant); fech[n] = $6; fant[n] = ant
  }
  { ant = $6 }
  END {
    for (i = 1; i <= n; i++) s += r[i]; m = s / n
    for (i = 1; i <= n; i++) v += (r[i] - m)^2; dp = sqrt(v / (n - 1))
    srand(semente); pi = atan2(0, -1)
    for (i = 1; i <= n; i++) {
      u1 = rand(); while (u1 == 0) u1 = rand(); u2 = rand()
      z[i] = dp * sqrt(-2 * log(u1)) * cos(2 * pi * u2)
    }
    arq = out "/serie.csv"; print "data,petr4,simulada" > arq
    for (i = 1; i <= n; i++) printf "%s,%.4f,%.4f\n", data[i], r[i], z[i] > arq
    # resumo: desvio por ano, extremos, desvio da simulada
    for (i = 1; i <= n; i++) {
      a = substr(data[i], 1, 4); na[a]++; sa[a] += r[i]; qa[a] += r[i]^2
      sz += z[i]; qz += z[i]^2
      if (i == 1 || r[i] < rmin) { rmin = r[i]; imin = i }
      if (i == 1 || r[i] > rmax) { rmax = r[i]; imax = i }
      if (i == 1 || z[i] < zmin) zmin = z[i]
      if (i == 1 || z[i] > zmax) zmax = z[i]
    }
    res = out "/resumo.txt"
    printf "pregões: %d (%s a %s)\n", n, data[1], data[n] > res
    printf "PETR4 log-retorno (%%): média %.4f, desvio-padrão %.4f\n", m, dp > res
    for (a in na) {
      ma = sa[a] / na[a]
      printf "  %s: %d pregões, desvio-padrão %.4f\n", a, na[a], sqrt((qa[a] - na[a] * ma^2) / (na[a] - 1)) | "sort"
    }
    close("sort")
    printf "  menor: %s %.4f (fechamento %.2f -> %.2f, variação simples %.2f%%)\n", data[imin], rmin, fant[imin], fech[imin], 100 * (fech[imin] / fant[imin] - 1) > res
    printf "  maior: %s %.4f (fechamento %.2f -> %.2f, variação simples %.2f%%)\n", data[imax], rmax, fant[imax], fech[imax], 100 * (fech[imax] / fant[imax] - 1) > res
    mz = sz / n
    printf "Simulada: semente %d, média %.4f, desvio-padrão %.4f, mín %.4f, máx %.4f\n", semente, mz, sqrt((qz - n * mz^2) / (n - 1)), zmin, zmax > res
  }' "$serie" > "$out/.anos.txt"
# os desvios por ano saem pelo sort no stdout; entram no resumo depois da linha 2
{ sed -n 1,2p "$out/resumo.txt"; cat "$out/.anos.txt"; sed -n '3,$p' "$out/resumo.txt"; } > "$out/.r" && mv "$out/.r" "$out/resumo.txt"
rm -f "$out/.anos.txt"
# desvio-padrão mensal da PETR4 (para o texto: a volatilidade depois de março de 2020)
{ echo "Desvio-padrão mensal da PETR4 (%):"
  LC_ALL=C awk -F, 'NR>1{m=substr($1,1,7); n[m]++; s[m]+=$2; q[m]+=$2^2}
    END{for(m in n){mu=s[m]/n[m]; printf "  %s: %.2f\n", m, sqrt((q[m]-n[m]*mu^2)/(n[m]-1))}}' "$out/serie.csv" | LC_ALL=C sort
} >> "$out/resumo.txt"
cat "$out/resumo.txt"
