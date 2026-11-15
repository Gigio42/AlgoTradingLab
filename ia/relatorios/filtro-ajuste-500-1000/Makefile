# Relatório: GARCH 500 e 1000 só com filtro e ajuste, mantendo ou encerrando no veto
# (13 e 15/11/2026). Dados em dados/resultados/filtro_ajuste_500_2026-11-13/ e _1000_2026-11-15/
# (filtro_ajuste_500.sh); números por filtro_ajuste_500_dados.sh.
DADOS = ../../../dados/resultados/filtro_ajuste_500_2026-11-13/cru

.PHONY: all dados clean
all: relatorio.pdf

dados:
	bash ../../../ferramentas/scripts/filtro_ajuste_500_dados.sh

relatorio.pdf: relatorio.tex $(wildcard $(DADOS)/*)
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex

clean:
	rm -f *.aux *.log *.toc *.out
