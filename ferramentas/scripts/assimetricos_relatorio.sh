#!/bin/bash
# assimetricos_relatorio.sh [pasta]  (18/11/2026)
# Monta ia/relatorios/assimetricos/relatorio.html a partir do modelo.html e dos
# arquivos do estudo: os CSVs e textos entram na pagina sem alteracao, dentro de
# <script type="text/plain">, e o JavaScript da pagina desenha tabelas e graficos.
# O texto de leitura (<!--LEITURA-->) vem de leitura.html, ao lado do modelo.
set -euo pipefail
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
P="${1:-$A/dados/resultados/assimetricos_2026-11-18}"; R="$A/ia/relatorios/assimetricos"
bash "$S/assimetricos_resumo.sh" "$P" > /dev/null
bloco(){ printf '<script type="text/plain" id="%s">\n' "$1"; tr -d '\r' < "$2"; printf '</script>\n'; }
{
  while IFS= read -r l; do
    case "$l" in
      '<!--LEITURA-->') [ -s "$R/leitura.html" ] && cat "$R/leitura.html" ;;
      '<!--DADOS-->')
        bloco csv-testes "$P/cru/testes.csv"; bloco csv-pares "$P/cru/pares.csv"
        bloco csv-impacto "$P/validacao/valid_assim_impacto.csv"; bloco csv-petr4 "$P/validacao/valid_assim_petr4.csv"
        bloco txt-validacao "$P/validacao/valid_assim_resumo.txt"; bloco txt-conferencias "$P/cru/conferencias.txt" ;;
      *) printf '%s\n' "$l" ;;
    esac
  done < "$R/modelo.html"
} > "$R/relatorio.html"
echo "gravado $R/relatorio.html ($(wc -c < "$R/relatorio.html") bytes)"
