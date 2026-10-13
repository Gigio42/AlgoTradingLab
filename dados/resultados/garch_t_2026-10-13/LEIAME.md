# GARCH com erros t de Student (13/10/2026)

Protocolo, escrito antes dos resultados: `PROTOCOLO.md`. Tabela completa:
`resumo.txt`, gerada por `ferramentas/scripts/resumo_garch_t.sh`. Bateria:
`ferramentas/scripts/garch_t.sh` (18h20 → 18h25).

**Não está no TG.** O modelo do TG continua sendo o GARCH normal. Isto é um
teste de sensibilidade pedido pelo autor depois de ler Thomaz (2019).

## Conferências

- **Validação sintética** (`dados/verificacao/validacao_garch_t_2026-10-13.txt`,
  `ferramentas/ValidarGarchT_EA.mq5`):
  - série com erros t de ν = 5: o ajuste t estimou ν = 4,55, com log-verossimilhança
    94 pontos acima da normal;
  - série com erros normais: ν = 173, com α e β iguais aos da normal;
  - 100 réplicas com resíduos de 236 barras (janela 240): ν mediano 5,71, quartis
    4,47 a 7,39, AIC menor com a t em 93;
  - com 116 barras (janela 120): ν mediano 6,82, quartis 4,78 a 11,04, 9 no teto,
    AIC menor com a t em 66. Na janela curta a estimativa de ν é ruidosa.
- **Regressão**: com `DistribuicaoGARCH=0`, a curva de `R6_GS` saiu idêntica byte
  a byte à da refação (`REG_R6_GS`). O caminho normal não mudou.
- **Apêndice A**: a listagem reduzida do EA continua idêntica (as linhas novas
  estão marcadas com `//@omitir`).

## Resultado (12 configurações: as 11 do TG e o cenário de Almeida 2013–2016)

Comparando, em cada configuração, a t com a normal:

- **Retorno:** menor com a t em 9 de 12. Maior só em 2007–2011 e nas duas de
  2013–2016. Em 2017–2024, a escolha por Sharpe foi de 273,8% para 199,6%.
- **Queda máxima:** maior com a t em 9 de 12, menor em 2, igual em 1. As
  diferenças são de 0,4 a 3,6 pontos.
- **Sharpe:** menor com a t em 9 de 12.
- **Testes pareados t × normal:** nenhum significativo (p do Sharpe de 0,124 a
  0,641; t pareado de 0,199 a 0,704).

**Proteção contra a gêmea sem GARCH: mantida.** Com a t, a queda máxima ficou
menor que a da gêmea nas 12 configurações, e o retorno, maior em 10 (as duas
exceções são as de 2025–2026, as mesmas da normal).

**Significância contra a gêmea:** com a normal, 1 melhor (2017–2024, escolha por
Calmar, p = 0,020) e nenhuma pior. Com a t, nenhuma melhor (aquela passou a
p = 0,169) e uma pior pelo Sharpe (2025–2026, escolha por Sharpe, p = 0,048; pelo
t pareado, p = 0,177).

**Mecanismo:** a t vetou menos em 7 das 8 configurações distintas (em 2013–2016,
só 2 vetos a menos; em 2025–2026 vetou mais; em 2017–2024,
escolha por Sharpe: 657 → 548 vetos em 1.983 sinais) e deixou o robô mais tempo
comprado em 5 de 8. É o efeito "mais permissivo": dias extremos pesam menos na
estimação e o veto dispara menos.

**Caudas da PETR4:** ν médio por barra de 4,6 a 10,5 nas janelas de 2017 a 2026,
caudas grossas como em Thomaz (2019). Nas janelas de 2007 a 2016 a média sobe
(20 a 70), puxada por estimativas altas (perto da normal) em parte das barras.
A média com teto de 200 é um resumo grosseiro; a mediana não foi gravada.

## Limite desta conclusão

As configurações foram escolhidas na calibração com a normal e não foram
reescolhidas com a t. Isto mede o efeito de trocar só a distribuição. Uma
calibração com a t poderia escolher outras configurações. Isso não foi testado.
