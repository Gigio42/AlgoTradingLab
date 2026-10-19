# Bateria de 15/10/2026 — protocolo (escrito ANTES dos testes de mercado)

Pedido do autor em 15/10/2026: rodar "todos os testes que falamos", guardar e,
se possível, analisar; a decisão sobre o texto é dele. Este protocolo fixa as
regras antes de qualquer resultado de mercado. O que não estiver aqui e for
decidido depois de ver números vai marcado como **análise posterior**.

Base: a refação de 05/10 (`../refeito_2026-10-05/PROTOCOLO.md`). Mudam três
coisas, todas combinadas com o autor e anotadas em `PENDENCIAS.md`.

## 1. Estimação do ARIMA (passo 4 do PENDENCIAS, item 1)

A estimação por máxima verossimilhança condicional (`MetodoARIMA=1`) só vira o
padrão se a validação sintética (`dados/verificacao/validacao_mv_arima_2026-10-15.txt`)
mostrar as três coisas abaixo. Senão, fica o Hannan-Rissanen (`MetodoARIMA=0`)
e a máxima verossimilhança vai para trabalhos futuros:

1. **precisão:** erro quadrático médio dos coeficientes menor ou igual ao do
   Hannan-Rissanen na maioria dos casos do Monte Carlo (janela de 240);
2. **convergência:** volta ao Hannan-Rissanen em menos de 5% dos ajustes;
3. **tempo:** a bateria inteira cabe na noite (estimativa a partir do tempo
   por ajuste medido na validação).

A decisão é registrada na seção 6 deste arquivo **antes** da primeira
otimização. Depois dela, o método não muda por causa de resultado de mercado.

## 2. Critério de escolha: fator de recuperação, um só

- Universo: a grade da rodada 3 (344 configurações só-compra, sub-grades em
  `../rodada3_b3_oficial/grades/`), otimizada nos 3 anos anteriores a cada
  teste.
- **Versão escolhida (GR):** maior `fator_recuperacao_mt5` (o
  `STAT_RECOVERY_FACTOR` do próprio testador: lucro líquido / rebaixamento
  máximo do patrimônio, sem custo e sem Selic) entre as configurações com
  GARCH.
- **ARIMA (AR):** o mesmo critério entre as configurações sem GARCH.
- **Sem GARCH (GRgemeo):** a configuração da GR com `UsarGARCH=false`.
- **Guarda contra o robô parado:** só concorrem configurações com pelo menos 12
  negociações encerradas (`saidas`) nos 3 anos de otimização (uma a cada três
  meses, em média). Se nenhuma atingir, concorrem todas.
- Desempate: menos negociações; depois, ordem alfabética da linha de
  parâmetros.
- As escolhas por Sharpe e por Calmar (versões A e B) continuam sendo gravadas
  pelo `escolher.sh` em `escolhas/`, só para registro. **Não são testadas.**

## 3. Períodos

| Otimização | Teste | Rótulo |
|---|---|---|
| 2004-01-02 a 2006-12-30 | 2007-01-02 a 2011-12-30 | T1 (crise de 2008) |
| 2010-01-04 a 2012-12-29 | 2013-01-02 a 2016-12-30 | T2 |
| 2014-01-02 a 2016-12-30 | 2017-01-02 a 2024-12-30 | R6 (principal) |
| 2022-01-03 a 2024-12-31 | 2025-01-02 a 2026-09-19 | T3 |
| **2017-01-02 a 2019-12-30** | **2020-01-02 a 2021-12-30** | **T5 (pandemia, novo)** |
| 2010-01-04 a 2012-12-29 | 2005-01-03 a 2026-09-18 e 2017-2024 | L1, L2 (fixas, GR de C2) |

Mais: o cenário de Almeida (`cenario_almeida.sh`, configurações fixas, sem
otimização), as médias móveis reproduzidas em todos os testes, o traço diário
da GR de R6 e, se a estimação mudar, a bateria das quatro ações (PETR4, VALE3,
USIM5, POMO4; grade de 688 com venda a descoberto; C1, T1, C2, T2, C3, T3).
Se a estimação não mudar, a bateria das quatro ações da refação de 05/10 vale
como está (a análise por pares não depende do critério de escolha).

## 4. Medida principal e camadas

- **Resultado principal: camada 1, "pura"** (sem custo, sem Selic no caixa,
  sem proventos), como Almeida (2016) e o relatório do MT5: `ret_puro`,
  `dd_puro`, `vol_puro`.
- Camadas adicionais, da mesma simulação: 2 = + custo de 0,03% por lado
  (`ret_custos`), 3 = + caixa na Selic (`ret_selic`, `dd_selic`, `vol_selic`),
  4 = + proventos (`ret_completo`). Compra e manutenção: `bh_preco` e
  `bh_total`.
- Comparações estatísticas (Pitman-Morgan, Sharpe, t pareado) rodadas nas duas
  versões de curva: camada 3 (a do `comparar.sh`) e camada 1 (curva "pura").

## 5. Entradas fixadas explicitamente em toda execução

`DistribuicaoGARCH=0` (normal) e `MetodoARIMA=<decisão da seção 6>`. Entrada
ausente no `[TesterInputs]` vem do `.set` salvo, não do padrão do código
(CLAUDE.md).

## 6. Decisão sobre a estimação (preencher antes da primeira otimização)

**Decidido em 15/10/2026, ~03:10, antes de qualquer otimização: fica o
Hannan-Rissanen (`MetodoARIMA=0`).** A máxima verossimilhança condicional vai
para trabalhos futuros (ou para uma frase no texto, a critério do autor).

Base: `dados/verificacao/validacao_mv_arima_2026-10-15.txt` (EA
`ferramentas/ValidarMVArima_EA.mq5`, rodado no testador em 208 s).

1. **Precisão — não passou.** Erro quadrático médio dos coeficientes, janela de
   240, 300 réplicas: MV melhor em ARMA(1,1) forte (phi 0,067 x 0,070; theta
   0,075 x 0,096) e em MA(1) (0,056 x 0,071); igual em AR(1) fraco (0,0613 x
   0,0612); **muito pior** em ARMA(1,1) com raízes quase canceladas, phi 0,3 e
   theta -0,2 (phi 0,477 x 0,266; theta 0,481 x 0,261). Melhor em 2 de 4.
2. **Convergência — passou.** Voltou ao HR em 32 de 9.503 ajustes (0,34%).
3. **Tempo — no limite.** Por ajuste: 34x (1,0), 6x (1,1), 49x (2,2) e 196x
   (4,4) mais lento. A busca de ordens ajusta os 25 candidatos até (4,4) a cada
   21 pregões.

Achado que pesou além dos critérios: **com a MV, o AIC acertou a ordem
verdadeira muito menos vezes** (ARMA(1,1): 12% x 40%; AR(1): 8% x 58%, 150
réplicas). E o caso em que a MV foi muito pior (AR e MA quase se anulando) é o
que aparece na PETR4: em 428 pregões reais, a MV deu phi 0,652 e theta -0,572,
coeficientes grandes que se cancelam, para ganho de 0,46 na log-verossimilhança
(HR: phi 0,175, theta -0,100).

Consequência: a bateria roda com `MetodoARIMA=0`, e a grade das quatro ações
da refação de 05/10 continua valendo (a estimação não mudou, e a análise por
pares não depende do critério de escolha).
