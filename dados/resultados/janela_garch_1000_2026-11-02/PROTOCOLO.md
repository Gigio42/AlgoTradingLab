# Protocolo — GARCH com 1000 resíduos (02/11/2026)

Escrito antes de rodar. Pedido do autor em 02/11/2026: refazer os testes dos
períodos da parte principal do Cap. III (PETR4) com a janela do GARCH em 1000
pregões e comparar com o TG atual e com o estudo de 500
(`janelas_240_500_2026-10-26/`). **O TG não é alterado**: no texto, a janela do
GARCH fica como limitação (decisão do autor, 02/11/2026).

## Igual ao estudo de 500

ARIMA com janela fixa de 240 pregões; GARCH estimado sobre os últimos N
resíduos, calculados com os coeficientes do ARIMA do dia
(`Janela_GARCH`); limiar por percentil sobre esses N pregões; o EA só opera e
só mede a partir de `Inicio_Operacao`; mesma grade só compra (156
configurações: arima 4, filtro_abs 24, filtro_pct 24, targ 8, ft_abs 48,
ft_pct 48), mesmo critério (`escolher.sh so_compra`: maior Sharpe e maior
Calmar na camada 3), mesmos testes individuais (GS, GC, gêmeas, AS), capital,
custos e execução. As médias móveis não dependem da mudança e são copiadas da
refação de 05/10.

## O que muda

1. `Janela_GARCH=1000` (antes 500).
2. **Aquecimento de quatro anos**: cada simulação começa quatro anos antes da
   data oficial (o testador ainda entrega o ano anterior, ≈ 5 anos ≈ 1.240
   pregões antes da primeira operação; são precisos 1000 mais as defasagens).
3. **Só a PETR4.** As outras ações não fazem parte da parte principal.
4. **Só a grade só compra** (r3, 156) também em C2 e C3. O estudo de 500
   rodou ali a grade com venda a descoberto (312) e filtrou só compra; o
   subconjunto é o mesmo.
5. **2007–2011 e o período longo.** A série oficial começa em 02/01/2003 e o
   1000º pregão é 10/01/2007 (`dados/series/PETR4_OFICIAL.csv`). A otimização
   de 2004–2006 (C1) não pode ser feita com 1000 resíduos. O tratamento de
   2007–2011 depende de decisão do autor e fica registrado abaixo quando
   tomado.

   **Decisão do autor (02/11/2026, antes de rodar C1): estender a série da
   B3.** Baixados os COTAHIST de 1998 a 2002 (`dados/FONTES.md`, item 14) e
   montado o símbolo `PETR4_DESDE1999`, idêntico ao `PETR4_OFICIAL` a partir
   de 02/01/2003. C1 (2004–2006), T1 (2007–2011) e L1 rodam nele; as demais
   janelas continuam no `PETR4_OFICIAL`. Conferência feita antes: a sub-grade
   arima de C2 dá o mesmo resultado nos dois símbolos (4 passagens, negócios e
   retornos iguais). Com isso o L1 volta a começar em 03/01/2005, como no TG
   (no estudo de 500, 01/02/2005).

## Janelas

| Nome | Operação | Testador desde |
|---|---|---|
| C2 | 04/01/2010 a 29/12/2012 | 02/01/2006 |
| T2 | 02/01/2013 a 30/12/2016 | 02/01/2009 |
| C4 | 02/01/2014 a 30/12/2016 | 04/01/2010 |
| R6 | 02/01/2017 a 30/12/2024 | 02/01/2013 |
| C3 | 03/01/2022 a 31/12/2024 | 02/01/2018 |
| T3 | 02/01/2025 a 19/09/2026 | 04/01/2021 |
| C1 | 02/01/2004 a 29/12/2006 | 03/01/2000 |
| T1 | 02/01/2007 a 30/12/2011 | 02/01/2003 |
| L1 | 03/01/2005 a 18/09/2026 | 02/01/2001 |
| L2 | 02/01/2017 a 30/12/2024 | 02/01/2013 |

## Conferências

- contagem de passagens: 156 por janela;
- as passagens sem GARCH (4 por janela) têm de ser idênticas às do estudo de
  500 nas mesmas janelas (a janela do GARCH não as afeta);
- o ARIMA-GARCH Sharpe de 2017–2024 roda com traço: nenhum pregão de operação
  sem volatilidade estimada;
- saldo final do relatório do MT5 = 100.000 × (1 + `ret_puro`).

Script: `ferramentas/scripts/janela_garch_1000.sh`.
