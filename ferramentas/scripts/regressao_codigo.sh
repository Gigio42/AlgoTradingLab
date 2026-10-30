#!/bin/bash
# Regressao do codigo: roda casos curtos que passam por todos os caminhos dos
# dois EAs e guarda metricas, curva diaria e traco. Rodar antes e depois de
# uma mudanca que nao deveria alterar resultado e comparar com --comparar.
#
#   bash regressao_codigo.sh <pasta_saida>
#   bash regressao_codigo.sh --comparar <pasta_antes> <pasta_depois>
source "$(dirname "$0")/comum.sh"
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"

if [ "$1" = "--comparar" ]; then
  antes="$2"; depois="$3"; falhas=0
  for f in "$antes"/*.csv; do
    nome=$(basename "$f")
    if [ ! -f "$depois/$nome" ]; then echo "FALTA    $nome"; falhas=$((falhas+1))
    elif cmp -s "$f" "$depois/$nome"; then echo "identico $nome"
    else echo "DIFERE   $nome"; falhas=$((falhas+1)); fi
  done
  echo "diferencas: $falhas"; exit $falhas
fi

OUT="$(mkdir -p "$1" && cd "$1" && pwd)"; LOG="$OUT/execucao.log"; : > "$LOG"
B="$TRAB/regressao_base.txt"
{ cat "$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"
  echo "MetodoARIMA=0"; echo "SelecaoPorBIC=false"; echo "DistribuicaoGARCH=0"; echo "Arquivo_Traco="; } | tr -d '\r' > "$B"
M="$A/dados/resultados/rodada3_b3_oficial/testes/in_mm.txt"
EA='ARIMA-GARCH\ARIMA_GARCH_EA'; MMEA='MediasMoveis2\MediasMoveis2'
T3="2025.01.02 2026.09.19"; T5="2020.01.02 2021.12.30"

GR="UsarGARCH=true Estrategia=3 ModoLimiar=1 Limiar_Percentil=70 Vol_Alvo=0.01 ZerarNoVeto=true Janela_Estimacao=240 Limiar_Sinal=0.001"
GS="UsarGARCH=true Estrategia=0 ModoLimiar=1 Limiar_Percentil=70 ZerarNoVeto=true Janela_Estimacao=240 IncluirConstante=true"

ea(){ local rot=$1 de=$2 ate=$3 dep=$4 alav=$5; shift 5
  echo "== $rot $*" >> "$LOG"
  bash "$S/rodar.sh" "$rot" "$EA" PETR4_OFICIAL "$de" "$ate" "$dep" "$alav" "$B" "$@" >> "$LOG" 2>&1
  cp "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv" "$OUT/" 2>>"$LOG"
  [ -f "$COMUM/traco_$rot.csv" ] && cp "$COMUM/traco_$rot.csv" "$OUT/"
  echo "$rot $([ -s "$OUT/metricas_$rot.csv" ] && echo ok || echo FALTOU)" | tee -a "$LOG"; }
mm(){ local rot=$1 de=$2 ate=$3 dep=$4 alav=$5; shift 5
  echo "== $rot $*" >> "$LOG"
  bash "$S/rodar.sh" "$rot" "$MMEA" PETR4_OFICIAL "$de" "$ate" "$dep" "$alav" "$M" "$@" >> "$LOG" 2>&1
  cp "$COMUM/metricas_$rot.csv" "$COMUM/curva_$rot.csv" "$OUT/" 2>>"$LOG"
  echo "$rot $([ -s "$OUT/metricas_$rot.csv" ] && echo ok || echo FALTOU)" | tee -a "$LOG"; }

rm -f "$COMUM"/traco_RG_*.csv
ea RG_filtro_targeting $T3 100000 1:1 $GR Arquivo_Traco=RG_filtro_targeting
ea RG_arima_puro       $T3 100000 1:1 UsarGARCH=false Janela_Estimacao=240 Limiar_Sinal=0.001 Arquivo_Traco=RG_arima_puro
ea RG_filtro_pandemia  $T5 100000 1:1 $GS Arquivo_Traco=RG_filtro_pandemia Diagnostico=true RelatorioInicial=true
# RG_intervalo (Estrategia=2) saiu em 21/10/2026 com o intervalo de confianca (fora do escopo, pedido do autor)
ea RG_targeting_fixo   $T3 100000 1:1 UsarGARCH=true Estrategia=1 Vol_Alvo=0.01 ModoVolume=0 Volume_Base=100 SomenteCompra=false
ea RG_manual_sltp      $T3 100000 1:1 UsarGARCH=true ModoOrdens=1 IncluirConstante=true StopLoss_Points=300 TakeProfit_Points=600 PermitirReversao=false SomenteCompra=false
ea RG_preco_bruto      $T3 100000 1:1 UsarGARCH=false Transformacao=1
ea RG_veross_bic       $T3 100000 1:1 $GR MetodoARIMA=1 SelecaoPorBIC=true
ea RG_student          $T3 100000 1:1 $GS DistribuicaoGARCH=1
ea RG_almeida_1316     2013.05.22 2016.05.24 50000 1:100 ModoVolume=0 Fracao_Capital=0 SomenteCompra=false Custo_Por_Lado=0 Volume_Base=1000 \
   UsarGARCH=true Estrategia=0 ModoLimiar=1 Limiar_Percentil=50
mm RG_mm_capital       $T3 100000 1:1 Volume_Fixo_Input=0 Fracao_Capital=0.95 SomenteCompra=true Custo_Por_Lado=0.0003
mm RG_mm_almeida       2013.05.22 2016.05.24 50000 1:100 Volume_Fixo_Input=1000 Fracao_Capital=0 SomenteCompra=false Custo_Por_Lado=0 \
   StopLoss_Points=0 TakeProfit_Points=0
mm RG_mm_sltp          $T3 100000 1:1 Volume_Fixo_Input=100 Fracao_Capital=0 StopLoss_Points=50 TakeProfit_Points=100 SomenteCompra=false
echo "fim $(date '+%F %T')" | tee -a "$LOG"
