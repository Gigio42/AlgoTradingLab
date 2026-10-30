# Gráficos que explicam os métodos do robô (30/10/2026). Os dados das figuras
# 01 a 07 vêm de dados/resultados/metodos_ilustrados_2026-10-30/
# (ferramentas/scripts/metodos_ilustrados.sh); os das 08 a 14, de
# dados/resultados/robo_em_acao_2026-10-30/ (ferramentas/scripts/robo_em_acao.sh).
# lualatex por causa das curvas de nível ("contour lua").
# Saída: PDF (vetorial, para LaTeX) e PNG a 300 dpi (para os slides).
FIGURAS = 01_mqo 02_hannan_rissanen 03_verossimilhanca 04_otimizacao 05_ljung_box 06_adf 07_aic \
          08_um_pregao 09_previsao_arima 10_reestimacao 11_garch_no_tempo 12_mapa_decisao \
          13_exposicao 14_memoria_garch
DADOS   = ../../dados/resultados/metodos_ilustrados_2026-10-30 ../../dados/resultados/robo_em_acao_2026-10-30

.PHONY: all clean
all: $(FIGURAS:%=%.png)

%.pdf: %.tex comum.tex $(foreach d,$(DADOS),$(wildcard $(d)/*))
	lualatex -interaction=nonstopmode -halt-on-error $<

%.png: %.pdf
	pdftoppm -png -r 300 -singlefile $< $*

clean:
	rm -f *.aux *.log *_contourtmp*
