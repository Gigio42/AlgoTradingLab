#!/bin/bash
# metodos_ilustrados.sh (30/10/2026): dados dos gráficos que explicam os métodos
# (apresentacao/graficos_metodos/). Compila ferramentas/MetodosIlustrados.mq5 no
# prefixo deste repositório (~/.wine-mt5, onde os #include de robos/ resolvem),
# copia só o .ex5 para o prefixo em uso e roda lá pelo [StartUp], com o perfil
# de gráficos AlgoLab (o Default está no limite de 100 gráficos, ia/INCERTEZAS.md
# item 54). Devolve o Config/common.ini do autor no fim.
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
V="$HOME/.wine-mt5/drive_c/Program Files/MetaTrader 5"
SAIDA="$A/dados/resultados/metodos_ilustrados_2026-10-30"

cp "$A/ferramentas/MetodosIlustrados.mq5" "$V/MQL5/Scripts/"
( cd "$V" && WINEPREFIX=~/.wine-mt5 wine MetaEditor64.exe /compile:"MQL5\Scripts\MetodosIlustrados.mq5" /log >/dev/null 2>&1 )
iconv -f UTF-16LE -t UTF-8 "$V/MQL5/Scripts/MetodosIlustrados.log" | grep "Result:"
cp "$V/MQL5/Scripts/MetodosIlustrados.ex5" "$N/MQL5/Scripts/"

R="$N/MQL5/Files/AlgoLab_metodos"; rm -rf "$R"
cp -p "$N/Config/common.ini" "$TRAB/common.ini.antes"
printf '[Charts]\r\nProfileLast=AlgoLab\r\n%s[StartUp]\r\nScript=MetodosIlustrados\r\nSymbol=PETR4_OFICIAL\r\nPeriod=D1\r\n' "$CONTA" > "$TRAB/metodos.ini"
matar; rodar_ini "$TRAB/metodos.ini"
for i in $(seq 1 60); do sleep 3; grep -q "FIM" "$R/resumo.txt" 2>/dev/null && break; done
sleep 3; matar
cp -p "$TRAB/common.ini.antes" "$N/Config/common.ini"

mkdir -p "$SAIDA" && cp "$R"/* "$SAIDA/" && echo "gravado em $SAIDA" && cat "$SAIDA/resumo.txt"
