#!/bin/bash
# validar_assimetrico.sh [pasta_saida]  (18/11/2026)
#
# Roda ferramentas/ValidacaoAssimetrico.mq5: as partes novas do modelo (GJR,
# EGARCH, t de Student, BIC, janela expansiva) contra a teoria, ANTES das
# simulacoes do estudo de 18/11. Mesmo esquema do janela_garch_simulada.sh:
# compila e roda no prefixo reserva (~/.wine-mt5), sem testador, enquanto o
# prefixo em uso pode estar rodando bateria. Le dados/series/PETR4_OFICIAL.csv
# (copiado para MQL5/Files de la). Semente fixa.
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
V="$HOME/.wine-mt5/drive_c/Program Files/MetaTrader 5"
OUT="${1:-$A/dados/resultados/assimetricos_2026-11-18/validacao}"
TRAB="${TRAB:-/tmp/algolab-trabalho}"; mkdir -p "$TRAB" "$OUT"

rm -f "$V/MQL5/Scripts/ValidacaoAssimetrico.ex5"
cp "$A/ferramentas/ValidacaoAssimetrico.mq5" "$V/MQL5/Scripts/"
( cd "$V" && WINEPREFIX=~/.wine-mt5 wine MetaEditor64.exe /compile:"MQL5\Scripts\ValidacaoAssimetrico.mq5" /log >/dev/null 2>&1 )
iconv -f UTF-16LE -t UTF-8 "$V/MQL5/Scripts/ValidacaoAssimetrico.log" | grep -E "error|warning|Result:"
[ -s "$V/MQL5/Scripts/ValidacaoAssimetrico.ex5" ] || { echo "nao compilou"; exit 1; }
cp "$A/dados/series/PETR4_OFICIAL.csv" "$V/MQL5/Files/"

cp -p "$V/Config/common.ini" "$TRAB/common_velho.ini.antes"
printf '[Charts]\r\nProfileLast=Euro\r\n[Experts]\r\nAllowLiveTrading=1\r\nEnabled=1\r\n[StartUp]\r\nScript=ValidacaoAssimetrico\r\nSymbol=EURUSD\r\nPeriod=D1\r\n' > "$TRAB/valid_assim.ini"
rm -f "$V"/MQL5/Files/valid_assim_*
( cd "$V" && WINEPREFIX=~/.wine-mt5 wine terminal64.exe "/config:Z:$(echo "$TRAB/valid_assim.ini" | tr / '\\')" >/dev/null 2>&1 & )
for i in $(seq 1 2880); do sleep 5; [ -s "$V/MQL5/Files/valid_assim_fim.txt" ] && break; done
sleep 2; WINEPREFIX=~/.wine-mt5 wineserver -k 2>/dev/null
cp -p "$TRAB/common_velho.ini.antes" "$V/Config/common.ini"
rm -f "$V/MQL5/Files/valid_assim_fim.txt"
cp "$V"/MQL5/Files/valid_assim_* "$OUT/" && echo "gravado em $OUT"
