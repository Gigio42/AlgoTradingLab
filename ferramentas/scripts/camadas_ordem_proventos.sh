#!/usr/bin/env bash
# Retorno por etapa na ordem bruto -> + custos -> + proventos -> + Selic
# (pedido do autor, 17/11/2026: a coluna antes da Selic e o dinheiro de fora no
# saldo comum, rendendo zero; a ultima, numa conta remunerada).
#
# Nada e rodado no MetaTrader. Sai das curvas diarias ja gravadas pelo
# Desempenho.mqh em refeito_2026-10-05/proventos_b3/:
#   estrategia = camada 3 (bruto - custos + parado x Selic)
#   completo   = camada 4 (camada 3 + exposicao x provento / preco)
#   selic      = referencia (todo o capital na Selic), da qual sai a Selic do dia
#   exposicao  = fracao do patrimonio na acao no dia
# Como no Desempenho.mqh, parado = 1 - min(1, |exposicao|), e cada etapa soma
# uma parcela ao retorno do dia. Logo:
#   custos            = r(estrategia) - parado x selic_dia
#   custos+proventos  = r(completo)   - parado x selic_dia
# Conferencia: a coluna "custos" recalculada assim tem de bater com ret_custos
# das metricas (gravado pelo EA).
#
# Uso: bash ferramentas/scripts/camadas_ordem_proventos.sh [pasta]
set -euo pipefail
export LC_ALL=C
PASTA="${1:-dados/resultados/refeito_2026-10-05/proventos_b3}"

valor() {   # valor <metricas.csv> <coluna>
  awk -F';' -v c="$2" 'NR==1{for(i=1;i<=NF;i++) if($i==c) k=i; next} NR==2{print $k}' "$1"
}

printf "%-14s %9s %9s %9s %9s | %9s %9s | %7s %7s %7s %7s\n" rotulo bruto "+custos" "+proventos" "+Selic" custos_EA dif_pp dd_bru dd_cprv dd_cSel dd_tudo
for curva in "$PASTA"/curva_*.csv; do
  rot=$(basename "$curva" .csv); rot=${rot#curva_}
  met="$PASTA/metricas_${rot}.csv"
  read -r custos cprov final ddcp <<<"$(awk -F, 'NR==2{e3=$2; s=$3; c4=$5; next}
    NR>2{
      x=$8; if(x<0)x=-x; if(x>1)x=1; parado=1-x
      sd=$3/s-1
      r3=$2/e3-1; r4=$5/c4-1
      fc*=1+r3-parado*sd; fp*=1+r4-parado*sd
      if(fp>pico)pico=fp; if(1-fp/pico>dd)dd=1-fp/pico
      e3=$2; s=$3; c4=$5; fim=$5
    }
    BEGIN{fc=1; fp=1; pico=1; dd=0}
    END{printf "%.6f %.6f %.6f %.6f", fc-1, fp-1, fim-1, dd}' "$curva")"
  puro=$(valor "$met" ret_puro); custos_ea=$(valor "$met" ret_custos)
  dds="$(valor "$met" dd_puro) $(valor "$met" dd_selic) $(valor "$met" dd_completo)"
  awk -v r="$rot" -v p="$puro" -v c="$custos" -v cp="$cprov" -v f="$final" -v ce="$custos_ea" -v dcp="$ddcp" -v dds="$dds" \
    'BEGIN{split(dds,d," "); printf "%-14s %8.1f%% %8.1f%% %8.1f%% %8.1f%% | %8.1f%% %9.3f | %6.1f%% %6.1f%% %6.1f%% %6.1f%%\n", r, p*100, c*100, cp*100, f*100, ce*100, (c-ce)*100, d[1]*100, dcp*100, d[2]*100, d[3]*100}'
done
echo
echo "PETR4 (mesmo arquivo de cada periodo): bh_preco = bruto, bh_total = + proventos"
for met in "$PASTA"/metricas_R3_T1_MM.csv "$PASTA"/metricas_R3_T2_MM.csv "$PASTA"/metricas_R3_T3_MM.csv "$PASTA"/metricas_R6_MM.csv; do
  awk -v r="$(basename "$met" .csv)" -v b="$(valor "$met" bh_preco)" -v t="$(valor "$met" bh_total)" -v s="$(valor "$met" selic)" \
    'BEGIN{printf "%-22s bruto %7.1f%%  +proventos %7.1f%%  Selic no periodo %6.1f%%\n", r, b*100, t*100, s*100}'
done
