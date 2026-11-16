# Relatório de estudo sobre a otimização (02/11/2026). Dados em
# dados/resultados/otimizacao_teste_2026-11-02/ (ferramentas/scripts/otimizacao_teste.sh,
# que lê os pareados de dados/resultados/refeito_2026-10-05/).
# Duas passadas por causa das referências.
DADOS = ../../../dados/resultados/otimizacao_teste_2026-11-02

.PHONY: all dados clean
all: relatorio.pdf

dados:
	bash ../../../ferramentas/scripts/otimizacao_teste.sh

relatorio.pdf: relatorio.tex $(wildcard $(DADOS)/*)
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex

clean:
	rm -f *.aux *.log *.toc *.out
