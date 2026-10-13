MAIN = main
# Apêndice A: o código do EA sem comentários e sem log, diagnóstico e avaliação,
# gerado a partir do arquivo que de fato roda (nunca copiado à mão). O que sai
# fica marcado no próprio EA com //@omitir (ver codigo_apendice.sh).
EA     = ../ARIMA-GARCH/ARIMA_GARCH_EA.mq5
CODIGO = codigo/ARIMA_GARCH_EA.mq5

.PHONY: all clean

all: $(MAIN).pdf

$(CODIGO): $(EA) ../ferramentas/scripts/codigo_apendice.sh ../ferramentas/scripts/sem_comentarios.sh
	mkdir -p codigo
	bash ../ferramentas/scripts/codigo_apendice.sh $(EA) > $@

$(MAIN).pdf: $(MAIN).tex referencias.bib conteudo/*.tex ../ferramentas/scripts/citacoes_abnt.pl $(CODIGO) graficos/rodada3/*.pdf
	pdflatex -interaction=nonstopmode -halt-on-error $(MAIN).tex
	bibtex $(MAIN)
	perl -i ../ferramentas/scripts/citacoes_abnt.pl $(MAIN).bbl
	pdflatex -interaction=nonstopmode -halt-on-error $(MAIN).tex
	pdflatex -interaction=nonstopmode -halt-on-error $(MAIN).tex

clean:
	rm -f *.aux *.bbl *.blg *.log *.lof *.lot *.toc *.out *.brf \
	      *.synctex.gz conteudo/*.aux
