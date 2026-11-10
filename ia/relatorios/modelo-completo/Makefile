# O modelo inteiro em figuras (06/11/2026). Fora do TG até o autor decidir.
# Dados: ../../../dados/resultados/modelo_completo_2026-11-06 (ferramentas/scripts/modelo_completo.sh)
# e ../../../dados/resultados/robo_em_acao_2026-10-30.
FIGURAS = fig-panorama.pdf fig-fluxo.pdf

.PHONY: all clean
all: relatorio.pdf

%.pdf: %.tex comum.tex
	lualatex -interaction=nonstopmode -halt-on-error $<
	rm -f $*.aux $*.log

relatorio.pdf: relatorio.tex $(FIGURAS)
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex

clean:
	rm -f *.aux *.log *.out
