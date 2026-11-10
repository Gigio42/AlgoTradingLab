# Alternativas ao Quadro 3 (05/11/2026). Fora do TG até o autor decidir.
FIGURAS = fig-grade-blocos.pdf fig-grade-barras.pdf

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
