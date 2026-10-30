#!/bin/bash
# Teste FORA DA AMOSTRA 2017-2024, com as configuracoes escolhidas na
# calibracao 2014-2016 (protocolo das rodadas 3 e 4).
A="/home/dark/.wine-mt5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/AlgoTradingLab"
S="$A/ferramentas/scripts"; cd "$S" || exit 1
B="$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"
M="$A/dados/resultados/rodada3_b3_oficial/testes/in_mm.txt"
DE=2017.01.02; ATE=2024.12.30

# GS: filtro, percentil 70, zera no veto, janela 240, COM constante
GS="UsarGARCH=true Estrategia=0 ModoLimiar=1 Limiar_Percentil=70 ZerarNoVeto=true Janela_Estimacao=240 IncluirConstante=true Limiar_Sinal=0"
# GC: filtro+targeting, percentil 50, nao zera, janela 120, sem constante
GC="UsarGARCH=true Estrategia=3 ModoLimiar=1 Limiar_Percentil=50 Vol_Alvo=0.01 ZerarNoVeto=false Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
# gemeos: mesmo ARIMA, GARCH desligado
GSg="UsarGARCH=false Janela_Estimacao=240 IncluirConstante=true Limiar_Sinal=0"
GCg="UsarGARCH=false Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
# ARIMA puro escolhido pelos dois criterios (coincidiram)
AR="UsarGARCH=false ModoLimiar=0 Janela_Estimacao=240 IncluirConstante=true Limiar_Sinal=0"

for c in "R6_GS $GS" "R6_GC $GC" "R6_GSgemeo $GSg" "R6_GCgemeo $GCg" "R6_ARIMA $AR"; do
  set -- $c; rot=$1; shift
  bash rodar.sh "$rot" 'robos\ARIMA-GARCH\ARIMA_GARCH_EA' PETR4_OFICIAL $DE $ATE 100000 1:1 "$B" "$@" >/dev/null 2>&1
done
bash rodar.sh R6_MM 'robos\MediasMoveis2\MediasMoveis2' PETR4_OFICIAL $DE $ATE 100000 1:1 "$M" \
  Volume_Fixo_Input=0 Fracao_Capital=0.95 SomenteCompra=true Custo_Por_Lado=0.0003 >/dev/null 2>&1

C="$HOME/.wine-mt5-novo/drive_c/users/dark/AppData/Roaming/MetaQuotes/Terminal/Common/Files/AlgoLab"
printf "%-12s %5s %8s %8s %8s %8s %7s %7s %8s %5s\n" rotulo anos retorno selic "b&h" excesso sharpe p quedaMax oper
for f in "$C"/metricas_R6_*.csv; do
  [ -s "$f" ] || continue
  awk -F';' -v n="$(basename "$f" .csv | sed 's/metricas_//')" '
    NR==1{for(i=1;i<=NF;i++)h[$i]=i}
    NR==2{printf "%-12s %5.1f %7.1f%% %7.1f%% %7.1f%% %7.1f%% %7.2f %7.3f %7.1f%% %5d\n",
      n,$h["anos"],$h["ret_selic"]*100,$h["selic"]*100,$h["bh_preco"]*100,
      $h["excesso"]*100,$h["sharpe"],$h["sharpe_p"],$h["dd_selic"]*100,$h["saidas"]}' "$f"
done
