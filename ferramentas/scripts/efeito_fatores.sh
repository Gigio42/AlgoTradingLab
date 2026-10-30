#!/bin/bash
# efeito_fatores.sh [T|C]
#
# Estudo de fatores de 27/10/2026 (PROTOCOLO.md, análise 1): para cada fator
# (DistribuicaoGARCH, SelecaoPorBIC, Barras_Entre_Reselecao), os pares de
# passagens que diferem só nele, nas grades dos períodos de teste (T, padrão) ou
# de calibração (C) das 4 ações. Camada 1 (bruta). Diferença = opção nova
# (t, BIC, 63) menos a de sempre (normal, AIC, 21), em pontos percentuais.
# Grupos: "reduz" = targeting, filtro+targeting ou zerar no veto; "filtro" = só
# filtra e mantém a posição; "arima" = sem GARCH (só para BIC e reseleção).
# No fim, a conferência com o estudo de 26/10 (mesmas configurações).
# Uso (da raiz): bash ferramentas/scripts/efeito_fatores.sh [T|C] > <saida>
raiz=$(cd "$(dirname "$0")/../.." && pwd)
F="$raiz/dados/resultados/fatores_500_2026-10-27/calibracao"
J="$raiz/dados/resultados/janelas_240_500_2026-10-26/calibracao"
P=${1:-T}
CHAVE="UsarGARCH Estrategia ModoLimiar Limiar_Percentil Limiar_Absoluto Vol_Alvo Limiar_Sinal SomenteCompra ZerarNoVeto IncluirConstante DistribuicaoGARCH SelecaoPorBIC Barras_Entre_Reselecao"
echo "Efeito pareado de cada fator, grades de $([ "$P" = T ] && echo teste || echo calibração), camada 1."
echo "n = pares; dDD, dVol, dRet = medianas em p.p.; caiu_DD = fração dos pares com queda máxima menor na opção nova."
for fator in DistribuicaoGARCH SelecaoPorBIC Barras_Entre_Reselecao; do
  echo; echo "== $fator"
  printf "%-6s %-4s %-7s %4s %7s %8s %7s %7s\n" ativo per grupo n dDD caiu_DD dVol dRet
  for a in PETR4 VALE3 USIM5 POMO4; do for k in 1 2 3; do
    gawk -F';' -v at="$a" -v pe="$P$k" -v fa="$fator" -v chave="$CHAVE" '
      function med(x,   y, m) { m = asort(x, y); return (m % 2) ? y[(m + 1) / 2] : (y[m / 2] + y[m / 2 + 1]) / 2 }
      NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; nc = split(chave, C, " "); next }
      { k = ""; for(i = 1; i <= nc; i++) if(C[i] != fa) k = k ";" ($h[C[i]] + 0)
        novo = ($h[fa] + 0 != (fa == "Barras_Entre_Reselecao" ? 21 : 0))
        if(novo) { N[k] = 1; dn[k] = $h["dd_puro"]; vn[k] = $h["vol_puro"]; rn[k] = $h["ret_puro"] }
        else { V[k] = 1; dv[k] = $h["dd_puro"]; vv[k] = $h["vol_puro"]; rv[k] = $h["ret_puro"] }
        e = $h["Estrategia"] + 0
        G[k] = ($h["UsarGARCH"] + 0 == 0) ? "arima" : (e == 1 || e == 3 || $h["ZerarNoVeto"] + 0 == 1) ? "reduz" : "filtro" }
      END { for(k in N) if(k in V) { g = G[k]; n[g]++
              a1[g, n[g]] = dn[k] - dv[k]; a2[g, n[g]] = vn[k] - vv[k]; a3[g, n[g]] = rn[k] - rv[k]; caiu[g] += (dn[k] < dv[k] - 1e-9) }
            split("reduz filtro arima", O, " ")
            for(gi = 1; gi <= 3; gi++) { g = O[gi]; if(!n[g]) continue
              delete x1; delete x2; delete x3
              for(j = 1; j <= n[g]; j++) { x1[j] = a1[g, j]; x2[j] = a2[g, j]; x3[j] = a3[g, j] }
              printf "%-6s %-4s %-7s %4d %+7.1f %8.2f %+7.1f %+7.1f\n", at, pe, g, n[g], 100 * med(x1), caiu[g] / n[g], 100 * med(x2), 100 * med(x3) } }' \
      "$F/${a}_$P$k.csv"
  done; done
  # Total do fator: queda máxima menor, igual ou maior na opção nova
  for a in PETR4 VALE3 USIM5 POMO4; do for k in 1 2 3; do
    gawk -F';' -v fa="$fator" -v chave="$CHAVE" '
      NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; nc = split(chave, C, " "); next }
      { k = ""; for(i = 1; i <= nc; i++) if(C[i] != fa) k = k ";" ($h[C[i]] + 0)
        if($h[fa] + 0 != (fa == "Barras_Entre_Reselecao" ? 21 : 0)) dn[k] = $h["dd_puro"] + 0; else dv[k] = $h["dd_puro"] + 0 }
      END { for(k in dn) if(k in dv) { d = dn[k] - dv[k]; if(d < -1e-9) m++; else if(d > 1e-9) p++; else z++ }; print m + 0, z + 0, p + 0 }' "$F/${a}_$P$k.csv"
  done; done | awk '{ m += $1; z += $2; p += $3 } END { t = m + z + p
    printf "total %d pares: queda menor %d (%.1f%%), igual %d (%.1f%%), maior %d (%.1f%%)\n", t, m, 100*m/t, z, 100*z/t, p, 100*p/t }'
done
# Conferência: normal, AIC e reseleção 21 são as configurações do estudo de
# 26/10 (só compra); retorno e queda têm de ser idênticos.
echo; echo "Conferência: passagens normal/AIC/21 iguais às do estudo de 26/10 (só compra)"
for a in PETR4 VALE3 USIM5 POMO4; do for k in 1 2 3; do
  gawk -F';' -v r="$a $P$k" -v chave="$CHAVE" '
    FNR == 1 { arq++; delete h; for(i = 1; i <= NF; i++) h[$i] = i; nc = split(chave, C, " "); next }
    $h["SomenteCompra"] + 0 != 1 { next }
    arq == 2 && ($h["DistribuicaoGARCH"] + 0 != 0 || $h["SelecaoPorBIC"] + 0 != 0 || $h["Barras_Entre_Reselecao"] + 0 != 21) { next }
    { k = ""; for(i = 1; i <= nc - 3; i++) k = k ";" ($h[C[i]] + 0); v = $h["ret_puro"] ";" $h["dd_puro"] }
    arq == 1 { R[k] = v; next } { n++; ig += (R[k] == v) }
    END { printf "%s: %d de %d iguais\n", r, ig, n }' "$J/${a}_$P$k.csv" "$F/${a}_$P$k.csv"
done; done
