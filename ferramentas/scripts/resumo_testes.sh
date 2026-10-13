#!/bin/bash
# resumo_testes.sh <pasta> [padrao]  -- uma linha por metricas_<rotulo>.csv
# Campos usados nas tabelas do TG (camada 3 = custos + caixa na Selic):
#   ret = ret_selic, aa = cagr_selic_camada, SR = sharpe, p = sharpe_p,
#   dd = dd_selic, oper = saidas, acerto = taxa_acerto, vetos/sinais (GARCH),
#   e, para o cenario de Almeida (sem custo, sem Selic): ret_puro e dd_puro.
d=$1; pad=${2:-*}
printf "%-18s %5s %9s %7s %6s %6s %6s %5s %6s %10s | %8s %6s %8s %6s | %8s %6s\n" \
  rotulo anos "ret%" "aa%" SR p "dd%" oper "acert%" vetos/sin "selic%" "aa%" "b&h%" "aa%" "puro%" "ddp%"
for f in "$d"/metricas_$pad.csv; do
  awk -F';' -v n="$(basename "$f" .csv | sed 's/^metricas_//')" '
    NR==1{for(i=1;i<=NF;i++)h[$i]=i}
    function v(c){return (c in h)?$h[c]:""}
    NR==2{vs = (v("vetos")!="") ? v("vetos") "/" v("sinais") : "-"
      printf "%-18s %5.1f %9.1f %7.1f %6.2f %6.3f %6.1f %5d %6.1f %10s | %8.1f %6.1f %8.1f %6.1f | %8.1f %6.1f\n",
        n, v("anos"), v("ret_selic")*100, v("cagr_selic_camada")*100, v("sharpe"), v("sharpe_p"),
        v("dd_selic")*100, v("saidas"), v("taxa_acerto")*100, vs, v("selic")*100, v("cagr_selic")*100,
        v("bh_preco")*100, v("cagr_bh_preco")*100, v("ret_puro")*100, v("dd_puro")*100}' "$f"
done
