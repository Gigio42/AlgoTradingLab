# O GARCH funcionando (06/11/2026). Fora do TG até o autor decidir.
# Dados: ../../../dados/resultados/modelo_completo_2026-11-06 (ferramentas/scripts/modelo_completo.sh).
# Preâmbulo da figura: ../modelo-completo/comum.tex.
FIGURAS = fig-garch.pdf

.PHONY: all clean
all: relatorio.pdf

%.pdf: %.tex ../modelo-completo/comum.tex
	lualatex -interaction=nonstopmode -halt-on-error $<
	rm -f $*.aux $*.log

relatorio.pdf: relatorio.tex $(FIGURAS)
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex

clean:
	rm -f *.aux *.log *.out
