# Relatório de estudo sobre a janela do GARCH (13/11/2026). Dados em
# dados/resultados/janelas_garch_2026-11-13/ (janelas_garch.sh, janela_garch_simulada.sh;
# números e dados dos gráficos por janelas_garch_dados.sh).
DADOS = ../../../dados/resultados/janelas_garch_2026-11-13/cru

.PHONY: all dados clean
all: relatorio.pdf

dados:
	bash ../../../ferramentas/scripts/janelas_garch_dados.sh

relatorio.pdf: relatorio.tex $(wildcard $(DADOS)/*)
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex

clean:
	rm -f *.aux *.log *.toc *.out
