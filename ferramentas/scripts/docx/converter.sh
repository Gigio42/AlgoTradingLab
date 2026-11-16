#!/bin/bash
# Gera a versão em Word do TG (tg/main.docx) a partir do LaTeX, pelo pandoc.
# Uso: bash converter.sh <pasta tg> <saida.docx>      (ou "make docx" em tg/)
#
# Trabalha numa cópia temporária: nada em tg/ é alterado. Precisa do main.aux e
# do main.bbl de uma compilação recente do PDF (o "make docx" compila antes),
# porque os números das ilustrações, das referências cruzadas e as citações saem
# deles e ficam iguais aos do PDF.
#
# Etapas: prep.pl (marcadores no LaTeX) -> pandoc + fatec.lua (estilos, seções,
# numeração) -> posprocessar.pl (XML do Word). Modelo de estilos: estilos.xml e
# montar_ref.sh; cores do código: codigo.theme. MANTER=1 guarda a pasta de
# trabalho para depuração.
set -euo pipefail
C=$(cd "$(dirname "$0")" && pwd)
TG=$(cd "$1" && pwd); OUT=$(realpath -m "$2")

# pandoc 3.8 ou mais novo (--syntax-highlighting): o do sistema (sudo pacman -S pandoc-cli) ou o binário
# oficial em ~/.local/opt (https://github.com/jgm/pandoc/releases)
versao_ok() { local v; v=$("$1" --version 2>/dev/null | head -1 | awk '{print $2}') || return 1
  [ -n "$v" ] && [ "$(printf '%s\n3.8\n' "$v" | sort -V | head -1)" = 3.8 ]; }
P=${PANDOC:-}
if [ -z "$P" ]; then
  for c in pandoc "$HOME"/.local/opt/pandoc-*/bin/pandoc; do
    if command -v "$c" >/dev/null 2>&1 && versao_ok "$c"; then P=$(command -v "$c"); fi
  done
fi
[ -n "$P" ] || { echo "pandoc 3.8+ não encontrado. Instale com: sudo pacman -S pandoc-cli" >&2; exit 1; }
for f in main.aux main.bbl; do
  [ -f "$TG/$f" ] || { echo "falta $TG/$f: compile o PDF antes (make)" >&2; exit 1; }
done

W=$(mktemp -d)
if [ -n "${MANTER:-}" ]; then echo "pasta de trabalho mantida: $W"; else trap 'rm -rf "$W"' EXIT; fi
cp -r "$TG" "$W/tg"
# as capturas do MetaTrader do Cap. III ficam em dados/ (caminho relativo ../dados)
mkdir -p "$W/dados/resultados/refeito_2026-10-05"
cp -r "$TG/../dados/resultados/refeito_2026-10-05/relatorios_mt5" "$W/dados/resultados/refeito_2026-10-05/"
cd "$W/tg"

# Word não exibe PDF como imagem: gráficos e fluxogramas viram PNG de 300 dpi
for f in figuras/*.pdf graficos/*.pdf graficos/cru/*.pdf; do pdftocairo -png -r 300 -singlefile "$f" "${f%.pdf}"; done
sed -i -E 's/(\\includegraphics(\[[^]]*\])?\{[^}]*)\.pdf\}/\1.png}/; s#\{\.\./graficos/#{graficos/#' conteudo/*.tex
sed -i -E 's#\\includegraphics(\[[^]]*\])?\{(fig[0-9][^}]*)\}#\\includegraphics\1{figuras/\2}#' conteudo/*.tex

# citações e referências: as do main.bbl (já com o citacoes_abnt.pl aplicado)
perl "$C/bbl.pl" "$TG/main.bbl" "$W"
cp "$W/refs.tex" refs.tex
# macros do abnTeX2 que o pandoc não conhece e o lugar das referências
perl -0pi -e 's/\\begin\{document\}/\\newcommand{\\fonte}[1]{\\par \\textbf{Fonte:} #1\\par}\n\\newcommand{\\nota}[1]{\\par \\textbf{Nota:} #1\\par}\n\\begin{document}/; s/\\bibliography\{referencias\}/\n\n\@\@REFS\@\@\n\n\\input{refs}\n\n\@\@FIMREFS\@\@\n\n/; s/\\partapendices//; s/\\(begin|end)\{apendicesenv\}//g' main.tex
perl "$C/prep.pl" "$TG/main.aux" "$W/citas.tsv" main.tex conteudo/*.tex

bash "$C/montar_ref.sh" "$P" "$W/ref.docx"
"$P" main.tex -f latex -t docx -o "$W/bruto.docx" \
  --reference-doc="$W/ref.docx" --lua-filter="$C/fatec.lua" -M lang=pt-BR \
  --syntax-highlighting="$C/codigo.theme" \
  --figure-caption-position=above --table-caption-position=above \
  --resource-path=.:figuras:graficos

# ajustes no XML que o pandoc não faz
mkdir "$W/x"; (cd "$W/x" && bsdtar -xf "$W/bruto.docx")
TITULO=$(perl -0ne 'print $1 if /pdftitle=\{([^}]*)\}/' main.tex)
AUTORES=$(perl -0ne 'print $1 if /pdfauthor=\{([^}]*)\}/' main.tex)
perl "$C/posprocessar.pl" "$W/x" "$TITULO" "$AUTORES"
for f in "$W"/x/word/*.xml; do xmllint --noout "$f"; done
rm -f "$OUT"
(cd "$W/x" && bsdtar --format zip -cf "$OUT" '[Content_Types].xml' _rels docProps word)
echo "gerado: $OUT ($("$P" --version | head -1))"
