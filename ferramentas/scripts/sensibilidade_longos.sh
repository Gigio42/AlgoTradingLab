#!/bin/bash
# Sensibilidade (06/10/2026): as tres configuracoes fixas da rodada 5 ORIGINAL
# (GF, GT, AR, escolhidas com o EA antigo) rodadas com o EA corrigido. Nao
# substitui o protocolo da refacao (que usa GS e GC de C2); serve so para
# separar o efeito da correcao do efeito da nova escolha.
S="$(cd "$(dirname "$0")" && pwd)"; A="$(cd "$S/../.." && pwd)"; source "$S/comum.sh"
OUT="$1"; B="$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"
GF="UsarGARCH=true Estrategia=0 ModoLimiar=1 Limiar_Percentil=50 Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
GT="UsarGARCH=true Estrategia=3 ModoLimiar=1 Limiar_Percentil=90 Vol_Alvo=0.01 ZerarNoVeto=true Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
AR="UsarGARCH=false Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
for p in "L1 2005.01.03 2026.09.18" "L2 2017.01.02 2024.12.30"; do
  set -- $p; n=$1; de=$2; ate=$3
  for c in "GFant:$GF" "GTant:$GT" "ARant:$AR"; do
    r=${n}_${c%%:*}
    bash "$S/rodar.sh" $r 'ARIMA-GARCH\ARIMA_GARCH_EA' PETR4_OFICIAL $de $ate 100000 1:1 "$B" ${c#*:} >/dev/null 2>&1
    cp "$COMUM/metricas_$r.csv" "$COMUM/curva_$r.csv" "$OUT/sensibilidade/"
  done
done
