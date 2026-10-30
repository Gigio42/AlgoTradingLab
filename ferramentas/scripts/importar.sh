#!/bin/bash
# importar.sh <preset.set> <SUFIXO>  -> importa CSVs como simbolos personalizados.
# Fecha o terminal com taskkill (sem /f): so assim o simbolo vai para symbols.custom.dat.
# PERFIL=<nome>: abre o terminal com esse perfil de graficos (o Default chegou ao
# limite de 100 graficos, notas/INCERTEZAS.md item 54) e depois devolve o
# Config/common.ini original, para o terminal do autor voltar ao perfil dele.
source "$(dirname "$0")/comum.sh"
R="$N/MQL5/Files/import_b3_resultado.txt"; matar; cp -p "$R" "$TRAB/imp_orig.txt" 2>/dev/null
[ -n "$PERFIL" ] && cp -p "$N/Config/common.ini" "$TRAB/common.ini.antes"
printf "%s[StartUp]\r\nScript=B3_Setup\\\\Import_B3_Custom\r\nScriptParameters=%s\r\nSymbol=PETR4\r\nPeriod=D1\r\n%s" "${PERFIL:+$'[Charts]\r\nProfileLast='$PERFIL$'\r\n'}" "$1" "$CONTA" > "$TRAB/imp.ini"
rodar_ini "$TRAB/imp.ini"
for i in $(seq 1 60); do sleep 3; grep -q "$2" "$R" 2>/dev/null && break; done; sleep 5; cat "$R" | head -3
WINEPREFIX=~/.wine-mt5-novo wine taskkill /im terminal64.exe >/dev/null 2>&1; sleep 20; matar
cp "$R" "$N/MQL5/Files/import${2}_resultado.txt"; cp -p "$TRAB/imp_orig.txt" "$R" 2>/dev/null
[ -n "$PERFIL" ] && cp -p "$TRAB/common.ini.antes" "$N/Config/common.ini"
