#!/bin/bash
# testes_formulas.sh (30/10/2026): dados do relatório dos testes do código
# (ia/relatorios/testes-do-codigo/). Compila ferramentas/TestesFormulas.mq5 no
# prefixo deste repositório (~/.wine-mt5, onde os #include de robos/ resolvem),
# copia só o .ex5 para o prefixo em uso e roda lá pelo [StartUp], com o perfil
# de gráficos AlgoLab (ia/INCERTEZAS.md item 54). Devolve o Config/common.ini do
# autor no fim. Semente fixa: rodar de novo dá os mesmos números.
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
V="$HOME/.wine-mt5/drive_c/Program Files/MetaTrader 5"
SAIDA="$A/dados/verificacao/testes_formulas_2026-10-30"

cp "$A/ferramentas/TestesFormulas.mq5" "$V/MQL5/Scripts/"
( cd "$V" && WINEPREFIX=~/.wine-mt5 wine MetaEditor64.exe /compile:"MQL5\Scripts\TestesFormulas.mq5" /log >/dev/null 2>&1 )
iconv -f UTF-16LE -t UTF-8 "$V/MQL5/Scripts/TestesFormulas.log" | grep -E "error|warning|Result:"
cp "$V/MQL5/Scripts/TestesFormulas.ex5" "$N/MQL5/Scripts/" || exit 1

R="$N/MQL5/Files/AlgoLab_testes"; rm -rf "$R"
cp -p "$N/Config/common.ini" "$TRAB/common.ini.antes"
printf '[Charts]\r\nProfileLast=AlgoLab\r\n%s[StartUp]\r\nScript=TestesFormulas\r\nSymbol=PETR4_OFICIAL\r\nPeriod=D1\r\n' "$CONTA" > "$TRAB/testes.ini"
matar; rodar_ini "$TRAB/testes.ini"
for i in $(seq 1 600); do sleep 3; grep -q "FIM" "$R/resumo.txt" 2>/dev/null && break; done
sleep 3; matar
cp -p "$TRAB/common.ini.antes" "$N/Config/common.ini"

mkdir -p "$SAIDA" && cp "$R"/* "$SAIDA/" || exit 1
echo "gravado em $SAIDA"; cat "$SAIDA/resumo.txt"
