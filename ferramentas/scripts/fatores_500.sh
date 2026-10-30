#!/bin/bash
# fatores_500.sh <pasta_de_saida> [calibrar] [testar]
#
# Estudo de fatores de 27/10/2026 (notas/INCERTEZAS.md, item 79): o estudo das
# janelas fixas de 26/10 (ARIMA 240, GARCH 500, janelas_240_500.sh), só compra,
# com três fatores a mais na grade, cada um com duas opções:
#   DistribuicaoGARCH       normal (0) ou t de Student (1)
#   SelecaoPorBIC           (p,q) pelo AIC ou pelo BIC
#   Barras_Entre_Reselecao  reavaliar as ordens a cada 21 ou 63 pregões
# A sub-grade sem GARCH não varia a distribuição (seria passagem repetida).
# Por janela: 16 passagens sem GARCH e 1.216 com GARCH (1.232).
S="$(cd "$(dirname "$0")" && pwd)"
export FATORES=$'SomenteCompra=true||false||0||true||N\nSelecaoPorBIC=false||false||0||true||Y\nDistribuicaoGARCH=0||0||1||1||Y\nBarras_Entre_Reselecao=21||21||42||63||Y'
export FATORES_ARIMA=$'SomenteCompra=true||false||0||true||N\nSelecaoPorBIC=false||false||0||true||Y\nBarras_Entre_Reselecao=21||21||42||63||Y'
export EXTRA_GARCH="DistribuicaoGARCH" EXTRA_ARIMA="SelecaoPorBIC Barras_Entre_Reselecao"
exec bash "$S/janelas_240_500.sh" "$@"
