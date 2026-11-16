#!/bin/bash
# janela_garch_simulada.sh [pasta_saida]  (13/11/2026)
#
# Roda ferramentas/JanelaGarchSimulada.mq5 (o CGarch do EA em séries GARCH
# artificiais, janelas de 120 a 1000) e copia a saída para
# dados/resultados/janelas_garch_2026-11-13/simulacao/.
# Diferente do validar.sh, compila E roda no prefixo deste repositório
# (~/.wine-mt5): o script não usa dado de mercado nem conta, e assim pode rodar
# enquanto o testador do prefixo em uso faz uma bateria (cada passo da bateria
# derruba o wineserver de lá). Perfil de gráficos "Euro" (o Default deste
# prefixo está vazio). Devolve o Config/common.ini no fim. Semente fixa.
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
V="$HOME/.wine-mt5/drive_c/Program Files/MetaTrader 5"
OUT="${1:-$A/dados/resultados/janelas_garch_2026-11-13/simulacao}"
TRAB="${TRAB:-/tmp/algolab-trabalho}"; mkdir -p "$TRAB" "$OUT"

rm -f "$V/MQL5/Scripts/JanelaGarchSimulada.ex5"
cp "$A/ferramentas/JanelaGarchSimulada.mq5" "$V/MQL5/Scripts/"
( cd "$V" && WINEPREFIX=~/.wine-mt5 wine MetaEditor64.exe /compile:"MQL5\Scripts\JanelaGarchSimulada.mq5" /log >/dev/null 2>&1 )
iconv -f UTF-16LE -t UTF-8 "$V/MQL5/Scripts/JanelaGarchSimulada.log" | grep -E "error|warning|Result:"
[ -s "$V/MQL5/Scripts/JanelaGarchSimulada.ex5" ] || { echo "nao compilou"; exit 1; }

cp -p "$V/Config/common.ini" "$TRAB/common_velho.ini.antes"
printf '[Charts]\r\nProfileLast=Euro\r\n[Experts]\r\nAllowLiveTrading=1\r\nEnabled=1\r\n[StartUp]\r\nScript=JanelaGarchSimulada\r\nSymbol=EURUSD\r\nPeriod=D1\r\n' > "$TRAB/sim.ini"
rm -f "$V"/MQL5/Files/janela_sim_*.csv "$V"/MQL5/Files/janela_sim_fim.txt
( cd "$V" && WINEPREFIX=~/.wine-mt5 wine terminal64.exe "/config:Z:$(echo "$TRAB/sim.ini" | tr / '\\')" >/dev/null 2>&1 & )
for i in $(seq 1 1440); do sleep 5; [ -s "$V/MQL5/Files/janela_sim_fim.txt" ] && break; done
sleep 2; WINEPREFIX=~/.wine-mt5 wineserver -k 2>/dev/null
cp -p "$TRAB/common_velho.ini.antes" "$V/Config/common.ini"
cp "$V"/MQL5/Files/janela_sim_precisao.csv "$V"/MQL5/Files/janela_sim_regime.csv "$V"/MQL5/Files/janela_sim_regime_media.csv "$OUT/" && echo "gravado em $OUT"
