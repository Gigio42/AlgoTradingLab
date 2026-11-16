# Proposta de figura para a Integração entre ARIMA e GARCH, Cap. I (12/11/2026). Fora do TG até o autor decidir.
FIGURAS = fig-integracao-a.pdf fig-integracao-b.pdf fig-integracao-c.pdf fig-integracao-d.pdf fig-integracao-e.pdf fig-integracao-f.pdf fig-integracao-g.pdf fig-integracao-h.pdf

.PHONY: all clean
all: relatorio.pdf fig-integracao-h.png

%.pdf: %.tex
	pdflatex -interaction=nonstopmode -halt-on-error $<
	rm -f $*.aux $*.log

relatorio.pdf: relatorio.tex $(FIGURAS)
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex

clean:
	rm -f *.aux *.log *.out

# PNG da proposta H para o autor copiar (300 dpi, fundo branco)
fig-integracao-h.png: fig-integracao-h.pdf
	pdftoppm -png -r 300 -singlefile fig-integracao-h.pdf fig-integracao-h
