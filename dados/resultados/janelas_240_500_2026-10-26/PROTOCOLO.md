# Protocolo — janelas fixas, ARIMA 240 e GARCH 500 (26/10/2026)

Escrito antes de rodar. Origem: crítica da orientadora sobre a janela curta do
GARCH e pedido do autor de ver o Cap. III refeito nessas condições, sem mexer
no TG (notas/INCERTEZAS.md, item 78).

## O que muda em relação à refação de 05/10/2026

1. **ARIMA com janela fixa de 240 pregões.** `Janela_Estimacao=240` em todas
   as configurações; a janela sai da grade (antes 120 ou 240).
2. **GARCH com 500 resíduos.** Input novo `Janela_GARCH=500`: o GARCH é
   estimado sobre os 500 resíduos mais recentes, calculados com os
   coeficientes do ARIMA do dia sobre uma série mais longa
   (`CArima::ResiduosSobre`). O limiar por percentil passa a ser o percentil
   da volatilidade condicional nesses 500 pregões. Com `Janela_GARCH=0`
   (padrão) o EA faz o que fazia antes (regressão byte a byte).
3. **Aquecimento.** O testador só entrega histórico a partir de 1º de janeiro
   do ano anterior ao início. Cada simulação começa dois anos antes da data
   oficial e o EA só opera e só mede a partir de `Inicio_Operacao` (input
   novo, fora do Apêndice A). Antes dessa data ele não faz nada, e na primeira
   barra de operação as ordens são reavaliadas.
4. **C1 e L1 começam em 01/02/2005** (antes 02/01/2004 e 03/01/2005): a série
   oficial começa em 02/01/2003 e só tem os 500 pregões a partir de meados de
   janeiro de 2005 (499 pregões até 30/12/2004).
5. **Sem intervalo de confiança** (fora do escopo desde 21/10).

## O que não muda

Ativos (PETR4, VALE3, USIM5, POMO4), séries `*_OFICIAL`, janelas de teste,
demais parâmetros da grade (formas de uso do GARCH, percentis, alvo, zerar no
veto, constante, previsão mínima, venda a descoberto na rodada 4), critério de
escolha (`escolher.sh`: maior Sharpe e maior Calmar na camada 3, só compra para
a PETR4), capital, custos e execução. As médias móveis não dependem da mudança
e são copiadas da refação de 05/10.

## Grade

As sub-grades das rodadas 3 e 4 sem a linha da janela. Só compra (rodada 3,
a do texto): arima 4, filtro_abs 24, filtro_pct 24, targ 8, ft_abs 48,
ft_pct 48 = **156 configurações** (antes 312). Com venda a descoberto
(rodada 4): o dobro, 312 por ativo e janela. Total: 4 ativos × 6 janelas × 312
+ C4 156 = 7.644 passagens.

## Testes individuais

R3 (T1, T2, T3): GS, GSgemeo, GC, GCgemeo, AS, AC. R6 (2017–2024, escolhas de
C4): GS (com traço), GSgemeo, GC, GCgemeo, ARIMA. L1 (01/02/2005–18/09/2026) e
L2 (2017–2024) com GS, GC e gêmeas das escolhas de C2.

## Conferências antes da bateria

- regressão do código (`regressao_codigo.sh`), 12 casos, idênticos;
- ARIMA sem GARCH com aquecimento = R6_GSgemeo da refação (curva e métricas);
- GS com GARCH 500 e aquecimento: curva começa em 02/01/2017 e o GARCH não
  falha por falta de histórico.

Script: `ferramentas/scripts/janelas_240_500.sh`.
