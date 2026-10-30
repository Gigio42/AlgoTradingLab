#!/bin/bash
# Periodos longos, no espirito do que Almeida fez: configuracao FIXA
# declarada antes, sem reotimizar dentro do periodo. Camada 3 (custo B3 +
# caixa na Selic), so compra, 95% do patrimonio, R$ 100 mil, 1:1.
A="/home/dark/.wine-mt5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/AlgoTradingLab"
S="$A/ferramentas/scripts"; cd "$S" || exit 1
B="$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"
M="$A/dados/resultados/rodada3_b3_oficial/testes/in_mm.txt"

# Duas variantes de ARIMA-GARCH, as duas escolhidas pelo protocolo da rodada 3
# (uma por filtro, outra por filtro+targeting), para nao haver escolha de campea
# dentro do periodo de teste.
GF="UsarGARCH=true Estrategia=0 ModoLimiar=1 Limiar_Percentil=50 Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
GT="UsarGARCH=true Estrategia=3 ModoLimiar=1 Limiar_Percentil=90 Vol_Alvo=0.01 ZerarNoVeto=true Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
AR="UsarGARCH=false Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"

roda(){ local rot=$1 de=$2 ate=$3; shift 3
  bash rodar.sh "$rot" 'robos\ARIMA-GARCH\ARIMA_GARCH_EA' PETR4_OFICIAL "$de" "$ate" 100000 1:1 "$B" "$@" >/dev/null 2>&1; }
rodamm(){ local rot=$1 de=$2 ate=$3
  bash rodar.sh "$rot" 'robos\MediasMoveis2\MediasMoveis2' PETR4_OFICIAL "$de" "$ate" 100000 1:1 "$M" \
    Volume_Fixo_Input=0 Fracao_Capital=0.95 SomenteCompra=true Custo_Por_Lado=0.0003 >/dev/null 2>&1; }

for p in "L1 2005.01.03 2026.09.18" "L2 2017.01.02 2024.12.30"; do
  set -- $p; n=$1; d=$2; f=$3
  roda ${n}_GF $d $f $GF
  roda ${n}_GT $d $f $GT
  roda ${n}_AR $d $f $AR
  rodamm ${n}_MM $d $f
done

C="$HOME/.wine-mt5-novo/drive_c/users/dark/AppData/Roaming/MetaQuotes/Terminal/Common/Files/AlgoLab"
printf "%-10s %5s %7s %8s %8s %9s %8s %7s %7s\n" rotulo anos retorno selic "b&h" excesso sharpe p quedaMax
for f in "$C"/metricas_L[12]_*.csv; do
  [ -s "$f" ] || continue
  awk -F';' -v n="$(basename "$f" .csv | sed 's/metricas_//')" '
    NR==1{for(i=1;i<=NF;i++)h[$i]=i}
    NR==2{printf "%-10s %5.1f %6.1f%% %7.1f%% %7.1f%% %8.1f%% %8.2f %7.3f %6.1f%%\n",
      n,$h["anos"],$h["ret_selic"]*100,$h["selic"]*100,$h["bh_preco"]*100,
      $h["excesso"]*100,$h["sharpe"],$h["sharpe_p"],$h["dd_selic"]*100}' "$f"
done
