#!/bin/bash
# Validacao do GARCH com erros t de Student em series sinteticas
# (ferramentas/ValidarGarchT_EA.mq5). Roda no TESTADOR, como o comparar.sh:
# o calculo e todo no OnInit, e script pelo [StartUp] nao abre com o perfil
# de graficos cheio (ia/INCERTEZAS.md, item 54).
# Uso: bash validar_garch_t.sh <arquivo_de_saida>
source "$(dirname "$0")/comum.sh"
A="$(cd "$(dirname "$0")/../.." && pwd)"
[ -n "$1" ] || { echo "uso: $0 <arquivo_de_saida>"; exit 1; }
SAIDA="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
rm -f "$COMUM/validacao_garch_t.txt"
cp "$A/ferramentas/ValidarGarchT_EA.mq5" "$N/MQL5/Experts/"
( cd "$N" && WINEPREFIX=~/.wine-mt5-novo wine MetaEditor64.exe /compile:"MQL5\Experts\ValidarGarchT_EA.mq5" /log >/dev/null 2>&1 )
iconv -f UTF-16LE -t UTF-8 "$N/MQL5/Experts/ValidarGarchT_EA.log" | grep -E "error|Result:"
ini="$TRAB/validar_garch_t.ini"
{ printf '%s[Tester]\r\n' "$CONTA"
  printf 'Expert=ValidarGarchT_EA\r\nSymbol=PETR4_OFICIAL\r\nPeriod=D1\r\nModel=2\r\nFromDate=2024.01.02\r\nToDate=2024.01.31\r\nDeposit=100000\r\nCurrency=BRL\r\nLeverage=1:1\r\nOptimization=0\r\nVisual=0\r\nReport=rel_validar_t\r\nReplaceReport=1\r\n'; } > "$ini"
matar; rm -f "$N/rel_validar_t".*; rodar_ini "$ini"; esperar "$N/rel_validar_t.htm" 900; sleep 2; matar
cp "$COMUM/validacao_garch_t.txt" "$SAIDA" && echo "gravado $SAIDA" && cat "$SAIDA"
