#!/bin/bash
# janelas_240_500.sh <pasta_de_saida> [calibrar] [testar]
#
# Estudo de 26/10/2026 (ia/INCERTEZAS.md, item 78): o mesmo protocolo da
# refação de 05/10/2026, com duas mudanças de método:
#   - ARIMA com janela fixa de 240 pregões (Janela_Estimacao sai da grade);
#   - GARCH estimado sobre os 500 resíduos mais recentes (Janela_GARCH=500),
#     calculados com os coeficientes do ARIMA do dia.
# Para o testador ter os 500 pregões, cada simulação começa dois anos antes e
# o EA só opera e só mede a partir de Inicio_Operacao (data oficial do período).
# A série oficial começa em 02/01/2003, então a calibração C1 e o período longo
# L1 começam em 01/02/2005 (antes: 02/01/2004 e 03/01/2005).
# O intervalo de confiança (fora do escopo desde 21/10) não entra.
# As médias móveis não dependem da mudança: os testes delas são copiados da
# refação de 05/10 (refeito_2026-10-05/testes).
#
# Etapas: calibrar (grades nas janelas de calibração e de teste, 4 ativos, e
# C4 da PETR4) e testar (escolhas, testes individuais com curva diária, traço).
# Sem etapa, roda as duas.
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"
OUT="$1"; [ -n "$OUT" ] || { echo "uso: $0 <pasta_de_saida> [calibrar] [testar]"; exit 1; }
shift; ETAPAS="${*:-calibrar testar}"
mkdir -p "$OUT"/{grades,calibracao,escolhas,testes,relatorios_mt5}
OUT="$(cd "$OUT" && pwd)"
R4="$A/dados/resultados/rodada4_multiativos/grades"
R3="$A/dados/resultados/rodada3_b3_oficial/grades"
REF="$A/dados/resultados/refeito_2026-10-05/testes"
SUBS="arima filtro_abs filtro_pct targ ft_abs ft_pct"

epoca(){ date -u -d "${1//./-}" +%s; }   # data do MT5 -> segundos (datetime do input)

# nome  operação_de  operação_até  testador_de
JANELAS=("C1 2005.02.01 2006.12.29 2003.01.02" "T1 2007.01.02 2011.12.30 2005.01.03"
         "C2 2010.01.04 2012.12.29 2008.01.02" "T2 2013.01.02 2016.12.30 2011.01.03"
         "C3 2022.01.03 2024.12.31 2020.01.02" "T3 2025.01.02 2026.09.19 2023.01.02")
C4="C4 2014.01.02 2016.12.30 2012.01.02"

# O que muda em toda grade e em todo teste (inputs listados: o que falta no
# [TesterInputs] viria do .set salvo, não do padrão do código; ver CLAUDE.md)
fixos(){ printf 'Janela_GARCH=500\nInicio_Operacao=%s\nMetodoARIMA=0\nSelecaoPorBIC=false\nDistribuicaoGARCH=0\nArquivo_Traco=\n' "$(epoca "$1")"; }
# Na otimização, linha sem "||" herda do .set salvo a marca de otimizar (Y) e a
# faixa: em 26/10 isso multiplicou as passagens a partir da C3 da PETR4. Por
# isso todo input numérico ou lógico vai com a faixa explícita e a marca N.
explicitar(){ awk -F= '!/\|\|/ && NF==2 && $2 ~ /^(-?[0-9.]+|true|false)$/ {
    if ($2=="true"||$2=="false") print $1"="$2"||false||0||true||N"; else print $1"="$2"||"$2"||1||"$2"||N"; next } { print }'; }
# FATORES (e FATORES_ARIMA, para a sub-grade sem GARCH): linhas "k=v||...||Y",
# uma por linha, que substituem a linha da chave na grade (estudo de fatores de
# 27/10, fatores_500.sh). Vazios, a grade é a de 26/10.
sobrepor(){ awk -v lista="$1" 'BEGIN { n = split(lista, L, "\n")
    for(i = 1; i <= n; i++) if(L[i] != "") { k = L[i]; sub(/=.*/, "", k); S[k] = L[i]; ordem[++m] = k } }
  { k = $0; sub(/=.*/, "", k) }
  k in S { if(!(k in feito)) print S[k]; feito[k] = 1; next } { print }
  END { for(i = 1; i <= m; i++) if(!(ordem[i] in feito)) print S[ordem[i]] }'; }
grade(){ # grade <arquivo_origem> <data_inicio> <ativo> <sub_grade>
  { tr -d '\r' < "$1" | sed -e 's/^Janela_Estimacao=.*/Janela_Estimacao=240/' \
    -e "s|^Arquivo_Proventos=.*|Arquivo_Proventos=proventos_$3.csv|"
    fixos "$2"; } | sobrepor "$([ "$4" = arima ] && echo "$FATORES_ARIMA" || echo "$FATORES")" | explicitar; }
pular(){ [[ " $PULAR " == *" $1 "* ]]; }   # PULAR="PETR4_C1 ..." retoma uma bateria interrompida
otimiza(){ rm -f "$N/MQL5/Profiles/Tester/ARIMA_GARCH_EA.set"; bash "$S/otimizar.sh" "$@"; }

if [[ " $ETAPAS " == *" calibrar "* ]]; then
  echo "calibrar: inicio $(date '+%F %T')"
  [ -d "$TRAB/g" ] && [ -z "$PULAR" ] && mv "$TRAB/g" "$TRAB/g_antigo_$(date +%s)"
  mkdir -p "$TRAB/sub240"
  for a in PETR4 VALE3 USIM5 POMO4; do
    for j in "${JANELAS[@]}"; do set -- $j
      for g in $SUBS; do
        f="$TRAB/sub240/${a}_$1_$g.txt"; grade "$R4/$g.txt" "$2" "$a" "$g" > "$f"
        [ "$a$1" = PETR4C1 ] && cp "$f" "$OUT/grades/r4_$g.txt"
        pular "${a}_$1" || otimiza "$1" "${a}_OFICIAL" "$4" "$3" "$f"
      done
    done
  done
  set -- $C4
  for g in $SUBS; do
    f="$TRAB/sub240/PETR4_C4_$g.txt"; grade "$R3/$g.txt" "$2" PETR4 "$g" > "$f"; cp "$f" "$OUT/grades/r3_$g.txt"
    pular PETR4_C4 || otimiza C4 PETR4_OFICIAL "$4" "$3" "$f"
  done
  for d in "$TRAB"/g/*_OFICIAL_*; do
    n=$(basename "$d" | sed 's/_OFICIAL//')
    f=$(ls "$d" | head -1); [ -n "$f" ] || continue
    { head -1 "$d/$f"; for x in "$d"/res_*; do sed -n 2p "$x"; done; } | tr -d '\r' > "$OUT/calibracao/$n.csv"
    echo "$n: $(( $(wc -l < "$OUT/calibracao/$n.csv") - 1 )) passagens"
  done
  echo "calibrar: fim $(date '+%F %T')"
fi

if [[ " $ETAPAS " == *" testar "* ]]; then
  echo "testar: inicio $(date '+%F %T')"
  B="$TRAB/in_240_500_base.txt"
  tr -d '\r' < "$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt" | sed 's/^Janela_Estimacao=.*/Janela_Estimacao=240/' > "$B"
  EA='robos\ARIMA-GARCH\ARIMA_GARCH_EA'
  LOG="$OUT/testes/execucao.log"; : > "$LOG"

  for j in 1 2 3; do bash "$S/escolher.sh" "$OUT/calibracao/PETR4_C$j.csv" so_compra > "$OUT/escolhas/r3_C$j.txt"; done
  bash "$S/escolher.sh" "$OUT/calibracao/PETR4_C4.csv" so_compra > "$OUT/escolhas/r6_C4.txt"
  for a in PETR4 VALE3 USIM5 POMO4; do for j in 1 2 3; do
    bash "$S/escolher.sh" "$OUT/calibracao/${a}_C$j.csv" > "$OUT/escolhas/r4_${a}_C$j.txt"
  done; done
  cfg(){ awk -v k="$2" '$1 == k { sub(/^[^|]*\| /, ""); print }' "$1"; }
  # roda <rotulo> <operação_de> <operação_até> <testador_de> <parametros...>
  roda(){ local rot=$1 de=$2 ate=$3 td=$4; shift 4
    echo "== $rot $*" >> "$LOG"
    bash "$S/rodar.sh" "$rot" "$EA" PETR4_OFICIAL "$td" "$ate" 100000 1:1 "$B" \
      Janela_GARCH=500 Inicio_Operacao=$(epoca "$de") MetodoARIMA=0 SelecaoPorBIC=false DistribuicaoGARCH=0 Arquivo_Traco= \
      "$@" >> "$LOG" 2>&1; }

  JT=("" "2007.01.02 2011.12.30 2005.01.03" "2013.01.02 2016.12.30 2011.01.03" "2025.01.02 2026.09.19 2023.01.02")
  for j in 1 2 3; do
    E="$OUT/escolhas/r3_C$j.txt"
    for k in GS GSgemeo GC GCgemeo AS AC; do roda R3_T${j}_$k ${JT[$j]} $(cfg "$E" $k); done
  done
  E="$OUT/escolhas/r6_C4.txt"
  rm -f "$COMUM/traco_R6_GS.csv"
  roda R6_GS 2017.01.02 2024.12.30 2015.01.02 $(cfg "$E" GS) Arquivo_Traco=R6_GS
  for k in GSgemeo GC GCgemeo; do roda R6_$k 2017.01.02 2024.12.30 2015.01.02 $(cfg "$E" $k); done
  roda R6_ARIMA 2017.01.02 2024.12.30 2015.01.02 $(cfg "$E" AS)
  E="$OUT/escolhas/r3_C2.txt"
  for k in GS GSgemeo GC GCgemeo; do
    roda L1_$k 2005.02.01 2026.09.18 2003.01.02 $(cfg "$E" $k)
    roda L2_$k 2017.01.02 2024.12.30 2015.01.02 $(cfg "$E" $k)
  done

  rotulos=$(sed -n 's/^== \([^ ]*\).*/\1/p' "$LOG")
  for r in $rotulos; do
    cp "$COMUM/metricas_$r.csv" "$COMUM/curva_$r.csv" "$OUT/testes/"
    cp "$TRAB/rel/rel_$r.htm" "$TRAB/rel/rel_$r.png" "$OUT/relatorios_mt5/" 2>/dev/null
  done
  for r in R3_T1_MM R3_T2_MM R3_T3_MM R6_MM L2_MM; do cp "$REF/metricas_$r.csv" "$REF/curva_$r.csv" "$OUT/testes/"; done
  mkdir -p "$OUT/traco"; cp "$COMUM/traco_R6_GS.csv" "$OUT/traco/"
  echo "testar: fim $(date '+%F %T')"
fi
