MAIN = main
# Apêndice A: o código do EA sem comentários e sem log, diagnóstico e avaliação,
# gerado a partir do arquivo que de fato roda (nunca copiado à mão). O que sai
# fica marcado no próprio EA com //@omitir (ver codigo_apendice.sh).
EA     = ../ARIMA-GARCH/ARIMA_GARCH_EA.mq5
# Apêndice B (27/10/2026): as classes e funções dos modelos, pelo mesmo processo
MODELOS = Arima SelecaoModelo Garch Estrategia
CODIGO = codigo/ARIMA_GARCH_EA.mq5 $(MODELOS:%=codigo/%.mqh)
GERADOR = ../ferramentas/scripts/codigo_apendice.sh ../ferramentas/scripts/sem_comentarios.sh

.PHONY: all clean

# Diagramas do Cap. I em TikZ (fonte .tex em figuras/, desde 27/10/2026)
FIGURAS = figuras/fig02-fluxograma-ea.pdf figuras/fig05-fluxo-arima.pdf figuras/fig06-fluxo-garch.pdf

all: $(MAIN).pdf

codigo/ARIMA_GARCH_EA.mq5: $(EA) $(GERADOR)
	mkdir -p codigo
	bash ../ferramentas/scripts/codigo_apendice.sh $(EA) > $@

codigo/%.mqh: ../Include/%.mqh $(GERADOR)
	mkdir -p codigo
	bash ../ferramentas/scripts/codigo_apendice.sh $< > $@

$(MAIN).pdf: $(MAIN).tex referencias.bib conteudo/*.tex ../ferramentas/scripts/citacoes_abnt.pl $(CODIGO) graficos/rodada3/*.pdf $(FIGURAS)
	pdflatex -interaction=nonstopmode -halt-on-error $(MAIN).tex
	bibtex $(MAIN)
	perl -i ../ferramentas/scripts/citacoes_abnt.pl $(MAIN).bbl
	pdflatex -interaction=nonstopmode -halt-on-error $(MAIN).tex
	pdflatex -interaction=nonstopmode -halt-on-error $(MAIN).tex

figuras/%.pdf: figuras/%.tex
	cd figuras && pdflatex -interaction=nonstopmode -halt-on-error $*.tex && rm -f $*.aux $*.log

clean:
	rm -f *.aux *.bbl *.blg *.log *.lof *.lot *.toc *.out *.brf \
	      *.synctex.gz conteudo/*.aux
