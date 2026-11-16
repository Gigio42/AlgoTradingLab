#!/bin/bash
# Verificacao da maxima verossimilhanca do ARIMA (ferramentas/VerificarMV_EA.mq5):
# (ferramentas/VerificarMV_EA.mq5). Roda no TESTADOR, como o
# validar_garch_t.sh: o calculo e todo no OnInit, e script pelo [StartUp] nao
# abre com o perfil de graficos cheio (ia/INCERTEZAS.md, item 54).
# Uso: bash validar_mv.sh <arquivo_de_saida>
source "$(dirname "$0")/comum.sh"
A="$(cd "$(dirname "$0")/../.." && pwd)"
[ -n "$1" ] || { echo "uso: $0 <arquivo_de_saida>"; exit 1; }
SAIDA="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
rm -f "$COMUM/verificacao_mv.txt"
cp "$A/ferramentas/VerificarMV_EA.mq5" "$N/MQL5/Experts/"
( cd "$N" && WINEPREFIX=~/.wine-mt5-novo wine MetaEditor64.exe /compile:"MQL5\Experts\VerificarMV_EA.mq5" /log >/dev/null 2>&1 )
iconv -f UTF-16LE -t UTF-8 "$N/MQL5/Experts/VerificarMV_EA.log" | grep -E "error|Result:"
ini="$TRAB/verificar_mv.ini"
{ printf '%s[Tester]\r\n' "$CONTA"
  printf 'Expert=VerificarMV_EA\r\nSymbol=PETR4_OFICIAL\r\nPeriod=D1\r\nModel=2\r\nFromDate=2026.09.21\r\nToDate=2026.09.30\r\nDeposit=100000\r\nCurrency=BRL\r\nLeverage=1:1\r\nOptimization=0\r\nVisual=0\r\nReport=rel_verificar_mv\r\nReplaceReport=1\r\n'; } > "$ini"
matar; rm -f "$N/rel_verificar_mv".*; t0=$(date +%s); rodar_ini "$ini"; esperar "$N/rel_verificar_mv.htm" 7200; sleep 2; matar
echo "duracao $(( $(date +%s)-t0 )) s"
cp "$COMUM/verificacao_mv.txt" "$SAIDA" && echo "gravado $SAIDA" && cat "$SAIDA"
