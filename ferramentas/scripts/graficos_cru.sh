#!/bin/bash
# graficos_cru.sh: compila os gráficos do Cap. III na camada crua
# (tg/graficos/cru/), depois de ferramentas/scripts/dados_cru.sh.
set -e
cd "$(dirname "$0")/../../tg/graficos/cru"
c() { pdflatex -interaction=nonstopmode -halt-on-error -jobname="$1" "$2" > /dev/null || { echo "falhou: $1" >&2; exit 1; }; }
c curva_T1 '\def\pre{R3_T1}\def\ar{AS}\def\comb{0}\input{curvas}'
c curva_T2 '\def\pre{R3_T2}\def\ar{AS}\def\comb{1}\input{curvas}'
c curva_R6 '\def\pre{R6}\def\ar{ARIMA}\def\comb{1}\input{curvas}'
c curva_T3 '\def\pre{R3_T3}\def\ar{AS}\def\comb{1}\input{curvas}'
c anual_T1 '\def\periodo{T1}\def\comb{0}\input{anual}'
c anual_T2 '\def\periodo{T2}\def\comb{1}\input{anual}'
c anual_R6 '\def\periodo{R6}\def\comb{1}\input{anual}'
c curva_2008 '\def\ano{2008}\def\comb{0}\input{curva_ano}'
c curva_2020 '\def\ano{2020}\def\comb{1}\input{curva_ano}'
c exposicao_2008 '\def\dados{exposicao_2008}\input{exposicao}'
c exposicao_2020 '\def\dados{exposicao_2020}\def\rotg{ARIMA-GARCH Sharpe}\input{exposicao}'
rm -f *.aux *.log
ls *.pdf
