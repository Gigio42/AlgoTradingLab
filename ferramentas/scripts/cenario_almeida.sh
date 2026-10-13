#!/bin/bash
# Cenario Almeida: os modelos deste TG rodando nas MESMAS condicoes que
# Almeida (2016) declarou -- R$ 50 mil, volume fixo, sem custo, compra e
# venda -- para permitir a tabela lado a lado com os numeros dele.
A="/home/dark/.wine-mt5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/AlgoTradingLab"
S="$A/ferramentas/scripts"; cd "$S" || exit 1
T=/tmp/algolab-trabalho
B="$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"
COM="ModoVolume=0 Fracao_Capital=0 SomenteCompra=false Custo_Por_Lado=0 StopLoss_Points=0 TakeProfit_Points=0"

roda(){ # roda <rotulo> <de> <ate> <volume> <extras...>
  local rot=$1 de=$2 ate=$3 vol=$4; shift 4
  bash rodar.sh "$rot" 'ARIMA-GARCH\ARIMA_GARCH_EA' PETR4_OFICIAL "$de" "$ate" 50000 1:100 "$B" \
    $COM Volume_Base=$vol "$@" >/dev/null 2>&1
}

# Configuracoes escolhidas na calibracao da rodada 3 (nao reotimizadas aqui)
# T1 2007-2011 e o subperiodo 2008-2010: GS = filtro+targeting, perc 90, alvo 1%, zera no veto, janela 120
G1="UsarGARCH=true Estrategia=3 ModoLimiar=1 Limiar_Percentil=90 Vol_Alvo=0.01 ZerarNoVeto=true Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
A1="UsarGARCH=false Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
# T2 2013-2016: GS = filtro, percentil 50, janela 120
G2="UsarGARCH=true Estrategia=0 ModoLimiar=1 Limiar_Percentil=50 Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
A2="$A1"

roda cenA_0711_GARCH 2007.01.01 2011.12.31  100 $G1
roda cenA_0711_ARIMA 2007.01.01 2011.12.31  100 $A1
roda cenA_0810_GARCH 2008.01.01 2010.12.31  100 $G1
roda cenA_0810_ARIMA 2008.01.01 2010.12.31  100 $A1
roda cenA_1316_GARCH 2013.05.22 2016.05.24 1000 $G2
roda cenA_1316_ARIMA 2013.05.22 2016.05.24 1000 $A2

C="$HOME/.wine-mt5-novo/drive_c/users/dark/AppData/Roaming/MetaQuotes/Terminal/Common/Files/AlgoLab"
echo "rotulo               oper  acerto      FL   liquido_R$   retorno   quedaMax"
for f in "$C"/metricas_cenA_*.csv; do
  [ -s "$f" ] || continue
  awk -F';' -v n="$(basename "$f" .csv | sed 's/metricas_//')" '
    NR==1{for(i=1;i<=NF;i++)h[$i]=i}
    NR==2{printf "%-20s %4d %7.1f%% %7.2f %11.0f %8.1f%% %8.1f%%\n",
          n,$h["saidas"],$h["taxa_acerto"]*100,$h["fator_lucro"],
          $h["ret_puro"]*50000,$h["ret_puro"]*100,$h["dd_puro"]*100}' "$f"
done
