# Rodada 3 — protocolo (escrito em 22/09/2026, ANTES de ver os resultados)

## Dados
`PETR4_OFICIAL` (B3 COTAHIST, corrigida só por desdobramentos), Selic SGS 11,
proventos do Yahoo só na camada 4. Procedência em `dados/FONTES.md`.

## Períodos (calibração = os 3 anos anteriores ao teste)

| Teste | Período de teste | Calibração | Por quê |
|---|---|---|---|
| T1 | 02/01/2007 – 30/12/2011 | C1: 02/01/2004 – 29/12/2006 | período de crise de Almeida (2016) |
| T2 | 02/01/2013 – 30/12/2016 | C2: 04/01/2010 – 28/12/2012 | outro período de Almeida |
| T3 | 02/01/2025 – 18/09/2026 | C3: 03/01/2022 – 30/12/2024 | período recente, até o último dado |

## Grade (9.216 passagens por janela, `grade2.txt`)
- GARCH on/off; estratégias filtro / targeting / intervalo de confiança /
  filtro+targeting;
- limiar **fixo** (2%, 3%, 4% ao dia) ou **relativo** (percentil 50/70/90);
- zerar a posição no veto (sim/não); alvo do targeting 1% ou 2% ao dia;
  k = 0,05/0,15;
- janela de estimação 120/240; com/sem constante; limiar de sinal 0 ou 0,1%.
- Fixos: ordens (p,d,q) por ADF+AIC reavaliadas a cada 21 barras sobre 240;
  só compra; 95% do patrimônio; custo 0,03% por lado.

## Critérios de escolha (declarados antes)
Calculados **só na calibração**, na camada 3 (custos + caixa na Selic, sem
proventos):

1. **Maior Sharpe sobre a Selic** — "melhor retorno por unidade de risco".
2. **Maior Calmar** (retorno anual ÷ drawdown máximo) — "mais segurança".

Cada critério é aplicado separadamente à família ARIMA-GARCH e à família ARIMA
puro. Desempate: menos operações. A configuração escolhida é aplicada **sem
alteração** ao período de teste.

## Referências fixas em cada período de teste
Selic acumulada; PETR4 comprada e mantida (só preço e com proventos); MM 10/20
de Almeida (só compra, 95% do capital, mesmos custos).

## O que será reportado além das escolhidas
Para dar a medida honesta do que o GARCH faz, e não só da configuração vencedora:
- distribuição dos resultados de **todas** as configurações no teste;
- efeito pareado do GARCH (mesma base de ARIMA, GARCH ligado − desligado);
- correlação de postos entre calibração e teste.
