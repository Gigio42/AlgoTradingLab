# Relatório de estudo sobre o Hannan-Rissanen. Versão 2 (02/11/2026).
# Dados em dados/resultados/hannan_rissanen_2026-10-30/ (ferramentas/scripts/hannan_rissanen.sh,
# e exemplo.tex/real_pesos_ma.csv por ferramentas/scripts/hannan_rissanen_exemplo.sh)
# e dados/resultados/robo_em_acao_2026-10-30/. Código lido de tg/codigo/ (gerado pelo
# tg/Makefile, mesma numeração dos Apêndices A e B) e de robos/Include/Numerico.mqh.
# Duas passadas por causa do sumário.
R = ../../..
DADOS = $(R)/dados/resultados/hannan_rissanen_2026-10-30 $(R)/dados/resultados/robo_em_acao_2026-10-30
CODIGO = $(R)/tg/codigo/Arima.mqh $(R)/tg/codigo/SelecaoModelo.mqh $(R)/tg/codigo/ARIMA_GARCH_EA.mq5

# Cada trecho do relatório é lido por número de linha. Se o código mudar, a linha
# indicada aqui deixa de ter o texto esperado e a compilação para: conferir os
# \trecho{...}{inicio}{fim} do relatorio.tex e atualizar esta lista.
TRECHOS = \
  "tg/codigo/Arima.mqh|77|void CArima::Diferenciar" \
  "tg/codigo/Arima.mqh|93|bool CArima::EstimarAR" \
  "tg/codigo/Arima.mqh|131|bool CArima::HannanRissanen" \
  "tg/codigo/Arima.mqh|173|int ordem_longa = " \
  "tg/codigo/Arima.mqh|182|return(false);" \
  "tg/codigo/Arima.mqh|184|int primeiro = " \
  "tg/codigo/Arima.mqh|217|return(true);" \
  "tg/codigo/Arima.mqh|220|void CArima::CalcularResiduos" \
  "tg/codigo/Arima.mqh|252|double soma_quadrados" \
  "tg/codigo/Arima.mqh|264|(MathLog(2.0 * M_PI)" \
  "tg/codigo/Arima.mqh|267|bool CArima::Ajustar" \
  "tg/codigo/Arima.mqh|308|}" \
  "tg/codigo/Arima.mqh|310|double CArima::PreverDiferenciado" \
  "tg/codigo/Arima.mqh|357|bool CArima::ObterResiduos" \
  "tg/codigo/SelecaoModelo.mqh|51|int aquecimento_comum" \
  "tg/codigo/SelecaoModelo.mqh|78|}" \
  "tg/codigo/ARIMA_GARCH_EA.mq5|60|void OnTick()" \
  "tg/codigo/ARIMA_GARCH_EA.mq5|134|void ReselecionarOrdensSeVencidas" \
  "tg/codigo/ARIMA_GARCH_EA.mq5|143|double PrevisaoDoRetorno" \
  "tg/codigo/ARIMA_GARCH_EA.mq5|150|bool EstimarVolatilidade" \
  "robos/Include/Numerico.mqh|30|for(int i = 0; i < parametros; i++)" \
  "robos/Include/Numerico.mqh|55|CAlglib::RMatrixSolve"

.PHONY: all conferir clean
all: relatorio.pdf

$(CODIGO):
	$(MAKE) -C $(R)/tg codigo/$(notdir $@)

conferir: $(CODIGO)
	@for t in $(TRECHOS); do \
	  a=$${t%%|*}; r=$${t#*|}; l=$${r%%|*}; x=$${r#*|}; \
	  sed -n "$${l}p" "$(R)/$$a" | grep -qF -- "$$x" || { echo "TRECHO FORA DO LUGAR: $$a linha $$l deveria conter '$$x'"; exit 1; }; \
	done; echo "trechos de código conferidos"

relatorio.pdf: relatorio.tex $(CODIGO) $(R)/robos/Include/Numerico.mqh $(foreach d,$(DADOS),$(wildcard $(d)/*)) | conferir
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex
	lualatex -interaction=nonstopmode -halt-on-error relatorio.tex

clean:
	rm -f *.aux *.log *.toc *.out
