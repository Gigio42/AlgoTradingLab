#!/bin/bash
# outras_acoes.sh
#
# Resultado bruto (camada 1) das configurações escolhidas em cada ação e período,
# só compra, para a seção de outras ações do Cap. III. Nada é simulado de novo:
#   1. aplica escolher.sh (so_compra) à calibração de cada janela
#      (refeito_2026-10-05/calibracao/<ATIVO>_C<k>.csv);
#   2. procura a mesma configuração na grade rodada no período de teste
#      (<ATIVO>_T<k>.csv; a passagem da grade é igual ao teste individual,
#      conferido na auditoria de 24/09, INCERTEZAS item 21);
#   3. imprime retorno, queda máxima e volatilidade brutos e a compra e
#      manutenção pela variação do preço.
# A PETR4 entra como conferência: tem de bater com cru/tabelas.txt.
#
# SEM_IC=1 (padrão desde 21/10/2026) tira da calibração as passagens com
# intervalo de confiança (Estrategia=2) antes da escolha: a forma saiu do escopo
# do TG a pedido do autor. SEM_IC=0 reproduz a versão de 19/10, guardada em
# cru/outras_acoes_com_ic_2026-10-19.txt.
#
# Saída: dados/resultados/refeito_2026-10-05/cru/outras_acoes.txt
# Uso (da raiz do repositório): bash ferramentas/scripts/outras_acoes.sh
set -e
raiz=$(cd "$(dirname "$0")/../.." && pwd)
RES="${RES:-$raiz/dados/resultados/refeito_2026-10-05}"   # outra pasta: estudo de 26/10
C="$RES/calibracao"
O="$RES/cru/outras_acoes.txt"
S="$raiz/ferramentas/scripts"
SEM_IC="${SEM_IC:-1}"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

{
  echo "Camada 1 (bruta), só compra. Escolha: escolher.sh so_compra na calibração; resultado: mesma configuração na grade do teste."
  [ "$SEM_IC" = 1 ] && echo "Sem as passagens com intervalo de confiança (Estrategia=2), fora do escopo desde 21/10/2026."
  echo "Colunas: ret_puro, dd_puro, vol_puro, saidas; PETR4 = bh_preco, dd_bh_preco, vol_bh_preco."
  for a in PETR4 VALE3 USIM5 POMO4; do
    for k in 1 2 3; do
      echo; echo "== $a T$k"
      cal="$C/${a}_C$k.csv"
      if [ "$SEM_IC" = 1 ]; then
        LC_ALL=C awk -F';' 'NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; print; next }
          !($h["UsarGARCH"] + 0 == 1 && $h["Estrategia"] + 0 == 2)' "$cal" > "$T/cal.csv"
        cal="$T/cal.csv"
      fi
      bash "$S/escolher.sh" "$cal" so_compra | grep -E '^(GS|GC|AS) ' |
      while IFS= read -r l; do
        rob=${l%% *}; par=${l#*| }
        LC_ALL=C awk -F';' -v alvo="$par" -v rob="$rob" '
          NR == 1 { for(i = 1; i <= NF; i++) h[$i] = i; next }
          function v(c) { return (c in h) ? $h[c] : "" }
          function b(x) { return (x + 0 == 1) ? "true" : "false" }
          { p = "UsarGARCH=" b(v("UsarGARCH"))
            if(v("UsarGARCH") + 0 == 1)
              p = p " Estrategia=" v("Estrategia") " ModoLimiar=" v("ModoLimiar") \
                  " Limiar_Percentil=" v("Limiar_Percentil") " Limiar_Absoluto=" v("Limiar_Absoluto") \
                  " K_Confianca=" v("K_Confianca") " Vol_Alvo=" v("Vol_Alvo") " ZerarNoVeto=" b(v("ZerarNoVeto"))
            p = p " Janela_Estimacao=" v("Janela_Estimacao") " IncluirConstante=" b(v("IncluirConstante")) \
                " Limiar_Sinal=" v("Limiar_Sinal") " SomenteCompra=" b(v("SomenteCompra"))
            if(p == alvo && !achou) { achou = 1
              printf "%-3s ret=%+7.1f queda=%5.1f vol=%5.1f saidas=%4d estrategia=%s zera=%s\n", rob,
                     100*v("ret_puro"), 100*v("dd_puro"), 100*v("vol_puro"), v("saidas"),
                     (v("UsarGARCH") + 0 == 1 ? v("Estrategia") : "-"), (v("UsarGARCH") + 0 == 1 ? b(v("ZerarNoVeto")) : "-")
              bh = sprintf("B&H ret=%+7.1f queda=%5.1f vol=%5.1f", 100*v("bh_preco"), 100*v("dd_bh_preco"), 100*v("vol_bh_preco")) } }
          END { if(!achou) { print rob " NÃO ENCONTRADA: " alvo; exit 1 } if(rob == "AS") print bh }' "$C/${a}_T$k.csv"
      done
    done
  done
} > "$O"
echo "gerado em $O"
