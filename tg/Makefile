MAIN = main
# Apêndice A: o código do EA sem comentários e sem log, diagnóstico e avaliação,
# gerado a partir do arquivo que de fato roda (nunca copiado à mão). O que sai
# fica marcado no próprio EA com //@omitir (ver codigo_apendice.sh).
EA     = ../robos/ARIMA-GARCH/ARIMA_GARCH_EA.mq5
# Apêndice B (27/10/2026): as classes e funções dos modelos, pelo mesmo processo
MODELOS = Arima SelecaoModelo Garch Estrategia
# Apêndice C (02/11/2026): o robô de médias móveis que reproduz Almeida (2016)
MM = ../robos/MediasMoveis2/MediasMoveis2.mq5
CODIGO = codigo/ARIMA_GARCH_EA.mq5 $(MODELOS:%=codigo/%.mqh) codigo/MediasMoveis2.mq5
GERADOR = ../ferramentas/scripts/codigo_apendice.sh ../ferramentas/scripts/sem_comentarios.sh

.PHONY: all clean docx

# Versão em Word (entrega à coordenação, 02/11/2026): gerada do LaTeX pelo pandoc,
# com os números e as citações do main.aux e do main.bbl, por isso depende do PDF.
DOCX = ../ferramentas/scripts/docx
docx: $(MAIN).docx

$(MAIN).docx: $(MAIN).pdf $(wildcard $(DOCX)/*)
	bash $(DOCX)/converter.sh . $@

# Diagramas em TikZ (fonte .tex em figuras/): Cap. I desde 27/10/2026, linha do
# tempo dos períodos (Cap. II) desde 05/11/2026
FIGURAS = figuras/fig02-fluxograma-ea.pdf figuras/fig05-fluxo-arima.pdf figuras/fig06-fluxo-garch.pdf \
          figuras/fig07-periodos.pdf
# Gráfico de heterocedasticidade do Cap. I (02/11/2026), com os dados de
# ferramentas/scripts/heterocedasticidade.sh
GRAFICOS = graficos/heterocedasticidade.pdf

all: $(MAIN).pdf

codigo/ARIMA_GARCH_EA.mq5: $(EA) $(GERADOR)
	mkdir -p codigo
	bash ../ferramentas/scripts/codigo_apendice.sh $(EA) > $@

codigo/MediasMoveis2.mq5: $(MM) $(GERADOR)
	mkdir -p codigo
	bash ../ferramentas/scripts/codigo_apendice.sh $(MM) > $@

codigo/%.mqh: ../robos/Include/%.mqh $(GERADOR)
	mkdir -p codigo
	bash ../ferramentas/scripts/codigo_apendice.sh $< > $@

$(MAIN).pdf: $(MAIN).tex referencias.bib conteudo/*.tex ../ferramentas/scripts/citacoes_abnt.pl $(CODIGO) graficos/rodada3/*.pdf $(FIGURAS) $(GRAFICOS)
	pdflatex -interaction=nonstopmode -halt-on-error $(MAIN).tex
	bibtex $(MAIN)
	perl -i ../ferramentas/scripts/citacoes_abnt.pl $(MAIN).bbl
	pdflatex -interaction=nonstopmode -halt-on-error $(MAIN).tex
	pdflatex -interaction=nonstopmode -halt-on-error $(MAIN).tex

figuras/%.pdf: figuras/%.tex
	cd figuras && pdflatex -interaction=nonstopmode -halt-on-error $*.tex && rm -f $*.aux $*.log

graficos/heterocedasticidade.pdf: graficos/heterocedasticidade.tex ../dados/resultados/heterocedasticidade_2026-11-02/serie.csv
	cd graficos && pdflatex -interaction=nonstopmode -halt-on-error heterocedasticidade.tex && rm -f heterocedasticidade.aux heterocedasticidade.log

clean:
	rm -f *.aux *.bbl *.blg *.log *.lof *.lot *.toc *.out *.brf \
	      *.synctex.gz conteudo/*.aux
