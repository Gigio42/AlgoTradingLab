#!/bin/bash
# estudo_janelas_dados.sh
#
# Gera os dados do documento do estudo das janelas fixas 240/500 (26/10/2026,
# ia/INCERTEZAS.md item 78), com os mesmos scripts do Cap. III do TG, depois
# de janelas_240_500.sh (calibrar e testar). Nada é simulado aqui.
# Saída em dados/resultados/janelas_240_500_2026-10-26/:
#   cru/                  dados_cru.sh, outras_acoes.sh, saldo_mt5.txt,
#                         analise_grades_cru.txt (CAMADA=puro), traco_resumo.txt,
#                         mecanismo.txt (vetos, sinais, exposição, acerto)
#   pareados/             parear.sh, calibração × teste de cada ação e janela
#   comparacao_tg.txt     comparar_janelas.sh (TG atual × estudo)
# Uso (da raiz do repositório): bash ferramentas/scripts/estudo_janelas_dados.sh
set -e
raiz=$(cd "$(dirname "$0")/../.." && pwd)
S="$raiz/ferramentas/scripts"
export RES="$raiz/dados/resultados/janelas_240_500_2026-10-26"
REF="$raiz/dados/resultados/refeito_2026-10-05"
O="$RES/cru"; mkdir -p "$O" "$RES/pareados"

bash "$S/dados_cru.sh"
SEM_IC=1 bash "$S/outras_acoes.sh"
bash "$S/saldo_mt5.sh" "$RES"/relatorios_mt5/rel_*.htm > "$O/saldo_mt5.txt"

args=()
for a in PETR4 VALE3 USIM5 POMO4; do for j in 1 2 3; do
  p="$RES/pareados/${a}_C${j}_T$j.csv"
  bash "$S/parear.sh" "$RES/calibracao/${a}_C$j.csv" "$RES/calibracao/${a}_T$j.csv" > "$p"
  args+=("$a:T$j:$p")
done; done
CAMADA=puro SEM_IC=1 bash "$S/analisar_grades.sh" "${args[@]}" > "$O/analise_grades_cru.txt"

# GARCH sobre 240 resíduos (traço da refação, só de 07/2019 a 06/2021) × sobre
# 500 (traço deste estudo, 2017-2024 inteiro), no mesmo intervalo e no período todo.
{ echo "== TG atual (traco_demo_GARCH, GARCH sobre os resíduos da janela do ARIMA)"
  bash "$S/traco_resumo.sh" "$REF/traco_demo/traco_demo_GARCH.csv" 2019.07.01 2021.06.30
  echo; echo "== Estudo (traco_R6_GS, GARCH sobre 500 resíduos)"
  bash "$S/traco_resumo.sh" "$RES/traco/traco_R6_GS.csv" 2019.07.01 2021.06.30
  echo; bash "$S/traco_resumo.sh" "$RES/traco/traco_R6_GS.csv" 2017.01.01 2024.12.31
  echo; echo "== Estudo, 03/04/2020"
  LC_ALL=C awk -F';' 'NR == 1 { print; next } $1 == "2020.04.03"' "$RES/traco/traco_R6_GS.csv"
} > "$O/traco_resumo.txt"

{ echo "rotulo saidas taxa_acerto vetos sinais exposicao"
  for f in "$RES"/testes/metricas_*.csv; do
    LC_ALL=C awk -F';' -v r="$(basename "$f" .csv | sed 's/^metricas_//')" '
      NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; next }
      { printf "%-14s %4d %5.1f%% %5s %5s %5.1f%%\n", r, $h["saidas"], 100 * $h["taxa_acerto"],
               ("vetos" in h ? $h["vetos"] : "-"), ("sinais" in h ? $h["sinais"] : "-"), 100 * $h["exposicao"] }' "$f"
  done
} > "$O/mecanismo.txt"

bash "$S/comparar_janelas.sh" > "$RES/comparacao_tg.txt"
echo "gerado em $RES"
