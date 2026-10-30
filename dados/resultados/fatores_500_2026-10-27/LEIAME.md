# Estudo de fatores com GARCH 500 (27/10/2026)

Pedido do autor em 27/10/2026: com as janelas fixas do estudo de 26/10 (ARIMA
240, GARCH 500, `janelas_240_500_2026-10-26/`), testar mais possibilidades na
grade. Protocolo escrito antes: `PROTOCOLO.md`. **O TG não foi alterado.**
Detalhes e leitura: `notas/INCERTEZAS.md`, item 79.

Fatores (duas opções cada): `DistribuicaoGARCH` (normal × t de Student),
`SelecaoPorBIC` (AIC × BIC), `Barras_Entre_Reselecao` (21 × 63). Só compra.

## O que tem aqui

| Caminho | O quê |
|---|---|
| `calibracao/` | Uma linha por passagem: 1.232 em cada uma das 25 janelas |
| `escolhas/` | Saída do `escolher.sh` com `EXTRA_GARCH`/`EXTRA_ARIMA` |
| `testes/`, `relatorios_mt5/`, `traco/` | Testes individuais dos robôs escolhidos (MM copiadas da refação) |
| `cru/efeito_fatores_teste.txt` | Análise 1 do protocolo, grades dos períodos de teste |
| `cru/efeito_fatores_calibracao.txt` | O mesmo nas grades de calibração |
| `comparacao.txt` | Cada robô no TG, no estudo de 26/10 e aqui, lado a lado |
| `execucao_bateria.log` | 01h00 a 06h54 de 27/10 |

## Reprodução

```bash
bash ferramentas/scripts/fatores_500.sh dados/resultados/fatores_500_2026-10-27 calibrar testar
bash ferramentas/scripts/efeito_fatores.sh T > dados/resultados/fatores_500_2026-10-27/cru/efeito_fatores_teste.txt
bash ferramentas/scripts/efeito_fatores.sh C > dados/resultados/fatores_500_2026-10-27/cru/efeito_fatores_calibracao.txt
C=$PWD/dados/resultados/fatores_500_2026-10-27/testes bash ferramentas/scripts/comparar_janelas.sh > dados/resultados/fatores_500_2026-10-27/comparacao.txt
```

## Conferências

- 1.232 passagens nas 25 janelas; as 8 combinações dos fatores com 152 passagens
  cada (conferido na PETR4 C1).
- As passagens normal/AIC/21 têm retorno e queda idênticos aos do estudo de 26/10
  (só compra) nas 12 grades de teste e nas de calibração (fim dos dois `cru/`).
- `escolher.sh`, `janelas_240_500.sh` e `comparar_janelas.sh` ganharam opções;
  sem elas, reproduzem as saídas anteriores byte a byte.

## Resultado (análise 1, grades de teste das 4 ações)

| Fator (opção nova) | Queda menor | Igual | Queda maior |
|---|---|---|---|
| t de Student | 37,5% | 24,8% | 37,7% |
| BIC | 30,3% | 26,4% | 43,3% |
| Reseleção a cada 63 | 37,6% | 17,4% | 45,0% |

O t de Student estimou ν mediano de 7 a 11 (caudas pesadas de fato), mas quase
não mudou as decisões. O BIC piorou a queda e, na mediana, o retorno em 2007–2011
(de −12 a −23 p.p. na PETR4 e na VALE3). A reseleção mais espaçada não teve
efeito consistente.
