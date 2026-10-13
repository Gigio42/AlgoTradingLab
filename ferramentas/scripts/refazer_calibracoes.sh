#!/bin/bash
# Refaz TODAS as otimizacoes (calibracao e teste de cada configuracao da grade)
# com o EA corrigido em 05/10/2026 (ver notas/INCERTEZAS.md, itens 43 e 44).
#
#  1. Rodada 4 completa: 4 ativos x 6 janelas (C1 T1 C2 T2 C3 T3) x 7 sub-grades,
#     688 configuracoes por janela (a grade da rodada 3 + venda a descoberto).
#     A rodada 3 e o subconjunto PETR4 com SomenteCompra=1, entao nao precisa
#     ser rodada a parte.
#  2. Calibracao C4 (2014-2016, so PETR4, grade da rodada 3) para o teste de
#     2017-2024.
#  3. Junta as passagens de cada janela num CSV so, em <saida>/calibracao/.
#
# Uso: bash refazer_calibracoes.sh <pasta_de_saida>
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
OUT="$1"; [ -n "$OUT" ] || { echo "uso: $0 <pasta_de_saida>"; exit 1; }
mkdir -p "$OUT/calibracao" "$OUT/grades"

# Sub-grades da rodada 4 (as da rodada 3 + SomenteCompra variando)
mkdir -p "$TRAB/sub"
for g in arima filtro_abs filtro_pct targ ic ft_abs ft_pct; do
  cp "$A/dados/resultados/rodada4_multiativos/grades/$g.txt" "$TRAB/sub/$g.txt"
  cp "$TRAB/sub/$g.txt" "$OUT/grades/r4_$g.txt"
  cp "$A/dados/resultados/rodada3_b3_oficial/grades/$g.txt" "$OUT/grades/r3_$g.txt"
done

# Passagens antigas nao podem se misturar com as novas
[ -d "$TRAB/g" ] && mv "$TRAB/g" "$TRAB/g_antigo_$(date +%s)"

echo "inicio $(date '+%F %T')"
bash "$S/bateria_ativos.sh" PETR4 VALE3 USIM5 POMO4
bash "$S/calib_2014_2016.sh"

# Um CSV por ativo e janela: o cabecalho uma vez, uma linha por passagem
for d in "$TRAB"/g/*_OFICIAL_*; do
  n=$(basename "$d" | sed 's/_OFICIAL//')
  f=$(ls "$d" | head -1); [ -n "$f" ] || continue
  { head -1 "$d/$f"; for x in "$d"/res_*; do sed -n 2p "$x"; done; } | tr -d '\r' > "$OUT/calibracao/$n.csv"
  echo "$n: $(( $(wc -l < "$OUT/calibracao/$n.csv") - 1 )) passagens"
done
echo "fim $(date '+%F %T')"
