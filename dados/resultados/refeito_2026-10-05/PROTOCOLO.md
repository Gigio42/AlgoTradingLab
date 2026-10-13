# Refação de todos os experimentos — protocolo (escrito em 05/10/2026, ANTES dos resultados)

## Por que refazer

Em 05/10/2026 a auditoria do código achou dois erros que mudam decisões de operar
quando o teste ADF escolhe d = 0 (ver `notas/INCERTEZAS.md`, itens 43 e 44):

1. o EA usava `PreverDiferenciado()` como previsão de retorno também com d = 0,
   quando isso é o nível do log-preço (sinal de compra quase sempre);
2. com d = 0 e `IncluirConstante=false`, o modelo de nível ficava sem média
   (viés para baixo).

E três correções menores no caminho do ADF: escolha das defasagens por AIC
sobre amostra comum, ADF que falha devolve d indeterminado (seleção adiada) em
vez de d = 0 silencioso, e o (0,d,0) só é pulado sem constante quando d ≠ 0.

Todo resultado do ARIMA e do ARIMA-GARCH anterior a 05/10/2026 foi produzido
com o código antigo. A estratégia de médias móveis não mudou.

## O que NÃO muda

O protocolo é o da rodada 3 (`../rodada3_b3_oficial/PROTOCOLO.md`) e o da rodada 4
(`../rodada4_multiativos/LEIAME.md`), sem nenhuma alteração de janela, grade,
critério ou desempate:

| Teste | Calibração |
|---|---|
| T1 02/01/2007 – 30/12/2011 | C1 02/01/2004 – 29/12/2006 |
| T2 02/01/2013 – 30/12/2016 | C2 04/01/2010 – 28/12/2012 |
| T3 02/01/2025 – 18/09/2026 | C3 03/01/2022 – 30/12/2024 |
| 2017–2024 (rodada 6) | C4 02/01/2014 – 30/12/2016 |

- Grade: as mesmas sub-grades (`grades/`), 344 configurações só-compra
  (rodada 3) e 688 com venda a descoberto (rodada 4).
- Escolha **só na calibração**, camada 3: maior Sharpe (GS) e maior Calmar (GC)
  na família ARIMA-GARCH; idem no ARIMA puro (AS, AC). Desempate: menos
  operações (`negocios`). Se ainda empatar, a primeira em ordem alfabética da
  linha de parâmetros (regra acrescentada agora só para ser determinística;
  passagens empatadas em Sharpe e operações são, na prática, a mesma
  configuração com um parâmetro irrelevante diferente).
- A rodada 3 é o subconjunto PETR4 com `SomenteCompra=1` da bateria da rodada 4,
  que roda as 688 configurações nas 6 janelas. Antes, as duas tinham rodado em
  separado com o mesmo EA; agora roda uma vez só.
- A escolha passa a ser feita por `ferramentas/scripts/escolher.sh` (awk), não
  mais por Python fora do repositório.

## Regras declaradas agora para o que antes estava fixo à mão

- **Períodos longos (rodada 5).** O texto diz que as duas configurações fixas
  foram escolhidas na calibração de 2010 a 2012. Na rodada 5 original isso valia
  só para uma delas (a outra era a escolha de 2004–2006). Agora: **as duas
  configurações fixas são a GS e a GC escolhidas em C2 (2010–2012)**, cada uma
  com a sua gêmea sem GARCH, mais a MM. Se GS e GC coincidirem, fica uma só.
- **Teste de 2017–2024 (rodada 6).** GS, GC e gêmeas da calibração C4; ARIMA
  puro = AS de C4.
- **Cenário de Almeida.** Mantém as configurações fixas do
  `cenario_almeida.sh` (a de 2013–2016 é a configuração padrão do EA: filtro,
  percentil 50, janela 120, sem constante), sem depender da nova escolha.
- **Traço de demonstração.** Usa a nova GS da rodada 6, como antes.

## Verificações previstas

1. A estratégia de médias móveis rodada de novo tem de sair **idêntica** à
   anterior (o código dela não mudou). Diferença ali indica problema de ambiente.
2. As análises em awk são conferidas primeiro contra os arquivos ANTIGOS: têm de
   reproduzir os números das análises em Python (`escolhidas.json`,
   `analise4_saida.txt`) antes de serem aplicadas aos novos.
