# Rodada 6 (30/09/2026) — teste fora da amostra em 2017–2024

> **SUPERADO em 06/10/2026** pela refação com o EA corrigido
> (`../refeito_2026-10-05/LEIAME.md`; erros em `notas/INCERTEZAS.md`, itens 43 a
> 47). Os números desta pasta foram produzidos com o EA antigo e não vão para o TG.


**O teste mais limpo do trabalho.** A configuração foi escolhida usando **apenas**
dados até 30/12/2016, e o período de teste começa em 02/01/2017. Não há
sobreposição entre escolher e testar.

## Protocolo (o mesmo das rodadas 3 e 4, declarado antes)

1. **Calibração** 02/01/2014 a 30/12/2016 — as mesmas 344 configurações das
   sub-grades da rodada 3.
2. **Critérios declarados antes:** maior **Sharpe** (`GS`) e maior **Calmar**
   (`GC`), na camada 3 (custo B3 de 0,03% por lado + caixa na Selic).
3. **Teste** 02/01/2017 a 30/12/2024, nunca usado para escolher nada.
4. **Gêmeos:** o mesmo ARIMA com `UsarGARCH=false`, para isolar o efeito do GARCH.
5. R$ 100 mil, 1:1, 95% do patrimônio, só compra, "somente preços de abertura".

Reprodução: `ferramentas/scripts/calib_2014_2016.sh` e `teste_2017_2024.sh`.

## Configurações escolhidas na calibração

| | Estratégia | Desempenho **na calibração** |
|---|---|---|
| `GS` | filtro, percentil 70, zera no veto, janela 240, com constante | +109,3% · Sharpe 0,75 · Calmar 1,20 · queda 23,7% |
| `GC` | filtro+targeting, percentil 50, não zera, janela 120, sem constante | +87,5% · Sharpe 0,69 · **Calmar 2,83** · queda 8,4% |
| ARIMA puro | janela 240, com constante (os dois critérios coincidiram) | +79,1% · Sharpe 0,43 · Calmar 0,59 · queda 36,9% |

São **diferentes** das escolhidas na rodada 3 — sintoma da não-persistência que o
trabalho documenta.

## Resultado no teste (2017–2024, camada 3)

Referências do período: **Selic +86,1%** · **buy-and-hold +143,6%**

| | retorno | CAGR | Sharpe (p) | queda máx. | oper. | acerto | vetos |
|---|---|---|---|---|---|---|---|
| **GS — ARIMA-GARCH** | **+276,1%** | **18,3%** | **0,49 (0,087)** | **26,9%** | 237 | 57,8% | 656/1983 |
| GS gêmeo (sem GARCH) | +106,5% | 9,7% | 0,21 (0,280) | 40,5% | 236 | 54,7% | — |
| GC — ARIMA-GARCH | +112,6% | 10,1% | 0,19 (0,300) | 38,5% | 216 | 56,0% | 997/1977 |
| GC gêmeo (sem GARCH) | **−43,8%** | −7,1% | −0,31 (0,807) | **76,5%** | 459 | 52,7% | — |
| ARIMA puro | +106,5% | 9,7% | 0,21 (0,280) | 40,5% | 236 | 54,7% | — |
| MM (Almeida) | +90,4% | 8,4% | 0,17 (0,319) | 36,7% | 56 | — | — |

## Leitura

1. **Nos dois pares, a versão com GARCH teve retorno maior E queda menor.**
   GS: +276,1% contra +106,5%, com 26,9% contra 40,5% de queda.
   GC: +112,6% contra −43,8%, com 38,5% contra 76,5%.
   É o efeito pareado, fora da amostra, nos dois critérios. Não depende de qual
   configuração foi escolhida.
2. **O GS superou a Selic e o buy-and-hold em retorno** (+276,1% contra +86,1% e
   +143,6%), com alfa de 7,6% ao ano. **Mas o Sharpe não é significativo**
   (p = 0,087) e a diferença de Sharpe contra o buy-and-hold também não
   (z = 0,55, p = 0,580). Reportar como "teve retorno superior", nunca como
   "superou de forma estatisticamente significativa".
3. **O critério Calmar não se transferiu.** O GC foi escolhido com Calmar 2,83 e
   queda de 8,4% na calibração, e entregou Calmar 0,26 e queda de 38,5% no teste.
   Isso qualifica o achado da rodada 3 (Calmar persiste "em parte"): persiste na
   ordenação, não no valor.
4. **O acerto direcional das operações executadas subiu** de 54,7% para 57,8% no
   par GS. Sugere que o filtro seleciona os períodos em que o sinal do ARIMA é
   mais confiável — mas com 237 operações o erro-padrão é de 3,2 p.p., então
   **a diferença não é significativa**. Registrar como indício.
5. **O gêmeo do GC foi significativamente pior que o buy-and-hold** (z = −2,51,
   p = 0,012), com alfa de −17,4% ao ano. É o pior resultado individual do
   trabalho, e mostra o que acontece com o ARIMA sem filtro numa janela longa:
   459 operações, −43,8% e 76,5% de queda.

## Ressalvas

- Um ativo, um período, uma calibração. Não generaliza sozinho.
- 344 configurações foram varridas na calibração, então resta sorte de seleção
  **na escolha da configuração** — mas **não** na comparação pareada, já que o
  gêmeo usa exatamente o mesmo ARIMA.
- Sharpe com p = 0,087 é indício, não prova.
