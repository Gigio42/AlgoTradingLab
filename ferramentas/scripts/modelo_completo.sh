#!/bin/bash
# modelo_completo.sh (06/11/2026): dados dos relatórios ia/relatorios/modelo-completo
# e ia/relatorios/garch-funcionando. Compila ferramentas/ModeloCompleto.mq5 no
# prefixo deste repositório (~/.wine-mt5, onde os #include de robos/ resolvem),
# roda o .ex5 no prefixo em uso pelo [StartUp] (perfil AlgoLab) e devolve o
# Config/common.ini do autor no fim. Depois confere previsão, volatilidade,
# limiar, veto, ordens e parâmetros contra o traço gravado pelo robô
# (dados/resultados/robo_em_acao_2026-10-30/dia_a_dia.csv).
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
V="$HOME/.wine-mt5/drive_c/Program Files/MetaTrader 5"
SAIDA="$A/dados/resultados/modelo_completo_2026-11-06"

cp "$A/ferramentas/ModeloCompleto.mq5" "$V/MQL5/Scripts/"
( cd "$V" && WINEPREFIX=~/.wine-mt5 wine MetaEditor64.exe /compile:"MQL5\Scripts\ModeloCompleto.mq5" /log >/dev/null 2>&1 )
iconv -f UTF-16LE -t UTF-8 "$V/MQL5/Scripts/ModeloCompleto.log" | grep -E "error|warning|Result:"
cp "$V/MQL5/Scripts/ModeloCompleto.ex5" "$N/MQL5/Scripts/" || exit 1

R="$N/MQL5/Files/AlgoLab_modelo"; rm -rf "$R"
cp -p "$N/Config/common.ini" "$TRAB/common.ini.antes"
printf '[Charts]\r\nProfileLast=AlgoLab\r\n%s[StartUp]\r\nScript=ModeloCompleto\r\nSymbol=PETR4_OFICIAL\r\nPeriod=D1\r\n' "$CONTA" > "$TRAB/modelo.ini"
matar; rodar_ini "$TRAB/modelo.ini"
for i in $(seq 1 60); do sleep 3; grep -q "FIM" "$R/resumo.txt" 2>/dev/null && break; done
sleep 3; matar
cp -p "$TRAB/common.ini.antes" "$N/Config/common.ini"

mkdir -p "$SAIDA" && cp "$R"/* "$SAIDA/" && echo "gravado em $SAIDA" || exit 1
cat "$SAIDA/resumo.txt"

# Conferência contra o traço: o script refaz o pregão, o traço é o que o robô gravou
T="$A/dados/resultados/robo_em_acao_2026-10-30/dia_a_dia.csv"
{
echo "Conferência contra $T"
echo "(traço: prev, vol e lim em %, com 5 casas; script: valores.tex com 2 casas, resumo com 8)"
for par in "Sex 2021-02-19" "Seg 2021-02-22"; do
  set -- $par
  linha=$(awk -F, -v d="$2" '$1==d' "$T")
  echo "== $2"
  echo "traço : $(echo "$linha" | awk -F, '{printf "p=%s d=%s q=%s prev=%s vol=%s lim=%s vetou=%s alfa=%s beta=%s phi1=%s const=%s", $10,$11,$12,$5,$6,$7,$17,$24,$25,$13,$15}')"
  awk -v d="$2" 'index($0,"================ "d)==1{f=1} f&&/^ARIMA\(|^previsao=|^GARCH:/{print "script: "$0} f&&/^Conferencia/{print "script: "$0; exit}' "$SAIDA/resumo.txt"
done
} | tee "$SAIDA/conferencia.txt"
