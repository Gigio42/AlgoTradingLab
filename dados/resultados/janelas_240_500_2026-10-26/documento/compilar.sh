#!/bin/bash
# Compila o documento do estudo das janelas 240/500 (só o Cap. III).
# O preâmbulo vem do tg/main.tex na hora (mesma formatação do TG, sem cópia).
# Antes: RES=<esta pasta de resultados> bash ferramentas/scripts/dados_cru.sh
set -e
cd "$(dirname "$0")"
raiz=$(cd ../../../.. && pwd)
sed -n '1,/^\\begin{document}/p' "$raiz/tg/main.tex" | sed '$d' |
  sed 's|^\\graphicspath{{figuras/}}|\\graphicspath{{graficos/}}|' > preambulo.tex
cd graficos
c() { pdflatex -interaction=nonstopmode -halt-on-error -jobname="$1" "$2" > /dev/null || { echo "falhou: $1" >&2; exit 1; }; }
c curva_T1 '\def\pre{R3_T1}\def\ar{AS}\def\comb{1}\input{curvas}'
c curva_T2 '\def\pre{R3_T2}\def\ar{AS}\def\comb{1}\input{curvas}'
c curva_R6 '\def\pre{R6}\def\ar{ARIMA}\def\comb{1}\input{curvas}'
c curva_T3 '\def\pre{R3_T3}\def\ar{AS}\def\comb{1}\input{curvas}'
c anual_T1 '\def\periodo{T1}\def\comb{1}\input{anual}'
c anual_T2 '\def\periodo{T2}\def\comb{1}\input{anual}'
c anual_R6 '\def\periodo{R6}\def\comb{1}\input{anual}'
c curva_2008 '\def\ano{2008}\def\comb{1}\input{curva_ano}'
c curva_2020 '\def\ano{2020}\def\comb{1}\input{curva_ano}'
c exposicao_2008 '\def\dados{exposicao_2008}\def\rotg{ARIMA-GARCH Sharpe}\input{exposicao}'
c exposicao_2020 '\def\dados{exposicao_2020}\def\rotg{ARIMA-GARCH Sharpe}\input{exposicao}'
rm -f *.aux *.log
cd ..
pdflatex -interaction=nonstopmode -halt-on-error estudo.tex > /dev/null
BIBINPUTS="$raiz/tg:" bibtex estudo > /dev/null
perl -i "$raiz/ferramentas/scripts/citacoes_abnt.pl" estudo.bbl
pdflatex -interaction=nonstopmode -halt-on-error estudo.tex > /dev/null
pdflatex -interaction=nonstopmode -halt-on-error estudo.tex > /dev/null
grep -c "undefined" estudo.log || true
rm -f estudo.aux estudo.bbl estudo.blg estudo.lof estudo.lot estudo.toc estudo.out estudo.brf
echo "gerado: $(pwd)/estudo.pdf"
