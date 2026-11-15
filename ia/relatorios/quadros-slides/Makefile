# Versões de slide dos Quadros 3 e 4 do TG (13/11/2026). Fora do TG. PNG para o PowerPoint.
SLIDES = slide-quadro3.pdf slide-quadro4.pdf

.PHONY: all clean
all: relatorio.pdf $(SLIDES:.pdf=.png) slide-integracao.png

%.pdf: %.tex preambulo-slide.tex
	pdflatex -interaction=nonstopmode -halt-on-error $<
	rm -f $*.aux $*.log

%.png: %.pdf
	pdftoppm -png -r 220 -singlefile $< $*

relatorio.pdf: relatorio.tex $(SLIDES)
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex

clean:
	rm -f *.aux *.log *.out
