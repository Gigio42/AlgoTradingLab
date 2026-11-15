# Proposta para a Figura 4 do Cap. I (etapas do ARIMA) só com o conceito (15/11/2026). Fora do TG até o autor decidir.
FIGURAS = fig-a.pdf fig-b.pdf

.PHONY: all clean
all: relatorio.pdf fig-a.png fig-b.png

%.pdf: %.tex estilo.tex
	pdflatex -interaction=nonstopmode -halt-on-error $<
	rm -f $*.aux $*.log

%.png: %.pdf
	pdftoppm -png -r 300 -singlefile $< $*

relatorio.pdf: relatorio.tex $(FIGURAS)
	pdflatex -interaction=nonstopmode -halt-on-error relatorio.tex
	pdflatex -interaction=nonstopmode -halt-on-error relatorio.tex

clean:
	rm -f *.aux *.log *.out
