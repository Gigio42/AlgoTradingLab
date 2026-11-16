#!/bin/bash
# serie_exemplo.sh [pasta_saida] -> dados das figuras de exemplo da série de preços
#
# Pedido do autor em 13/11/2026: uma série de preços de exemplo para a seção 1.4
# (Modelos estatísticos de séries temporais). Proposta, fora do TG
# (ia/relatorios/serie-precos/).
#   - curta.csv: os últimos 20 pregões de dados/series/PETR4_OFICIAL.csv (B3
#     COTAHIST, dados/FONTES.md itens 1 e 2), com o fechamento (campo 6) e o
#     retorno logarítmico em % sobre o fechamento do pregão anterior (o primeiro
#     usa o 21º pregão a partir do fim). Coluna "rotulo" = dd/mm, para o eixo.
#   - longa.csv: fechamento de 2019-01-02 a 2021-12-30, o mesmo período do
#     Gráfico 1 (heterocedasticidade_2026-11-02/serie.csv tem os retornos dele).
# Só lê a série: não roda o testador.
set -e
raiz="$(cd "$(dirname "$0")/../.." && pwd)"
out="${1:-$raiz/dados/resultados/serie_exemplo_2026-11-13}"
mkdir -p "$out"
serie="$raiz/dados/series/PETR4_OFICIAL.csv"

tail -n 21 "$serie" | LC_ALL=C awk -F, '
  BEGIN { print "indice,data,rotulo,fechamento,retorno" }
  NR > 1 {
    n++; d = $1; gsub(/\./, "-", d)
    printf "%d,%s,%s/%s,%.2f,%.4f\n", n, d, substr(d, 9, 2), substr(d, 6, 2), $6, 100 * log($6 / ant)
  }
  { ant = $6 }' > "$out/curta.csv"

LC_ALL=C awk -F, '
  BEGIN { print "data,fechamento" }
  { d = $1; gsub(/\./, "-", d) }
  d >= "2019-01-01" && d <= "2021-12-31" { printf "%s,%.2f\n", d, $6 }' "$serie" > "$out/longa.csv"

echo "curta.csv: $(($(wc -l < "$out/curta.csv") - 1)) pregões; longa.csv: $(($(wc -l < "$out/longa.csv") - 1)) pregões"
