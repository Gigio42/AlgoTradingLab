# Protocolo do estudo de fatores (27/10/2026), escrito antes dos resultados

Pedido do autor em 27/10/2026: com a janela do GARCH fixa em 500, testar mais
possibilidades na grade (t de Student, BIC e reseleção). Os modelos assimétricos
(GJR) ficam para depois da faxina do código. **O TG não é alterado.**

## O que fica fixo (igual ao estudo de 26/10, `janelas_240_500_2026-10-26/`)

- ARIMA com janela de 240 pregões e GARCH sobre os 500 resíduos mais recentes,
  com o aquecimento de dois anos (`Inicio_Operacao`).
- **Só compra** em todas as ações. A venda a descoberto já foi respondida no
  estudo de 26/10: aumentou a queda máxima nos 12 casos.
- As ações (PETR4, VALE3, USIM5, POMO4), as janelas de calibração e de teste, a
  C4 da PETR4, o capital, o custo e a forma de execução.
- O critério de escolha: `escolher.sh` (maior Sharpe e maior Calmar na
  calibração), sem mudança.

## Os três fatores novos (duas opções cada)

| Input | Opções |
|---|---|
| `DistribuicaoGARCH` | normal (0) × t de Student (1) |
| `SelecaoPorBIC` | AIC × BIC |
| `Barras_Entre_Reselecao` | 21 × 63 pregões |

Por janela: 16 passagens sem GARCH (4 × BIC × reseleção) e 1.216 com GARCH
(152 × 8). Total de 1.232 por janela, 25 janelas, 30.800 passagens.

Piloto (27/10, 01h): a mesma sub-grade de 48 passagens levou 29 s com a normal e
68 s com o t de Student. **Estimativa** da bateria: cerca de 11 horas.

## Análises declaradas antes

1. **Efeito pareado de cada fator** (a resposta principal). Para cada fator, os
   pares de passagens que diferem só nele, nas grades dos períodos de teste
   (T1, T2, T3) das 4 ações: mediana da diferença na queda máxima, na
   volatilidade e no retorno, e a fração dos pares com queda menor. Separado
   pelos dois grupos do TG (reduz a posição × só filtra). Como conferência, o
   mesmo nas grades de calibração.
2. **Escolha e teste fora da amostra**, como no Cap. III: os robôs escolhidos e
   o resultado deles nos períodos de teste, ao lado do estudo de 26/10.
3. **Quantas vezes cada opção foi escolhida** (t × normal, BIC × AIC, 21 × 63).

Nenhum resultado é descartado. Uma grade com oito vezes mais candidatas aumenta a
chance de a vencedora da calibração ser sorte, e isso tem de ser dito junto com a
análise 2. A análise 1 não depende de escolha.

## Conferências

- Contagem de passagens: 16, 192, 192, 64, 384 e 384 por sub-grade.
- As passagens com normal, AIC e reseleção 21 são as mesmas configurações do
  estudo de 26/10 restritas a só compra: retorno e queda têm de ser idênticos.
- Os inputs novos gravados nas métricas (`DistribuicaoGARCH`, `SelecaoPorBIC`,
  `Barras_Entre_Reselecao`, `nu_medio`) conferidos numa amostra.
- `escolher.sh` e `janelas_240_500.sh` alterados com opção: sem as variáveis de
  ambiente, reproduzem as escolhas e as grades de 26/10 byte a byte (conferido
  em 27/10 antes de rodar).

## Reprodução

```bash
bash ferramentas/scripts/fatores_500.sh dados/resultados/fatores_500_2026-10-27 calibrar testar
```
