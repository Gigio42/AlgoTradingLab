# Rodada 3 — ARIMA × ARIMA-GARCH × Médias Móveis (Almeida), dados oficiais B3

> **SUPERADO em 06/10/2026** pela refação com o EA corrigido
> (`../refeito_2026-10-05/LEIAME.md`; erros em `notas/INCERTEZAS.md`, itens 43 a
> 47). Os números desta pasta foram produzidos com o EA antigo e não vão para o TG.


Executada em 22/09/2026, segundo o `PROTOCOLO.md` (escrito antes dos
resultados). Dados em `dados/FONTES.md`; limitações em `notas/INCERTEZAS.md`.
Todos os números abaixo saem dos arquivos desta pasta.

## Como ler

- **Camadas de resultado** (o modelo nunca vê custos, Selic ou proventos):
  1. **puro:** só as posições, caixa rende zero;
  2. **+ custos:** 0,03% por lado;
  3. **+ Selic:** o capital fora da ação rende a Selic. **É a camada de
     referência**, feita só com dados oficiais;
  4. **+ proventos:** adendo, com fonte não oficial.
- **Sharpe** é calculado contra a Selic: **> 0 significa que rendeu mais que a
  Selic por unidade de risco**. O p é o do teste de Sharpe > 0; abaixo de 0,05,
  é pouco provável que seja sorte.
- **Queda máx.** é o drawdown: a maior queda do topo ao fundo.
- **Calmar** = retorno anual ÷ queda máxima.
- **Siglas:**
  - **GS / GC:** ARIMA-GARCH escolhido na calibração pelo maior Sharpe / maior
    Calmar;
  - **gêmeo:** o mesmo ARIMA com o GARCH desligado, que isola o efeito do
    GARCH;
  - **ARIMA:** ARIMA puro escolhido na calibração (o mesmo pelos dois
    critérios nos três períodos);
  - **MM:** médias móveis 10/20 de Almeida, só compra, 95% do capital, mesmos
    custos.

## Configurações escolhidas (só com os 3 anos anteriores a cada teste)

| Teste | ARIMA-GARCH por Sharpe (GS) | ARIMA-GARCH por Calmar (GC) | ARIMA |
|---|---|---|---|
| T1 2007–2011 | filtro+targeting, percentil 90, alvo 1%, zera no veto, janela 120 | igual ao GS | janela 240 |
| T2 2013–2016 | filtro, percentil 50, janela 120 | filtro+targeting, percentil 50, alvo 1%, zera no veto, janela 240 | janela 120 |
| T3 2025–2026 | filtro+targeting, percentil 90, alvo 2%, zera no veto, janela 240, limiar de sinal 0,1% | igual ao GS, alvo 1% | janela 240, limiar de sinal 0,1% |

Todas: ordens (p,d,q) por ADF+AIC reavaliadas a cada 21 barras, sem constante,
só compra.

## Referências de cada período (iguais em todos os testes)

| | Selic | PETR4 comprada (só preço) | PETR4 com proventos |
|---|---|---|---|
| **T1** 02/01/2007–29/12/2011 (4,9 anos) | +68,1% (11,2% a.a.) | −14,0% · queda máx. 67,2% · Sharpe −0,10 | −1,2% |
| **T2** 02/01/2013–29/12/2016 (3,9 anos) | +53,9% (11,6% a.a.) | −25,6% · queda máx. 83,1% · Sharpe −0,02 | −17,7% |
| **T3** 02/01/2025–18/09/2026 (1,7 ano) | +25,7% (14,4% a.a.) | +33,2% · queda máx. 25,1% · Sharpe 0,26 | +57,6% |

## Resultado principal (camada 3)

### T1 — 2007 a 2011 (crise de 2008)

| | Retorno | a.a. | Queda máx. | Volat. | Sharpe (p) | Calmar | Oper. | Acerto | FL | Exposição |
|---|---|---|---|---|---|---|---|---|---|---|
| **ARIMA-GARCH (GS = GC)** | **+17,2%** | 3,3% | **19,3%** | 10,8% | −0,63 (0,92) | **0,17** | 255 | 49% | 0,84 | 22% |
| gêmeo sem GARCH | +10,1% | 2,0% | 43,3% | 28,5% | −0,16 (0,64) | 0,05 | 294 | 50% | 0,95 | 50% |
| ARIMA | −11,4% | −2,4% | 44,6% | 28,0% | −0,32 (0,76) | −0,05 | 310 | 50% | 0,89 | 48% |
| MM (Almeida) | −11,6% | −2,5% | 57,5% | 28,7% | −0,31 (0,76) | −0,04 | 31 | 45% | 0,78 | 48% |

### T2 — 2013 a 2016 (queda da PETR4 e recuperação de 2016)

| | Retorno | a.a. | Queda máx. | Volat. | Sharpe (p) | Calmar | Oper. | Acerto | FL | Exposição |
|---|---|---|---|---|---|---|---|---|---|---|
| **ARIMA-GARCH (GS)** | **+325,3%** | 44,5% | 26,1% | 43,5% | **0,80 (0,056)** | **1,70** | 130 | 52% | 1,77 | 50% |
| ARIMA-GARCH (GC) | +34,0% | 7,7% | **6,8%** | 7,1% | −0,46 (0,82) | 1,14 | 141 | 42% | 0,85 | 9% |
| gêmeo do GC sem GARCH | −3,7% | −0,9% | 50,9% | 35,1% | −0,16 (0,63) | −0,02 | 267 | 46% | 0,93 | 50% |
| ARIMA (= gêmeo do GS) | −30,5% | −8,8% | 51,9% | 37,8% | −0,35 (0,75) | −0,17 | 266 | 48% | 0,85 | 46% |
| MM (Almeida) | +150,9% | 26,4% | 38,4% | 40,4% | 0,50 (0,16) | 0,69 | 24 | 38% | 1,99 | 44% |

### T3 — 2025 a 2026 (período recente)

| | Retorno | a.a. | Queda máx. | Volat. | Sharpe (p) | Calmar | Oper. | Acerto | FL | Exposição |
|---|---|---|---|---|---|---|---|---|---|---|
| ARIMA-GARCH (GS) | +14,7% | 8,4% | 20,1% | 20,7% | −0,16 (0,58) | 0,42 | 48 | 44% | 1,04 | 50% |
| ARIMA-GARCH (GC) | +18,9% | 10,7% | **12,1%** | 12,9% | −0,19 (0,60) | **0,89** | 48 | 44% | 1,05 | 32% |
| ARIMA (= gêmeos) | +23,2% | 13,0% | 20,3% | 22,7% | 0,06 (0,47) | 0,64 | 46 | 41% | 1,18 | 57% |
| MM (Almeida) | **+31,3%** | 17,3% | 28,2% | 22,6% | 0,23 (0,38) | 0,61 | 13 | 25% | 1,25 | 50% |

## Ano a ano (camada 3, %)

| Ano | PETR4 | Selic | ARIMA-GARCH (GS) | ARIMA-GARCH (GC) | ARIMA | MM |
|---|---|---|---|---|---|---|
| 2007 | +72,4 | +11,6 | +12,1 | +12,1 | +6,4 | +61,0 |
| **2008** | **−47,3** | +12,2 | **+4,8** | **+4,8** | −25,2 | −36,6 |
| 2009 | +61,1 | +9,8 | +6,2 | +6,2 | +35,8 | +22,3 |
| 2010 | −25,4 | +9,6 | +5,9 | +5,9 | −12,6 | −9,0 |
| 2011 | −21,3 | +11,6 | −11,3 | −11,3 | −6,4 | −22,2 |
| 2013 | −15,2 | +8,0 | +13,4 | +1,4 | −22,9 | −9,3 |
| 2014 | −40,1 | +10,7 | +25,6 | +4,3 | −13,4 | +0,3 |
| 2015 | −34,4 | +13,0 | +28,6 | +8,8 | +3,7 | −10,4 |
| 2016 | +123,3 | +14,0 | +132,1 | +16,4 | +0,4 | +208,1 |
| 2025 | −15,4 | +14,1 | −14,4 | −4,9 | −8,6 | −20,6 |
| 2026* | +57,5 | +10,1 | +34,0 | +25,0 | +34,7 | +65,3 |

\* até 18/09/2026. Gráficos: `tg/graficos/rodada3/anual_T*.pdf` e `curva_T*.pdf`.

## Camadas (retorno acumulado, %)

| | 1) puro | 2) + custos | 3) + Selic | 4) + proventos |
|---|---|---|---|---|
| T1 ARIMA-GARCH | −15,9 | −21,9 | +17,2 | +21,5 |
| T1 ARIMA | −19,6 | −32,5 | −11,4 | −6,1 |
| T1 MM | −31,6 | −32,8 | −11,6 | −5,9 |
| T2 ARIMA-GARCH (GS) | +269,7 | +243,4 | +325,3 | +368,0 |
| T2 ARIMA-GARCH (GC) | −6,8 | −9,5 | +34,0 | +34,0 |
| T2 ARIMA | −35,8 | −44,8 | −30,5 | −27,9 |
| T2 MM | +100,8 | +98,1 | +150,9 | +176,0 |
| T3 ARIMA-GARCH (GS) | +5,1 | +2,2 | +14,7 | +21,8 |
| T3 ARIMA-GARCH (GC) | +3,5 | +1,7 | +18,9 | +23,5 |
| T3 ARIMA | +14,5 | +11,6 | +23,2 | +33,5 |
| T3 MM | +18,1 | +17,2 | +31,3 | +39,0 |

Custos totais (% do capital inicial): T1 ARIMA-GARCH 7,3; ARIMA 16,4; MM 1,8
· T2 GS 14,0; ARIMA 11,5; MM 1,4 · T3 GS 2,6; ARIMA 2,6; MM 0,6.

## Comparações diretas (mesmos dias; teste de Memmel da diferença de Sharpe)

| Período | Comparação | Sharpe A × B | p | Leitura |
|---|---|---|---|---|
| T1 | ARIMA-GARCH × gêmeo | −0,63 × −0,16 | 0,14 | sem diferença significativa |
| T1 | ARIMA-GARCH × ARIMA | −0,63 × −0,32 | 0,44 | idem |
| T1 | ARIMA-GARCH × MM | −0,63 × −0,31 | 0,52 | idem |
| T2 | **ARIMA-GARCH (GS) × gêmeo/ARIMA** | **0,80 × −0,35** | **0,009** | **GARCH melhor, significativo** |
| T2 | ARIMA-GARCH (GC) × gêmeo | −0,46 × −0,16 | 0,52 | sem diferença |
| T2 | ARIMA-GARCH (GS) × MM | 0,80 × 0,50 | 0,42 | sem diferença |
| T2 | ARIMA × MM | −0,35 × 0,50 | 0,11 | sem diferença |
| T3 | todas as combinações | — | > 0,5 | sem diferença |

Arquivo completo: `testes/comparacao_modelos_R3.csv`, que traz também o t
pareado da diferença de retorno diário.

## O que TODAS as 344 configurações fizeram no teste

Serve para separar o efeito do GARCH da sorte de uma configuração. Medianas:

| | T1: queda máx. · retorno | T2: queda máx. · retorno | T3: queda máx. · retorno |
|---|---|---|---|
| ARIMA puro (8) | 49,9% · −17,4% | 51,4% · −13,8% | 22,5% · +16,0% |
| GARCH filtro (96) | 43,8% · +0,2% | 42,2% · +18,9% | 20,7% · +15,5% |
| GARCH targeting (16) | 33,4% · +12,4% | 21,0% · +19,1% | 18,7% · +16,3% |
| GARCH intervalo de confiança (32) | 46,4% · −6,6% | 45,7% · −0,3% | 22,5% · +19,3% |
| GARCH filtro+targeting (192) | **29,6% · +19,4%** | **19,0% · +33,6%** | **16,3% · +16,8%** |

**Efeito pareado** (GARCH − ARIMA com a mesma base), fração dos pares em que o
GARCH **reduziu a queda máxima**:

| Variante | T1 | T2 | T3 |
|---|---|---|---|
| targeting | 94% | 100% | 56% |
| filtro+targeting, zera, limiar fixo | 96% | 100% | 65% |
| filtro+targeting, zera, percentil | 100% | 100% | 90% |
| filtro (sem zerar), percentil | 42% | 29% | 29% |

O Sharpe melhorou em menos da metade dos pares na maioria das variantes.

**Correlação entre calibração e teste** (Spearman, 344 configurações):

| | T1 | T2 | T3 |
|---|---|---|---|
| Sharpe | 0,03 | −0,06 | −0,07 |
| Calmar | 0,41 | 0,28 | 0,34 |

## Réplica de Almeida (2016)

R$ 50.000, volume fixo, compra e venda, sem custo. Dados oficiais B3, preço
corrigido por desdobramento; o preço bruto só difere em 2007–2011.

| | Almeida (tabela do TG) | Réplica sem stop | Réplica stop 50 / alvo 100 |
|---|---|---|---|
| 2013–2016, 1.000 ações | +R$ 10.430 · 38 op. | +R$ 12.380 · 49 op. · FL 1,42 | +R$ 8.830 · 49 op. · FL 1,72 |
| 2007–2011, 100 ações | −R$ 2.542 · 52 op. | −R$ 1.274 · 63 op. · FL 0,83 | +R$ 450 · 63 op. · FL 1,23 |

A mesma ordem de grandeza, mas não o número exato (ver `notas/INCERTEZAS.md`).
Arquivos em `replica_almeida/`.

## Conclusões desta rodada

1. **Segurança em crise: sim.**
   - Nas duas crises, o ARIMA-GARCH teve queda máxima de 19–26% (escolhido por
     Sharpe) e de 7–19% (por Calmar), contra 43–52% do ARIMA, 38–58% da MM e
     67–83% da PETR4.
   - **Em 2008 ganhou 4,8% com a ação caindo 47,3%.**
   - O efeito aparece na **maioria das 344 configurações**, não só na
     escolhida, desde que a posição seja de fato reduzida (targeting ou zerar no
     veto). O filtro que só congela a posição não protege.
2. **Superar a Selic: raramente.**
   - Nas crises a Selic rendeu 54–68%, e só uma configuração passou dela com
     folga: GS em T2, Sharpe 0,80, p = 0,056, **no limite da significância**.
   - Nos outros casos o Sharpe ficou negativo. Proteção não é o mesmo que
     retorno acima da Selic.
3. **ARIMA-GARCH × ARIMA.**
   - Risco menor nos três períodos.
   - Retorno maior em T1 e T2, menor em T3.
   - Diferença de Sharpe estatisticamente significativa só em T2, com o GS
     (p = 0,009).
4. **ARIMA-GARCH × MM de Almeida.**
   - T1: GARCH melhor em retorno e risco.
   - T2: GS acima da MM em retorno; GC muito mais seguro.
   - T3: MM com mais retorno e mais risco.
   - Nenhuma diferença de Sharpe foi significativa.
   - A MM brilha nas retomadas fortes (2016: +208%) e sofre nas quedas.
5. **O que se consegue prever.** Escolher configuração pelo retorno não se
   sustenta de um período para outro (Spearman do Sharpe ≈ 0). Escolher pela
   segurança se sustenta em parte (Calmar 0,28–0,41). É coerente com a teoria:
   o GARCH prevê a volatilidade, que tem memória, e não a direção.
6. **O preço da proteção.** Nos anos de alta forte (2007, 2009, 2026), o
   ARIMA-GARCH ficou bem atrás da ação e da MM.
