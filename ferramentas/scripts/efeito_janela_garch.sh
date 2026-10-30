#!/bin/bash
# efeito_janela_garch.sh
#
# Estudo das janelas 240/500 (26/10/2026): a MESMA configuração com o GARCH
# estimado sobre os resíduos da janela do ARIMA (refação de 05/10, só as
# passagens com Janela_Estimacao=240 e sem intervalo de confiança) e sobre 500
# resíduos (estudo), na grade do período de teste de cada ação. O ARIMA é o
# mesmo nos dois (aquecimento conferido no item V1 do PROTOCOLO), então a
# diferença vem só da janela do GARCH (e do limiar por percentil, que passa a ser
# calculado sobre 500 pregões). Camada 1 (bruta). Grupos como no bloco 2 do
# analisar_grades.sh: "reduz" = targeting, filtro+targeting ou zerar no veto.
# Diferenças = 500 menos 240, em pontos percentuais.
# Uso (da raiz): bash ferramentas/scripts/efeito_janela_garch.sh > <saida>
raiz=$(cd "$(dirname "$0")/../.." && pwd)
A="$raiz/dados/resultados/refeito_2026-10-05/calibracao"
B="$raiz/dados/resultados/janelas_240_500_2026-10-26/calibracao"
echo "Mesma configuração com GARCH: 500 resíduos (estudo) menos 240 (TG), camada 1, grade do período de teste."
echo "n = pares; dDD, dVol, dRet = medianas em p.p.; caiu_DD = fração dos pares com queda máxima menor com 500."
printf "%-6s %-4s %-5s %4s %7s %8s %7s %7s\n" ativo per reduz n dDD caiu_DD dVol dRet
for a in PETR4 VALE3 USIM5 POMO4; do for k in 1 2 3; do
  gawk -F';' -v at="$a" -v pe="T$k" '
    function med(x, n,   y, m) { m = asort(x, y); return (m % 2) ? y[(m + 1) / 2] : (y[m / 2] + y[m / 2 + 1]) / 2 }
    FNR == 1 { arq++; delete h; for(i = 1; i <= NF; i++) h[$i] = i; next }
    $h["UsarGARCH"] + 0 != 1 || $h["Estrategia"] + 0 == 2 || $h["Janela_Estimacao"] + 0 != 240 { next }
    { k = ""; split("Estrategia ModoLimiar Limiar_Percentil Limiar_Absoluto Vol_Alvo Limiar_Sinal SomenteCompra ZerarNoVeto IncluirConstante", P, " ")
      for(i in P) k = k ";" ($h[P[i]] + 0)
      if(arq == 1) { D[k] = $h["dd_puro"]; V[k] = $h["vol_puro"]; R[k] = $h["ret_puro"]; next }
      if(!(k in D)) { falta++; next }
      e = $h["Estrategia"] + 0; g = (e == 1 || e == 3 || $h["ZerarNoVeto"] + 0 == 1) ? "sim" : "nao"
      n[g]++; dd[g, n[g]] = $h["dd_puro"] - D[k]; dv[g, n[g]] = $h["vol_puro"] - V[k]; dr[g, n[g]] = $h["ret_puro"] - R[k]
      caiu[g] += ($h["dd_puro"] < D[k]) }
    END { for(gi = 1; gi <= 2; gi++) { g = (gi == 1 ? "sim" : "nao"); if(!n[g]) continue
            delete x1; delete x2; delete x3
            for(j = 1; j <= n[g]; j++) { x1[j] = dd[g, j]; x2[j] = dv[g, j]; x3[j] = dr[g, j] }
            printf "%-6s %-4s %-5s %4d %+7.1f %8.2f %+7.1f %+7.1f\n", at, pe, g, n[g], 100 * med(x1), caiu[g] / n[g], 100 * med(x2), 100 * med(x3) }
          if(falta) printf "AVISO: %d configurações do estudo sem par no TG\n", falta > "/dev/stderr" }' \
    "$A/${a}_T$k.csv" "$B/${a}_T$k.csv"
done; done
# Conferência: as passagens SEM GARCH (Janela_Estimacao=240) têm de ser
# idênticas nos dois (o aquecimento não muda o ARIMA).
echo; echo "Conferência: passagens sem GARCH, retorno e queda idênticos no TG e no estudo"
for a in PETR4 VALE3 USIM5 POMO4; do for k in 1 2 3; do
  gawk -F';' -v r="$a T$k" 'FNR == 1 { arq++; delete h; for(i = 1; i <= NF; i++) h[$i] = i; next }
    $h["UsarGARCH"] + 0 != 0 || $h["Janela_Estimacao"] + 0 != 240 { next }
    { k = ($h["Limiar_Sinal"] + 0) ";" ($h["SomenteCompra"] + 0) ";" ($h["IncluirConstante"] + 0); v = $h["ret_puro"] ";" $h["dd_puro"] }
    arq == 1 { R[k] = v; next } { n++; ig += (R[k] == v) }
    END { printf "%s: %d de %d iguais\n", r, ig, n }' "$A/${a}_T$k.csv" "$B/${a}_T$k.csv"
done; done
# Total de pares com GARCH (as 4 ações e os 3 períodos): a queda máxima com 500
# ficou menor, igual ou maior que com 240.
echo; echo "Total dos pares com GARCH: queda máxima com 500 menor / igual / maior que com 240"
for a in PETR4 VALE3 USIM5 POMO4; do for k in 1 2 3; do
  gawk -F';' 'FNR == 1 { arq++; delete h; for(i = 1; i <= NF; i++) h[$i] = i; next }
    $h["UsarGARCH"] + 0 != 1 || $h["Estrategia"] + 0 == 2 || $h["Janela_Estimacao"] + 0 != 240 { next }
    { k = ""; split("Estrategia ModoLimiar Limiar_Percentil Limiar_Absoluto Vol_Alvo Limiar_Sinal SomenteCompra ZerarNoVeto IncluirConstante", P, " ")
      for(i in P) k = k ";" ($h[P[i]] + 0) }
    arq == 1 { D[k] = $h["dd_puro"] + 0; next }
    { d = $h["dd_puro"] - D[k]; if(d < -1e-9) m++; else if(d > 1e-9) p++; else z++ }
    END { print m + 0, z + 0, p + 0 }' "$A/${a}_T$k.csv" "$B/${a}_T$k.csv"
done; done | awk '{ m += $1; z += $2; p += $3 } END { t = m + z + p
  printf "pares %d: menor %d (%.1f%%), igual %d (%.1f%%), maior %d (%.1f%%)\n", t, m, 100*m/t, z, 100*z/t, p, 100*p/t }'
