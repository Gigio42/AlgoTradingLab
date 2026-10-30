# Relatório de estudo sobre o Hannan-Rissanen (30/10/2026). Dados em
# dados/resultados/hannan_rissanen_2026-10-30/ (ferramentas/scripts/hannan_rissanen.sh)
# e dados/resultados/robo_em_acao_2026-10-30/. Duas passadas por causa do sumário.
DADOS = ../../../dados/resultados/hannan_rissanen_2026-10-30 ../../../dados/resultados/robo_em_acao_2026-10-30

.PHONY: all clean
all: relatorio.pdf

relatorio.pdf: relatorio.tex $(foreach d,$(DADOS),$(wildcard $(d)/*))
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex

clean:
	rm -f *.aux *.log *.toc *.out
