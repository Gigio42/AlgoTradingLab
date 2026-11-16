# Proposta de figura para a seção 2.2 (12/11/2026). Fora do TG até o autor decidir.
FIGURAS = fig-periodos.pdf

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
