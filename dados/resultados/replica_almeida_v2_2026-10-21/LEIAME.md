# Réplica de Almeida (2016), rodada 2 — resultados (21/10/2026)

Protocolo em `PROTOCOLO.md`. Robô: `ferramentas/ReplicaAlmeidaEA.mq5` (porta do
OnTick do anexo dele). Séries: `ferramentas/scripts/series_replica_almeida.sh`.
Execução: `replica_almeida_v2.sh` (parte a) e `replica_almeida_v2b.sh` (parte b,
`SO=<trecho do símbolo>` roda só uma parte). Resumos: `resumo.txt` (um relatório
por linha) e `meses.txt` (por mês do ano, como a Figura 13 dele e os gráficos
mensais de CIEL3 e VLID3). Relatórios do testador em `relatorios/`.

Rótulo `ra_<teste><série>_m<modelo>_e<entrada>_r<reversão>`: modelo 2 = preços
de abertura, 0 = todos os ticks; entrada 0 = por estado (anexo dele), 1 = por
cruzamento (o `MediasMoveis2` do TG); reversão 0 = uma ordem com volume somado,
1 = fecha e abre.

## 1. O que não muda nada

- **Modelo de ticks**: "todos os ticks" = "preços de abertura" em todos os 28
  pares. Símbolo personalizado só com barras D1 não tem tick dentro da barra.
- **Forma de inverter a posição** (r0 × r1): idêntico em todos os pares.
- **Entrada por estado × por cruzamento**: muda uma operação por teste (a
  primeira) e quase nada no dinheiro. A do anexo é por estado.

## 2. O achado principal: o testador adia o início até ter 100 barras

Quando o símbolo não tem histórico suficiente antes da data inicial, o testador
do MT5 **muda a data de início sozinho**, sem erro, e só avisa no log
(`inicio_adiado_testador.log`):

    PETR4_DESDE2008: start time changed to 2008.05.31 00:00 to provide data at beginning

Com histórico começando em 02/01/2008, o teste "2007–2011" e o "2008–2010"
começam de fato em **02/06/2008**. Se o servidor de Almeida (MetaBrazil-Demo)
tinha a PETR4 a partir de 2008, os dois testes de crise dele não incluíram 2007
nem o primeiro semestre de 2008. **Não confirmado** (não há como ver o servidor
dele), mas é o que melhor explica a contagem de operações:

| Série (PETR4) | Início real | T1 (alvo 52) | T2 (alvo 37) | Entradas por mês × Figura 13 (soma das diferenças) |
|---|---|---|---|---|
| OFICIAL (desde 2003) | 02/01/2007 | 64 | 39 | 14 |
| SET2007 (desde 04/09/2007) | 08/02/2008 | **52** | **37** | 6 |
| DESDE2008 | 02/06/2008 | 50 | 35 | **2** |
| PROVB3 (desde 2008, com proventos B3) | 02/06/2008 | 56 | **37** | 6 |

(Entrada por estado, preços de abertura. A leitura da Figura 13 é visual,
**estimativa**: 3, 4, 4, 3, 1, 5, 4, 4, 8, 4, 7, 5.)

Com o histórico desde 2008, as entradas de julho a dezembro batem mês a mês com
a Figura 13 (4, 4, 8, 4, 7, 5) em todas as séries que começam em 2008.

## 3. O dinheiro: o nível de preço dele era mais baixo

Na série da B3 sem proventos, o lucro bruto sai muito acima do dele (T1: 5.277
contra 3.363). Ajustando a série pelos **proventos oficiais da B3** (dividendos,
JCP e rendimentos até 06/2016, que seria o ajuste de uma corretora em 2016), o
nível dos preços de 2008–2011 cai e o dinheiro se aproxima:

| Teste | Almeida: oper. · lucro bruto · perda bruta · líquido | Nosso (série B3 com proventos, entrada por estado) |
|---|---|---|
| T1 PETR4 2007–2011 | 52 · 3.363 · −5.905 · −2.542 | 56 · 3.546 · −5.683 · −2.137 |
| T2 PETR4 2008–2010 | 37 · 2.855 · −4.450 · −1.595 | **37** · 2.902 · −4.264 · −1.362 |
| T3 PETR4 2013–2016 | 38 · — · — · +10.430 | **38** · 34.880 · −23.340 · +11.540 |
| T4 CIEL3 2012–2016 | 51 (21 com lucro) · 45.590 · −31.940 · +13.650 | **51 (21)** · 45.260 · −27.820 · +17.440 |
| T5 VLID3 2012–2016 | 49 (25) · 63.760 · −38.250 · +25.510 | 51 (24) · 63.480 · −34.650 · +28.830 |

O lucro bruto fica a menos de 6% do dele nos quatro testes em que ele o informa
(−0,4% a +5,4%). A perda bruta dele é sempre maior que a nossa: 4% (T1, T2), 10% (VLID3) e 15% (CIEL3).

Antes (rodada 1, série sem proventos e histórico desde 2003): T1 63 operações e
lucro bruto 6.609; T2 38 e 4.610.

**O que não fecha:**

- T1 tem 4 operações a mais, todas num zigue-zague de 03 a 08/06/2011 (quatro
  inversões em quatro pregões, com as médias quase iguais). Sem elas seriam 52,
  e junho teria 5 entradas, como na Figura 13. É o ponto mais sensível a
  diferenças mínimas de dado.
- Nos gráficos mensais de CIEL3 e VLID3, a série **sem** proventos fica mais
  perto dos gráficos dele que a série com proventos (`meses.txt`: CIEL3 1.531
  contra 3.286; VLID3 1.785 contra 2.207, soma das diferenças em R$ na escala de
  100 ações). Ou seja, os totais melhoram com proventos e o desenho por mês
  piora. O ajuste por proventos **não está confirmado** para essas duas.
- Na PETR4, o desenho mensal melhora com proventos (1.323 contra 2.164 da série
  sem proventos desde 2008), mas a contagem piora (56 contra 50).
- A perda maior dele não se explica por custo fixo: um custo por ação em cada
  operação (testado de R$ 0,01 a R$ 0,10) ou uma taxa diária sobre a posição
  vendida aproximam T1, T2, T4 e T5, mas derrubam T3 para +7.740 a +9.640
  (simulador offline).

## 4. Variantes testadas só no simulador offline (descartável, fora do repo)

O simulador reproduz os relatórios do testador centavo a centavo (mesmas
operações, datas e lucros). A exceção são os testes com início adiado e entrada
por estado: lá a primeira operação difere em R$ 62 a R$ 80, porque o simulador
começa um pregão antes do testador. Por isso, os números das seções 2 e 3 são
todos do testador.

- Histórico começando em qualquer data entre 17/08 e 01/10/2007 dá 52 e 37 na
  série da B3 sem proventos. Com o Yahoo, entre 01/11/2007 e 17/12/2007. **Com
  uma data livre para ajustar, acertar 52 e 37 é fácil**, por isso a contagem
  sozinha não prova a hipótese. O que a sustenta é o adiamento do testador e as
  entradas de julho a dezembro.
- Série do Yahoo ajustada (não oficial, com 51 pregões faltando): 52, 37 e 38 nos
  três testes de PETR4, com T2 −1.560 contra −1.595. Mas a mesma coincidência
  aparece no fechamento do Yahoo sem ajuste, e não aparece com os fatores do
  Yahoo aplicados aos preços da B3. A coincidência vem das falhas do Yahoo, não
  do ajuste.
- Tirar só o provento de 12/05/2011 do ajuste dá 52 e 37. Mas ele existe na B3
  (JCP de R$ 0,20, data-com 11/05/2011), então não há razão para tirá-lo.
- Deixar de ajustar uma bonificação da CIEL3 (2013 ou 2015) aproxima a perda
  bruta, mas a contagem vai para 53. Os fatores das bonificações são estimativas.
- Médias de outros períodos e exponenciais (rodada 1 desta exploração): nenhum
  par natural chega perto. Os ajustes que chegam são sobreajuste.

## 5. Conclusão

A lógica do anexo (entrada por estado), um histórico da PETR4 começando no início
de 2008 no servidor dele (com o testador adiando o início para junho de 2008) e
preços ajustados por proventos explicam a maior parte da distância entre os
nossos números e os dele. Explicam a contagem exata em T2, T3 e CIEL3 e o lucro
bruto a menos de 6% em todos. Não explicam a perda bruta maior dele nem as 4
operações de junho de 2011. Tudo isso é **reconstrução por hipótese**, não
confirmação: o servidor MetaBrazil-Demo e o histórico que ele baixou em 2016 não
existem mais.

**Consequência para o TG** (decisão do autor): se a hipótese do histórico
estiver certa, o teste "2007–2011" de Almeida cobre, na prática, de junho de 2008
a 2011.

## 6. Os módulos que o anexo não traz (conferidos no código do livro)

O anexo inclui seis arquivos do livro de Young (2013) sem reproduzi-los. O
código-fonte oficial do livro foi obtido (`dados/FONTES.md`, item 13) e o anexo é
o EA de exemplo "Moving Average Cross" do livro, com os nomes traduzidos e alguns
inputs transformados em variáveis fixas. O que isso confirma:

- **Volume**: `MoneyManagement()` só calcula volume por risco com `StopLoss > 0`.
  Com `StopLoss = 0` devolve o volume fixo, e o `VerifyVolume()` eleva o 0,1 do
  anexo ao mínimo do símbolo. Explica a frase dele sobre o "número mínimo" de 100.
- **Inversão**: o `Buy`/`Sell` do livro soma o volume da posição oposta numa só
  ordem (o `ModoReversao=0` daqui; r0 e r1 dão o mesmo resultado).
- **Barra nova**: o `CNewBar` não sinaliza na primeira chamada (`PularPrimeiraBarra`).
- **Médias**: `CiMA` sobre `iMA`, lida na barra 1. **Mas o `CIndicator::Main`
  arredonda o valor para `_Digits` (2 casas) antes de devolver.** Não estava na
  réplica. Acrescentado como `ArredondarMedias` e rodado (`_n1`, `replica_almeida_v2c.sh`):

| Teste | Almeida | PROVB3 sem arredondar | PROVB3 arredondando |
|---|---|---|---|
| T1 | 52 · 3.363 · −5.905 · −2.542 | 56 · 3.546 · −5.683 · −2.137 | 54 · 3.541 · −5.584 · −2.043 |
| T2 | 37 · 2.855 · −4.450 · −1.595 | 37 · 2.902 · −4.264 · −1.362 | 37 · 2.995 · −4.197 · −1.202 |
| T3 | 38 · +10.430 | 38 · +11.540 | 38 · +11.100 |
| T4 CIEL3 | 51 (21) · 45.590 · −31.940 | 51 (21) · 45.260 · −27.820 | 51 (21) · 43.390 · −27.890 |
| T5 VLID3 | 49 (25) · 63.760 · −38.250 | 51 (24) · 63.480 · −34.650 | 51 (24) · 63.350 · −34.480 |

  O arredondamento aproxima T1 (54) e T3, e afasta T2 e o lucro bruto da CIEL3.
  Como é o que o código dele fazia, a réplica fiel é a com arredondamento.
- **Desligados no anexo** (não influem): trailing stop, break even, timer; a
  `CBars` só lê preços.
- **Preço de execução**: o livro compra no ask e vende no bid. Com spread no
  servidor dele, cada operação custaria o spread; os símbolos daqui têm spread
  zero. É candidato à perda bruta maior dele, mas um custo uniforme por ação já
  foi testado (seção 3) e não fecha T3. **Não confirmado.**
