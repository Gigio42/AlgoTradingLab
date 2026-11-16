#!/bin/bash
# hannan_rissanen.sh (30/10/2026): dados do relatório sobre o Hannan-Rissanen
# (ia/relatorios/hannan-rissanen/). Compila ferramentas/HannanRissanenDetalhado.mq5
# no prefixo deste repositório (~/.wine-mt5, onde os #include de robos/ resolvem),
# copia só o .ex5 para o prefixo em uso e roda lá pelo [StartUp], com o perfil de
# gráficos AlgoLab (ia/INCERTEZAS.md item 54). Devolve o Config/common.ini do
# autor no fim. Depois confere os pregões reais contra o traço da refação de
# 05/10/2026.
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
V="$HOME/.wine-mt5/drive_c/Program Files/MetaTrader 5"
SAIDA="$A/dados/resultados/hannan_rissanen_2026-10-30"
TRACO="$A/dados/resultados/refeito_2026-10-05/traco_demo/traco_demo_GARCH.csv"

cp "$A/ferramentas/HannanRissanenDetalhado.mq5" "$V/MQL5/Scripts/"
( cd "$V" && WINEPREFIX=~/.wine-mt5 wine MetaEditor64.exe /compile:"MQL5\Scripts\HannanRissanenDetalhado.mq5" /log >/dev/null 2>&1 )
iconv -f UTF-16LE -t UTF-8 "$V/MQL5/Scripts/HannanRissanenDetalhado.log" | grep -E "error|Result:"
cp "$V/MQL5/Scripts/HannanRissanenDetalhado.ex5" "$N/MQL5/Scripts/" || exit 1

R="$N/MQL5/Files/AlgoLab_hr"; rm -rf "$R"
cp -p "$N/Config/common.ini" "$TRAB/common.ini.antes"
printf '[Charts]\r\nProfileLast=AlgoLab\r\n%s[StartUp]\r\nScript=HannanRissanenDetalhado\r\nSymbol=PETR4_OFICIAL\r\nPeriod=D1\r\n' "$CONTA" > "$TRAB/hr.ini"
matar; rodar_ini "$TRAB/hr.ini"
for i in $(seq 1 200); do sleep 3; grep -q "FIM" "$R/resumo.txt" 2>/dev/null && break; done
sleep 3; matar
cp -p "$TRAB/common.ini.antes" "$N/Config/common.ini"

mkdir -p "$SAIDA" && cp "$R"/* "$SAIDA/" || exit 1

# Conferência: os coeficientes e a previsão refeitos têm de bater com o traço
{ echo; echo "--- Conferência contra o traço ($TRACO)"
  grep "^CONFERIR" "$SAIDA/resumo.txt" | tr -d '\r' | while IFS=';' read -r _ rot data c rest; do
    awk -F';' -v data="$data" -v c="$c" -v rest="$rest" -v rot="$rot" '
      $1==data { n=split(rest, v, ";"); q=n-1; dif=0
        x=c-$7; if(x<0)x=-x; if(x>dif)dif=x
        for(j=1;j<=q;j++){ x=v[j]-$(11+j); if(x<0)x=-x; if(x>dif)dif=x }
        x=v[n]-$22; if(x<0)x=-x; if(x>dif)dif=x
        printf "  %s %s: maior diferença absoluta (constante, thetas, previsão) = %.3g -> %s\n", rot, data, dif, (dif<1e-9?"IGUAL":"DIFERENTE") }' "$TRACO"
  done; } | tee -a "$SAIDA/resumo.txt"
# Quantos pregões do traço passaram pelos dois estágios (q > 0)
awk -F';' 'NR>1{n++; if($6>0)hr++} END{printf "\\def\\vHTracoN{%d}\n\\def\\vHTracoDois{%d}\n\\def\\vHTracoUm{%d}\n\\def\\vHTracoPct{%.0f}\n", n, hr, n-hr, 100*hr/n}' "$TRACO" >> "$SAIDA/valores.tex"
echo "gravado em $SAIDA"; grep -v "^CONFERIR" "$SAIDA/resumo.txt"
