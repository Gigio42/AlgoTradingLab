#!/bin/bash
# resumo_bateria.sh <pasta da bateria de 15/10/2026>  > resumo.txt
# Le escolhas/, testes/metricas_N_*.csv e testes/comparacoes_*.csv e imprime
# as tabelas da analise (camada 1 "pura" como principal).
D="$1"; T="$D/testes"
[ -d "$T" ] || { echo "uso: $0 <pasta>" >&2; exit 1; }
export LC_ALL=C

m(){ # m <rotulo> <coluna>
  awk -F';' -v c="$2" 'NR==1{for(i=1;i<=NF;i++)h[$i]=i; next} NR==2{print (c in h) ? $h[c] : "NA"}' "$T/metricas_$1.csv" 2>/dev/null; }
pct(){ awk -v x="$1" 'BEGIN{ if(x=="" || x=="NA") printf "%9s", "-"; else printf "%8.1f%%", 100*x }'; }

echo "=========== BATERIA DE 15/10/2026 — RESUMO (camada 1, pura, salvo indicacao) ==========="
echo
echo "--- Escolhas (fator de recuperacao do MT5, >= 12 negociacoes na otimizacao) ---"
for j in 1 2 3 4 5; do echo "[C$j]"; grep -v "^GRgemeo" "$D/escolhas/rf_C$j.txt"; done
echo

echo "--- Resultado por periodo: retorno | queda max | volatilidade | negociacoes | acerto | exposicao ---"
for n in T1 T2 R6 T3 T5 L1 L2; do
  [ -s "$T/metricas_N_${n}_MM.csv" ] || continue
  printf "\n[%s] %s a %s | Selic no periodo %s\n" "$n" "$(m N_${n}_MM inicio)" "$(m N_${n}_MM fim)" "$(pct $(m N_${n}_MM selic))"
  for r in MM AR GR GRgemeo; do
    f="N_${n}_$r"; [ -s "$T/metricas_$f.csv" ] || continue
    printf "  %-9s %s %s %s %6s %7s %7s" "$r" "$(pct $(m $f ret_puro))" "$(pct $(m $f dd_puro))" "$(pct $(m $f vol_puro))" \
      "$(m $f saidas)" "$(pct $(m $f taxa_acerto))" "$(pct $(m $f exposicao))"
    [ "$r" = GR ] && printf "  vetos %s de %s" "$(m $f vetos)" "$(m $f sinais)"
    echo
  done
  printf "  %-9s %s %s %s\n" "PETR4" "$(pct $(m N_${n}_MM bh_preco))" "$(pct $(m N_${n}_MM dd_bh_preco))" "$(pct $(m N_${n}_MM vol_bh_preco))"
done
echo

echo "--- Camadas do retorno: 1 cru | 2 +custos | 3 +caixa na Selic | 4 +proventos ---"
for n in T1 T2 R6 T3 T5 L1 L2; do
  [ -s "$T/metricas_N_${n}_MM.csv" ] || continue
  printf "\n[%s]\n" "$n"
  for r in MM AR GR GRgemeo; do
    f="N_${n}_$r"; [ -s "$T/metricas_$f.csv" ] || continue
    printf "  %-9s %s %s %s %s   (queda: %s | %s)\n" "$r" "$(pct $(m $f ret_puro))" "$(pct $(m $f ret_custos))" \
      "$(pct $(m $f ret_selic))" "$(pct $(m $f ret_completo))" "$(pct $(m $f dd_puro))" "$(pct $(m $f dd_selic))"
  done
  printf "  %-9s %s %9s %9s %s\n" "PETR4" "$(pct $(m N_${n}_MM bh_preco))" "" "" "$(pct $(m N_${n}_MM bh_total))"
done
echo

echo "--- Com GARCH x mesma configuracao sem GARCH (camada 1) ---"
nq=0; nv=0; nr=0; tot=0
for n in T1 T2 R6 T3 T5 L1 L2; do
  a="N_${n}_GR"; b="N_${n}_GRgemeo"; [ -s "$T/metricas_$a.csv" ] && [ -s "$T/metricas_$b.csv" ] || continue
  tot=$((tot+1))
  q=$(awk -v x="$(m $a dd_puro)" -v y="$(m $b dd_puro)" 'BEGIN{print (x<y)?1:0}')
  v=$(awk -v x="$(m $a vol_puro)" -v y="$(m $b vol_puro)" 'BEGIN{print (x<y)?1:0}')
  r=$(awk -v x="$(m $a ret_puro)" -v y="$(m $b ret_puro)" 'BEGIN{print (x>y)?1:0}')
  nq=$((nq+q)); nv=$((nv+v)); nr=$((nr+r))
  printf "  %-3s queda %s x %s | vol %s x %s | retorno %s x %s\n" "$n" "$(pct $(m $a dd_puro))" "$(pct $(m $b dd_puro))" \
    "$(pct $(m $a vol_puro))" "$(pct $(m $b vol_puro))" "$(pct $(m $a ret_puro))" "$(pct $(m $b ret_puro))"
done
echo "  Em $tot comparacoes: queda menor com GARCH em $nq, volatilidade menor em $nv, retorno maior em $nr."
echo "  (L1 e L2 usam a mesma GR de C2; R6 e L2 cobrem o mesmo periodo; T5 esta dentro de R6.)"
echo

echo "--- Cenario de Almeida (R\$ 50 mil, volume fixo, sem custo, compra e venda) ---"
for f in N_cenA_0711_GARCH N_cenA_0711_ARIMA N_cenA_1316_GARCH N_cenA_1316_ARIMA; do
  [ -s "$T/metricas_$f.csv" ] || continue
  printf "  %-20s oper %4s | resultado R\$ %9.0f | queda %s | vol %s | acerto %s\n" "$f" "$(m $f saidas)" \
    "$(awk -v x="$(m $f ret_puro)" 'BEGIN{print x*50000}')" "$(pct $(m $f dd_puro))" "$(pct $(m $f vol_puro))" "$(pct $(m $f taxa_acerto))"
done
echo

for k in puro camada3; do
  f="$T/comparacoes_$k.csv"; [ -s "$f" ] || continue
  echo "--- Testes pareados ($k): vol A x vol B, p de Pitman-Morgan; p da diferenca de Sharpe; p do t pareado ---"
  tr -d '\r' < "$f" | awk -F';' 'NR==1{for(i=1;i<=NF;i++)h[$i]=i; next}
    {printf "  %-9s %-16s x %-16s vol %5.1f%% x %5.1f%% p_pm=%-9s | p_sharpe=%s | p_dif=%s\n", $h["grupo"], $h["modelo_a"], $h["modelo_b"],
      100*$h["vol_a"], 100*$h["vol_b"], $h["p_pm"], $h["p_sharpe"], $h["p_dif"]}'
  echo
done

echo "--- Recortes de um ano (camada 1, queda medida dentro do ano) ---"
for r in recorte_2008 recorte_2020_R6 recorte_2020_T5 recorte_2021_T5; do
  [ -s "$D/$r.txt" ] && { echo "[$r]"; sed 's/^/  /' "$D/$r.txt"; }
done
