# Proposta de figuras para o Cap. II (05/11/2026). Fora do TG até o autor decidir.
FIGURAS = fig07-periodos.pdf fig08-janela.pdf fig09-escolha.pdf

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
