# GARCH com erros t de Student — protocolo (escrito em 13/10/2026, ANTES dos resultados)

## Pergunta

Pedido do autor depois da leitura de Thomaz (2019): trocar a distribuição dos
erros do GARCH de normal para t de Student muda o desempenho do robô?

Thomaz (2019) mostra que a t descreve melhor a volatilidade de ações brasileiras
(ABEV3, BBDC3, VALE3, 2007–2018). A PETR4 tem curtose ainda maior (14,5 na série
de 2003–2026, conta rápida, não está no TG). Mas ele mediu o erro da previsão da
volatilidade, não o resultado de operar. É isso que se mede aqui.

## O que muda e o que não muda

- Muda só a verossimilhança do GARCH (`Include/Garch.mqh`, `DIST_STUDENT`): os
  graus de liberdade ν são estimados junto com ω, α e β, a cada barra.
- Não muda: a equação da variância, a previsão, o ARIMA, o limiar, a estratégia,
  as janelas e os custos. O input `DistribuicaoGARCH` tem padrão normal.
- **Não há nova calibração.** As configurações são as escolhidas na refação
  (`../refeito_2026-10-05/escolhas/`), com a distribuição normal. Isto mede o
  efeito de trocar só a distribuição, com tudo o mais fixo. Não responde "qual
  seria o resultado se o TG tivesse calibrado com a t".

## Verificações antes dos testes

1. **Validação em séries sintéticas** (`ferramentas/ValidarGarchT_EA.mq5`,
   saída em `dados/verificacao/validacao_garch_t_2026-10-13.txt`): o estimador t
   tem de recuperar ν de uma série t e dar ν grande numa série normal.
2. **Regressão**: com `DistribuicaoGARCH=0`, o EA modificado tem de reproduzir a
   curva de `R6_GS` da refação **byte a byte**. Se não reproduzir, parar.

## Testes

As 11 configurações com GARCH da Tabela de significância do TG, mais o cenário
de Almeida 2013–2016, cada uma rodada com `DistribuicaoGARCH=1` (rótulo
`TS_<rótulo original>`):

| Rótulo | Período | Configuração |
|---|---|---|
| TS_R3_T1_GS (= GC) | 2007–2011 | GS de C1 |
| TS_R3_T2_GS, TS_R3_T2_GC | 2013–2016 | GS e GC de C2 |
| TS_R3_T3_GS, TS_R3_T3_GC | 2025–18/09/2026 | GS e GC de C3 |
| TS_R6_GS, TS_R6_GC | 2017–2024 | GS e GC de C4 |
| TS_L1_GS, TS_L1_GC | 2005–2026 | GS e GC de C2, fixas |
| TS_L2_GS, TS_L2_GC | 2017–2024 | GS e GC de C2, fixas |
| TS_cenA_1316_GARCH | 22/05/2013–24/05/2016 | condições de Almeida (`cenario_almeida.sh`) |

## O que se compara (declarado antes)

Para cada configuração:

1. **t × normal** (mesma configuração): retorno, queda máxima, Sharpe, operações
   e vetos. Teste pareado de Sharpe (Jobson-Korkie-Memmel) e t pareado dos
   retornos diários.
2. **t × gêmea sem GARCH**: a proteção se mantém? (queda máxima menor nos 11 pares?)

Leitura prevista: com 11 pares, uma diferença só é tratada como efeito da
distribuição se for na mesma direção na maioria dos pares. Uma diferença isolada
não basta.
