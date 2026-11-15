#!/bin/bash
# outras_acoes_2017_2024.sh <pasta_de_saida>
#
# Completa o teste complementar do TG com o período 2017-2024 (pergunta da
# orientadora em 10/11/2026: por que o teste complementar não tem 2017 a 2024?).
# Mesmo procedimento da refação de 05/10/2026 (refazer_calibracoes.sh), só com a
# janela que faltava:
#   C4 = 2014.01.02 a 2016.12.30 (calibração, três anos antes do teste)
#   T4 = 2017.01.02 a 2024.12.30 (teste, as datas da rodada 6 / R6 da refação)
# nas quatro ações, com a grade da rodada 4 (a da rodada 3 + venda a descoberto)
# SEM o intervalo de confiança (fora do escopo desde 21/10/2026): 624
# configurações por janela.
#
# Proteções da armadilha do .set (CLAUDE.md, 26/10/2026): toda linha numérica ou
# lógica vai com faixa explícita e N, e o .set do testador é apagado antes de
# cada otimização.
#
# Conferência embutida: o subconjunto só compra da PETR4 em C4 tem de ser igual a
# refeito_2026-10-05/calibracao/PETR4_C4.csv (a calibração do teste principal).
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
OUT="$1"; [ -n "$OUT" ] || { echo "uso: $0 <pasta_de_saida>"; exit 1; }
mkdir -p "$OUT/calibracao" "$OUT/grades"
SUBS="arima filtro_abs filtro_pct targ ft_abs ft_pct"
JAN=("C4 2014.01.02 2016.12.30" "T4 2017.01.02 2024.12.30")
explicitar(){ awk -F= '!/\|\|/ && NF==2 && $2 ~ /^(-?[0-9.]+|true|false)$/ {
    if ($2=="true"||$2=="false") print $1"="$2"||false||0||true||N"; else print $1"="$2"||"$2"||1||"$2"||N"; next } { print }'; }

mkdir -p "$TRAB/sub2017"
for g in $SUBS; do
  tr -d '\r' < "$A/dados/resultados/rodada4_multiativos/grades/$g.txt" | explicitar > "$OUT/grades/r4_$g.txt"
done
[ -d "$TRAB/g" ] && mv "$TRAB/g" "$TRAB/g_antigo_$(date +%s)"

echo "inicio $(date '+%F %T')"
for a in PETR4 VALE3 USIM5 POMO4; do
  for g in $SUBS; do
    sed "s|^Arquivo_Proventos=.*|Arquivo_Proventos=proventos_$a.csv|" "$OUT/grades/r4_$g.txt" > "$TRAB/sub2017/${a}_$g.txt"
  done
  for j in "${JAN[@]}"; do set -- $j
    for g in $SUBS; do
      rm -f "$N/MQL5/Profiles/Tester/ARIMA_GARCH_EA.set"
      bash "$S/otimizar.sh" "$1" "${a}_OFICIAL" "$2" "$3" "$TRAB/sub2017/${a}_$g.txt"
    done
  done
done

for d in "$TRAB"/g/*_OFICIAL_*; do
  n=$(basename "$d" | sed 's/_OFICIAL//')
  f=$(ls "$d" | head -1); [ -n "$f" ] || continue
  { head -1 "$d/$f"; for x in "$d"/res_*; do sed -n 2p "$x"; done; } | tr -d '\r' > "$OUT/calibracao/$n.csv"
  echo "$n: $(( $(wc -l < "$OUT/calibracao/$n.csv") - 1 )) passagens"
done
echo "fim $(date '+%F %T')"
