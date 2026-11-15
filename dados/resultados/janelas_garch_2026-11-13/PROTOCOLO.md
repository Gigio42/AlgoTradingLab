# Protocolo: janela do GARCH em 120, 240, 500 e 1000 (13/11/2026)

Escrito antes de rodar. Estudo à parte, **não entra no TG** sem pedido.

## Pergunta (do autor, 13/11/2026)

A dupla discutiu se a banca pode perguntar sobre a janela: uma janela de 500 tem
"duas de 240", o modelo treina com mais dado, e o resultado com 500 saiu pior
mesmo com os parâmetros do GARCH mais estáveis. Isso é overfitting? Uma janela
menor pode ser melhor para o modelo "não se acostumar"? E quanto do resultado é
a otimização?

Os estudos de 26/10 (500) e 02/11 (1000) não respondem isso de forma limpa: em
cada um a otimização escolheu configurações diferentes, e a diferença no
resultado mistura o efeito da janela com o da escolha. Aqui a comparação é feita
**com a mesma configuração**, mudando só a janela do GARCH.

## Montagem

- PETR4, D1, série oficial. `PETR4_DESDE1999` em C1 e T1 (a janela de 1000
  precisa de pregões anteriores a 2003), `PETR4_OFICIAL` no resto. Depois de 2003
  os dois símbolos são idênticos (conferido em 02/11).
- ARIMA fixo em 240 pregões (`Janela_Estimacao=240`), seleção de ordens em 240,
  reseleção a cada 21. **Só a janela do GARCH muda**: `Janela_GARCH` = 120, 240,
  500 e 1000 resíduos (calculados com os coeficientes do ARIMA do dia).
- Grade: as seis sub-grades r3 só-compra do estudo de 1000 (156 configurações; a
  sub-grade `arima`, sem GARCH, tem 4 e não depende da janela do GARCH).
- Aquecimento de quatro anos em todos os períodos e janelas (o testador começa
  quatro anos antes e o EA só opera e mede a partir de `Inicio_Operacao`).
- Períodos, todos com a grade inteira:

| nome | operação | papel |
|---|---|---|
| C4 | 02/01/2014 a 30/12/2016 | otimização do teste principal |
| R6 | 02/01/2017 a 30/12/2024 | teste principal |
| C2 | 04/01/2010 a 29/12/2012 | otimização |
| T2 | 02/01/2013 a 30/12/2016 | teste |
| C3 | 03/01/2022 a 31/12/2024 | otimização |
| T3 | 02/01/2025 a 19/09/2026 | teste |
| C1 | 02/01/2004 a 29/12/2006 | otimização |
| T1 | 02/01/2007 a 30/12/2011 | teste |

  Ordem de execução: C4 e R6 nas quatro janelas primeiro (o par principal);
  depois C2/T2, C3/T3, C1/T1.
- Traço por barra de **uma configuração fixa** nas quatro janelas, de 2017 a
  2024: a do ARIMA-GARCH Sharpe do TG nesse período (`refeito_2026-10-05/escolhas/r6_C4.txt`,
  GS: filtro, percentil 70, zera no veto, constante, ARIMA 240), que também foi a
  escolhida no estudo de 500. Mais um quinto traço com `Janela_GARCH=0` (o TG).

## O que se mede (camada 1, crua, como o Cap. III)

1. **Funcionamento com a mesma configuração**: para cada período de teste,
   distribuição de queda máxima (`dd_puro`), volatilidade (`vol_puro`), retorno
   (`ret_puro`), exposição e fração de sinais vetados (`vetos/sinais`) das 152
   configurações com GARCH, por janela. Pares: mesma configuração com 120, 500 e
   1000 contra 240.
2. **Otimização**: em cada par otimização → teste, por janela, a escolha pelo
   critério do protocolo (`escolher.sh so_compra`, GS e GC), a posição da escolhida
   no teste entre as 152 com GARCH, e a correlação de Spearman entre a ordem na
   otimização e no teste (Sharpe e Calmar da escolha, que são os do critério).
3. **Estimação** (traço): persistência α+β do GARCH dia a dia, fração dos dias com
   persistência > 0,999, volatilidade prevista, limiar, vetos e exposição.
4. **Simulação em MQL5** (`ferramentas/JanelaGarchSimulada.mq5`, semente fixa): o
   mesmo `CGarch` do EA estimado em séries GARCH(1,1) artificiais com verdade
   conhecida, em amostras de 120, 240, 500 e 1000, muitas repetições: erro dos
   parâmetros por tamanho de janela. E uma série com mudança de regime (a
   variância de longo prazo muda no meio), para ver quanto tempo cada janela leva
   para acompanhar a mudança.

## Conferências previstas

- 156 passagens em cada uma das 32 otimizações.
- Sub-grade `arima` idêntica nas quatro janelas (só o GARCH muda).
- `Janela_GARCH=1000` em C1 a C4 idêntica à calibração de `janela_garch_1000_2026-11-02/`
  (mesmo aquecimento e símbolos).
- `Janela_GARCH=500` em C2, C3 e C4 contra `janelas_240_500_2026-10-26/` (aquecimento
  de dois anos lá): espera-se igual; se não for, registrar.
- `Janela_GARCH=240` contra o TG (`Janela_GARCH=0`, ARIMA 240) não precisa ser
  igual: com 0 o GARCH usa os resíduos do próprio ajuste do ARIMA, sem as
  primeiras observações de aquecimento; com 240 usa os 240 últimos resíduos
  recalculados. A diferença é registrada.
- O traço com `Janela_GARCH=0` reproduz o retorno do GS de 2017–2024 do TG.

## O que NÃO se conclui daqui

Um ativo, quatro pares de períodos. Nenhum teste estatístico formal entre as
janelas. Sem escolher "a melhor janela" pelo resultado do teste (isso seria
otimizar no teste).
