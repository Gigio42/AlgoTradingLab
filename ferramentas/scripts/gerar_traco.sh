#!/bin/bash
# Gera o traco diario do EA (input Arquivo_Traco) para o painel de demonstracao.
# Janela: jul/2019 a jun/2021 -- calmaria, crash da COVID e recuperacao.
A="/home/dark/.wine-mt5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/AlgoTradingLab"
S="$A/ferramentas/scripts"; source "$S/comum.sh"; cd "$S" || exit 1
B="$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"
DE=2019.07.01; ATE=2021.06.30
LOGDIR="$N/Tester/Agent-127.0.0.1-3000/logs"
OUT=/tmp/algolab-trabalho/traco; mkdir -p "$OUT"

# Uso: gerar_traco.sh ["<parametros>"] [pasta_destino]
# Padrao: a configuracao GS da rodada 6 original (o resultado principal ate
# 05/10/2026). A refacao de 05/10 passa a nova GS da rodada 6.
GS="${1:-Estrategia=0 ModoLimiar=1 Limiar_Percentil=70 ZerarNoVeto=true Janela_Estimacao=240 IncluirConstante=true Limiar_Sinal=0}"
GS=$(echo "$GS" | sed 's/UsarGARCH=[a-z]* *//')
DEST="${2:-$A/dados/resultados/traco_demo_2019_2021}"; mkdir -p "$DEST"

for v in "GARCH true" "ARIMA false"; do
  set -- $v; nome=$1; flag=$2
  matar; rm -f "$LOGDIR"/*.log
  bash rodar.sh "demo_$nome" 'ARIMA-GARCH\ARIMA_GARCH_EA' PETR4_OFICIAL $DE $ATE 100000 1:1 "$B" \
    UsarGARCH=$flag $GS Arquivo_Traco=demo_$nome >/dev/null 2>&1
  f=$(ls -t "$LOGDIR"/*.log 2>/dev/null | head -1)
  iconv -f UTF-16LE -t UTF-8 "$f" > "$OUT/log_$nome.txt" 2>/dev/null
  echo "$nome: $(wc -l < "$OUT/log_$nome.txt") linhas de log"
done

# O EA grava em Common/Files/AlgoLab/traco_<nome>.csv (39 campos por barra).
C="$HOME/.wine-mt5-novo/drive_c/users/dark/AppData/Roaming/MetaQuotes/Terminal/Common/Files/AlgoLab"
for nome in GARCH ARIMA; do
  cp "$C/traco_demo_$nome.csv" "$DEST/" && echo "copiado traco_demo_$nome.csv"
done
