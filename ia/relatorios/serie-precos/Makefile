# Proposta de série de preços de exemplo para a seção 1.4 (13/11/2026). Fora do TG.
FIGURAS = fig-serie-curta.pdf fig-serie-longa.pdf

.PHONY: all clean
all: relatorio.pdf

%.pdf: %.tex
	pdflatex -interaction=nonstopmode -halt-on-error $<
	rm -f $*.aux $*.log

relatorio.pdf: relatorio.tex $(FIGURAS)
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex

clean:
	rm -f *.aux *.log *.out
