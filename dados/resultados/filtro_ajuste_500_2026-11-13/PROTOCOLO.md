# Protocolo: GARCH 500 só com filtro e ajuste, mantendo ou encerrando no veto (13/11/2026)

Escrito antes de rodar. Estudo à parte, **não entra no TG** sem pedido.

## Pedido (do autor, 13/11/2026)

Refazer todos os testes com a janela do GARCH em 500. Desta vez, todos os robôs
com GARCH usam o filtro e o ajuste da posição juntos (`Estrategia=3`). Rodar
separado: primeiro tudo mantendo a posição no veto (`ZerarNoVeto=false`, versão
**M**), depois tudo encerrando a posição no veto (`ZerarNoVeto=true`, versão
**E**). Depois, um relatório comparando com o que está no TG (janela do GARCH =
janela do ARIMA), com uma tabela do que a otimização escolheu nos demais
parâmetros (limiar, alvo, constante etc.).

## Montagem

- Mesmo molde do estudo das janelas de hoje (`janelas_garch_2026-11-13/`): ARIMA
  fixo em 240 pregões (`Janela_Estimacao=240`), `Janela_GARCH=500`, aquecimento
  de quatro anos (o testador começa quatro anos antes; o EA só opera e mede a
  partir de `Inicio_Operacao`), `MetodoARIMA=0`, AIC, GARCH normal.
- Grade só compra, a partir das sub-grades da rodada 3:
  - `arima` (sem GARCH, 4 configurações: constante × previsão mínima);
  - `ft_abs` (filtro e ajuste, limiar fixo de 2%, 3% ou 4% ao dia);
  - `ft_pct` (filtro e ajuste, limiar no percentil 50, 70 ou 90);
  - em ambas: alvo de 1% ou 2% ao dia, constante sim/não, previsão mínima 0 ou
    0,1%, e `ZerarNoVeto` **fixo** na versão.
  - Total: 4 + 24 + 24 = **52 passagens por janela e versão**.
- Ações e períodos (os do TG, só compra):

| janela | operação | papel | símbolo da PETR4 |
|---|---|---|---|
| C1 | 02/01/2004 a 29/12/2006 (outras ações: desde 01/02/2005) | otimização de T1 | `PETR4_DESDE1999` |
| T1 | 02/01/2007 a 30/12/2011 | teste | `PETR4_DESDE1999` |
| C2 | 04/01/2010 a 29/12/2012 | otimização de T2 | `PETR4_OFICIAL` |
| T2 | 02/01/2013 a 30/12/2016 | teste | idem |
| C3 | 03/01/2022 a 31/12/2024 | otimização de T3 | idem |
| T3 | 02/01/2025 a 19/09/2026 | teste | idem |
| C4 | 02/01/2014 a 30/12/2016 | otimização do teste principal | idem |
| T4 | 02/01/2017 a 30/12/2024 | teste principal (R6 no TG) | idem |

  PETR4, VALE3, USIM5 e POMO4. As outras ações só têm série desde 2003, e o GARCH
  de 500 não tem dados em 2004: a C1 delas começa em 01/02/2005, como no estudo de
  26/10.
- Ordem: todas as janelas da versão M (PETR4 primeiro), depois todas da versão E.

## Escolha (a mesma do TG)

`escolher.sh so_compra` na calibração de cada versão: GS = maior Sharpe, GC =
maior Calmar, AS = ARIMA sem GARCH de maior Sharpe, camada 3 (custos e Selic no
caixa). A escolha é feita dentro de cada versão: a M nunca vê as passagens da E.

## Testes

- PETR4, testes individuais (curva diária) em cada versão: T1, T2, T3 e T4 com GS,
  GC, as gêmeas (mesma configuração sem GARCH) e o ARIMA (AS); e os testes
  adicionais do TG com as escolhas de C2: 2017–2024 (L2) e 2005–2026 (L1, de
  03/01/2005 a 18/09/2026, `PETR4_DESDE1999`).
- Outras ações: resultado da configuração escolhida lido da grade do período de
  teste (`outras_acoes.sh`, como no TG).

## O que se compara (camada 1, bruta, como o Cap. III)

1. Configuração escolhida: TG × M × E, por período e robô (forma, limiar, alvo,
   posição no veto, constante, previsão mínima, índice na otimização).
2. Retorno, queda máxima e volatilidade dos robôs da PETR4: TG × M × E.
3. Cada versão com e sem o GARCH (gêmea), como a Tabela do efeito do GARCH no TG.
4. Outras ações: retorno e queda dos escolhidos, TG × M × E.
5. Na grade inteira de cada período de teste: mediana e dispersão de queda e
   retorno das 48 configurações com GARCH, M × E (o efeito de manter ou
   encerrar, com o resto igual, em pares).

## Conferências previstas

- 52 passagens em cada uma das 64 otimizações (32 janelas × 2 versões).
- Sub-grade `arima` idêntica entre M e E.
- PETR4: as passagens desta bateria iguais às de `janelas_garch_2026-11-13/`
  (janela 500, mesmas datas e aquecimento) com `Estrategia=3` e o mesmo
  `ZerarNoVeto`.
- Teste individual = passagem da grade do período de teste (GS e GC da PETR4).

## O que NÃO se conclui daqui

Comparar com o TG mistura duas mudanças: a janela do GARCH (240/120 → 500, e o
ARIMA fixo em 240) e a grade restrita. A grade inteira de hoje separa as duas
coisas só em parte (item 5 e `janelas_garch_2026-11-13/`). Um ativo principal,
quatro períodos, sem teste estatístico formal. Não se escolhe "a melhor versão"
pelo resultado do teste.
