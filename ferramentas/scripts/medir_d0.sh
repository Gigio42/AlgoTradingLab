#!/bin/bash
# Mede o efeito da correcao do d=0 (05/10/2026). Roda os testes principais com
# o EA CORRIGIDO e o traco ligado (rotulos FX_*), conta quantos pregoes tiveram
# d=0 em cada um e compara as metricas com as antigas, guardadas em dados/.
# Se um teste nunca teve d=0, as metricas novas tem de ser IDENTICAS as antigas
# (a correcao nao muda nada quando d=1): isso tambem e o teste de regressao.
A="/home/dark/.wine-mt5/drive_c/Program Files/MetaTrader 5/MQL5/Experts/AlgoTradingLab"
S="$A/ferramentas/scripts"; cd "$S" || exit 1
B="$A/dados/resultados/rodada3_b3_oficial/testes/in_r3_base.txt"
R="$A/dados/resultados"
roda(){ local rot=$1 de=$2 ate=$3 dep=$4 alav=$5; shift 5
  bash rodar.sh "FX_$rot" 'ARIMA-GARCH\ARIMA_GARCH_EA' PETR4_OFICIAL "$de" "$ate" "$dep" "$alav" "$B" \
    "$@" Arquivo_Traco=FX_$rot >/dev/null 2>&1; echo "rodou $rot"; }

# Rodada 6 (2017-2024, escolhidas em 2014-2016) -- mesmas linhas de teste_2017_2024.sh
GS="UsarGARCH=true Estrategia=0 ModoLimiar=1 Limiar_Percentil=70 ZerarNoVeto=true Janela_Estimacao=240 IncluirConstante=true Limiar_Sinal=0"
GC="UsarGARCH=true Estrategia=3 ModoLimiar=1 Limiar_Percentil=50 Vol_Alvo=0.01 ZerarNoVeto=false Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
GSg="UsarGARCH=false Janela_Estimacao=240 IncluirConstante=true Limiar_Sinal=0"
GCg="UsarGARCH=false Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
roda R6_GS 2017.01.02 2024.12.30 100000 1:1 $GS
roda R6_GSgemeo 2017.01.02 2024.12.30 100000 1:1 $GSg
roda R6_GC 2017.01.02 2024.12.30 100000 1:1 $GC
roda R6_GCgemeo 2017.01.02 2024.12.30 100000 1:1 $GCg
# Rodada 5 (configuracoes fixas) -- mesmas linhas de periodos_longos.sh
GF="UsarGARCH=true Estrategia=0 ModoLimiar=1 Limiar_Percentil=50 Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
GT="UsarGARCH=true Estrategia=3 ModoLimiar=1 Limiar_Percentil=90 Vol_Alvo=0.01 ZerarNoVeto=true Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
AR="UsarGARCH=false Janela_Estimacao=120 IncluirConstante=false Limiar_Sinal=0"
for p in "L1 2005.01.03 2026.09.18" "L2 2017.01.02 2024.12.30"; do
  set -- $p; n=$1; d=$2; f=$3
  roda ${n}_GF $d $f 100000 1:1 $GF
  roda ${n}_GT $d $f 100000 1:1 $GT
  roda ${n}_AR $d $f 100000 1:1 $AR
done
# Condicoes de Almeida, 2013-2016 -- mesmas linhas de cenario_almeida.sh
COM="ModoVolume=0 Fracao_Capital=0 SomenteCompra=false Custo_Por_Lado=0 StopLoss_Points=0 TakeProfit_Points=0 Volume_Base=1000"
roda cenA_1316_GARCH 2013.05.22 2016.05.24 50000 1:100 $COM $GF
roda cenA_1316_ARIMA 2013.05.22 2016.05.24 50000 1:100 $COM $AR

# ---- resumo: d=0 por teste e metricas antes x depois
C="$HOME/.wine-mt5-novo/drive_c/users/dark/AppData/Roaming/MetaQuotes/Terminal/Common/Files/AlgoLab"
antigo(){ case $1 in R6_*) echo "$R/rodada6_fora_amostra_2017_2024/metricas_$1.csv";;
  L[12]_*) echo "$R/rodada5_periodos_longos/metricas_$1.csv";;
  cenA_*) echo "$R/cenario_almeida_2026-09-30/metricas_$1.csv";; esac; }
met(){ awk -F';' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i} NR==2{printf "%.4f %.4f %.4f %.4f %d",$h["ret_selic"],$h["ret_puro"],$h["dd_selic"],$h["sharpe"],$h["saidas"]}' "$1"; }
printf "%-16s %6s %6s | %-40s | %-40s\n" teste barras d0 "ANTES ret_selic ret_puro dd sharpe saidas" "DEPOIS"
for t in R6_GS R6_GSgemeo R6_GC R6_GCgemeo L1_GF L1_GT L1_AR L2_GF L2_GT L2_AR cenA_1316_GARCH cenA_1316_ARIMA; do
  tr="$C/traco_FX_$t.csv"; n=$(($(wc -l < "$tr")-1)); z=$(awk -F';' 'NR>1 && $5==0' "$tr" | wc -l)
  printf "%-16s %6d %6d | %-40s | %-40s\n" "$t" "$n" "$z" "$(met "$(antigo $t)")" "$(met "$C/metricas_FX_$t.csv")"
done
