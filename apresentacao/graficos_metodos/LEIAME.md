# Gráficos que explicam os métodos

Catorze figuras feitas para a apresentação (pedido do autor, 30/10/2026). **Não
estão no TG.** Cada uma tem `.png` (300 dpi, para o slide) e `.pdf` (vetorial).
São duas partes:

- **Parte 1, figuras 01 a 07: os métodos, um por figura.** Mostram a matemática
  por trás de cada peça (ADF, MQO, Hannan-Rissanen, AIC, verossimilhança,
  otimização, Ljung-Box).
- **Parte 2, figuras 08 a 14: o robô funcionando.** Mostram o ARIMA-GARCH
  decidindo pregão a pregão, com os números que ele de fato registrou.

Para refazer: `ferramentas/scripts/metodos_ilustrados.sh` (dados da parte 1, roda
o MetaTrader), `ferramentas/scripts/robo_em_acao.sh` (dados da parte 2, só lê
arquivos) e `make` nesta pasta (precisa de LuaLaTeX; `make clean` apaga o que
sobra da compilação).

# Parte 1: os métodos

Todas usam a mesma janela: **500 pregões da PETR4, de 17/09/2024 a 18/09/2026**
(`PETR4_OFICIAL`). É a janela da validação numérica, então todo número aqui foi
conferido contra ela. Os dados saem do próprio código do robô; procedência e
conferência em `dados/resultados/metodos_ilustrados_2026-10-30/LEIAME.md`.

**O modelo ilustrado é o ARIMA(1,1,1) com GARCH(1,1)**, o da validação, porque
um coeficiente de cada tipo é mais fácil de mostrar. Nesta janela o AIC escolheria
outro, o ARIMA(4,1,0) (figura 7). Se a banca perguntar, a resposta é essa.

Ordem sugerida para os slides, que é a ordem em que o robô faz as coisas a cada
pregão: 6 (ADF) → 1 (MQO) → 2 (Hannan-Rissanen) → 7 (AIC) → 3 (verossimilhança)
→ 4 (otimização) → 5 (Ljung-Box).

---

## 6. ADF: por que o robô trabalha com o retorno, e não com o preço (`06_adf`)

**O que mostra.** Em cima, o log-preço (anda sem rumo) e o log-retorno (oscila
em volta de zero). Embaixo, para cada série, a variação de hoje contra o valor de
ontem.

**Como ler.** A inclinação da reta de baixo diz se a série é "puxada de volta".
No log-preço ela é praticamente zero (−0,002): o preço de ontem não diz nada
sobre para onde ele vai, ele só passeia. No log-retorno ela é −0,927, perto de
−1: seja qual for o retorno de ontem, o de hoje volta para perto da média.

**O número do teste.** O ADF do log-preço deu −0,95, acima do valor crítico de
−2,87: não se rejeita a raiz unitária, então é preciso diferenciar. O do
log-retorno deu −6,14, bem abaixo: é estacionário. Por isso d = 1.

**Cuidado.** A reta do gráfico é a regressão de Dickey-Fuller simples, sem
defasagens, para dar para ver. O teste do robô inclui defasagens (11 e 10
aqui). A ideia é a mesma, o número não.

## 1. MQO: o que é "ajustar" um coeficiente (`01_mqo`)

**O que mostra.** À esquerda, cada ponto é um dia: o retorno de ontem no eixo
horizontal, o de hoje no vertical. A reta é o AR(1) estimado e os tracinhos são
os resíduos. À direita, a soma dos quadrados dos resíduos para cada valor
possível de φ.

**Como ler.** MQO escolhe a reta que deixa a soma dos tracinhos ao quadrado a
menor possível. A curva da direita é uma parábola com um único mínimo, e o MQO
vai direto a ele por uma conta fechada. Não há taxa de aprendizado nem
iterações, que era o problema do gradiente descendente da versão antiga.

**Os números.** φ = 0,0729, constante de 0,0550% ao dia, 498 dias. A reta é
quase horizontal: o retorno de ontem quase não prevê o de hoje.

## 2. Hannan-Rissanen: como estimar um termo que não se observa (`02_hannan_rissanen`)

**O problema.** O termo MA do ARIMA usa o erro de ontem, e o erro não está nos
dados. Sem ele não dá para fazer MQO.

**Estágio 1 (barras).** Ajusta-se um AR longo, com 38 defasagens, por MQO. Os
coeficientes são pequenos e espalhados. O AR longo não é o modelo final, serve só
para prever cada dia.

**Os erros (gráfico do meio).** A diferença entre o retorno real e a previsão do
AR longo é a estimativa do erro, ε̂. O gráfico mostra os últimos 60 pregões,
desde 26/06/2026.

**Estágio 2 (fluxo embaixo).** Com ε̂ em mãos, ele vira uma coluna como outra
qualquer, e um segundo MQO estima φ = 0,1399 e θ = −0,0768. São os mesmos números
do `CArima`.

**Cuidado.** Hannan-Rissanen não é máxima verossimilhança. Por isso um modelo
maior pode sair com verossimilhança menor que um menor (`ia/INCERTEZAS.md`,
item 82).

## 7. AIC: como o robô escolhe p e q (`07_aic`)

**O que mostra.** À esquerda, os 25 modelos (p e q de 0 a 4), pintados pela
distância ao melhor AIC. O quadrado em vermelho é o escolhido, (4,0), com AIC de
−2680,3. À direita, a log-verossimilhança de cada modelo contra o número de
parâmetros.

**Como ler.** Mais parâmetros sempre ajudam a "explicar" a amostra, mas o AIC
cobra 2 por parâmetro. A linha inclinada da direita junta os pontos de mesmo AIC
que o melhor: quem fica abaixo dela pagou mais em parâmetro do que ganhou em
ajuste. O maior modelo, (4,4), tem 10 parâmetros e fica 5,2 pontos atrás do (4,0).

**Cuidado.** A faixa marca os modelos a menos de 2 pontos do melhor. Aqui são
oito contando o escolhido, e diferença menor que 2 costuma ser tratada como empate. O (1,1), usado
nas outras figuras, fica 2,7 pontos atrás.

## 3. Verossimilhança: por que o GARCH "explica melhor" os dias de choque (`03_verossimilhanca`)

**A ideia.** A verossimilhança mede quão plausíveis os dados observados são sob
certos parâmetros. Cada dia contribui com a altura do sino (a densidade normal)
no ponto onde o resíduo caiu. Soma-se o log disso em todos os dias.

**O que mostra.** O dia de maior resíduo da janela, 10/04/2025, com −6,71%. Com
volatilidade fixa (1,60%, a da amostra) o sino é estreito e o resíduo cai na
cauda: log da densidade de −10,16. O GARCH, que já via o mercado agitado, previa
2,46% para aquele dia. O sino fica mais largo e o mesmo resíduo dá −5,53. Embaixo,
os resíduos de todos os dias com a faixa de ±2σ do GARCH, que abre e fecha
acompanhando os períodos agitados.

**Como dizer.** O GARCH não acerta a direção do choque. Ele só reconhece que
naquele período choques grandes são mais prováveis.

## 4. Otimização: como o computador encontra α e β (`04_otimizacao`)

**O que mostra.** À esquerda, um "mapa de relevo" da log-verossimilhança para
cada par (α, β), com ω fixo no valor estimado. Quanto mais claro, melhor. O
triângulo branco é a região proibida (α + β ≥ 1, onde a volatilidade explodiria).
O caminho branco é o que o otimizador da ALGLIB (MinBLEIC) percorreu: começa no
quadrado (α = 0,10, β = 0,85) e termina na estrela (α = 0,126, β = 0,588). À
direita, a log-verossimilhança a cada iteração, de 1353,4 a 1359,5.

**Como ler.** Não há fórmula fechada como no MQO, então o otimizador sobe o
morro aos poucos. A restrição entra no próprio otimizador, que nunca testa um
ponto proibido. Nesta janela o ótimo ficou longe da parede (α + β = 0,714). Foram 24 iterações e 1273 cálculos da verossimilhança
(o gradiente é numérico, cada passo calcula a função várias vezes).

**Cuidado.** O mapa é um corte com ω fixo, mas o otimizador mexe em ω também.
Por isso o caminho não precisa seguir as curvas de nível do mapa.

## 5. Ljung-Box: como se confere se sobrou alguma coisa (`05_ljung_box`)

**O que mostra.** Três linhas, cada uma com as autocorrelações das 10 primeiras
defasagens (barras, com a faixa de ±0,088 de ruído) e a estatística Q acumulada
contra o valor crítico de 15,51 (qui-quadrado com 8 graus de liberdade a 5%).

**Como ler, linha a linha.**

- Resíduos do ARIMA: Q = 20,3, p = 0,009. Ainda sobra autocorrelação no
  ARIMA(1,1,1). É o argumento para a grade de AIC em vez de fixar a ordem.
- Resíduos ao quadrado: Q = 29,3, p = 0,0003. A **variância** tem memória: dia
  agitado puxa dia agitado. É isso que justifica usar o GARCH.
- Resíduos padronizados pelo GARCH, ao quadrado: Q = 5,1, p = 0,75. Depois de
  dividir pelo σ do GARCH, a memória da variância some. O GARCH capturou o que
  devia.

**Cuidado.** Q é a soma das autocorrelações ao quadrado, ponderada. Uma barra
fora da faixa sozinha não reprova; o que conta é a soma.

---

# Parte 2: o robô funcionando

**De onde vêm os números.** Do traço por barra que o próprio robô gravou na
refação de 05/10/2026 (`dados/resultados/refeito_2026-10-05/traco_demo/`):
configuração **ARIMA-GARCH Sharpe** escolhida na calibração de 2014–2016 (C4),
PETR4, **01/07/2019 a 29/06/2021** (calmaria, crise da COVID e recuperação),
com a execução gêmea sem GARCH para comparar. Nada foi rodado de novo. A
procedência está em `dados/resultados/robo_em_acao_2026-10-30/LEIAME.md`.

**Como o robô estava configurado** (o que aparece nas figuras): janela de 240
pregões, ordens refeitas a cada 21 pregões, ARIMA com constante, GARCH como
filtro com limiar no percentil 70, **só compra**, e posição **zerada no veto**.

**Mostram mecanismo, não desempenho.** Nenhuma destas figuras mede lucro. O
resultado financeiro é o do Cap. III.

Ordem sugerida: 8 (um pregão) → 12 (mapa da decisão) → 9 (o ARIMA) → 10 (o ARIMA
mudando) → 11 (o GARCH mudando) → 14 (a memória do GARCH) → 13 (o resultado na
exposição).

## 8. Um pregão, passo a passo (`08_um_pregao`)

**O que mostra.** Dois pregões seguidos, 19/02/2021 e 22/02/2021, com os
números reais de cada passo: dados → ADF → AIC → Hannan-Rissanen → previsão →
GARCH → decisão. Nos dois o modelo é o mesmo ARIMA(3,1,0) e a previsão é de
alta. No primeiro o GARCH libera a compra. No segundo, a queda de 6,9% da sexta
entrou nos resíduos, a volatilidade prevista passou do limiar e o GARCH vetou:
não comprou e zerou a posição. O pregão de segunda caiu 24,2%, e o ARIMA puro só
saiu na quarta.

**Como dizer.** É a figura que mostra a divisão de papéis: os passos 1 a 5 são o
ARIMA (direção), o 6 é o GARCH (risco), e só o 6 muda entre os dois dias.

**Cuidado.** É um exemplo escolhido para mostrar o mecanismo. O GARCH **não
previu** a queda de segunda: reagiu à de sexta, que o robô perdeu do mesmo
jeito. E a variação do dia é do fechamento anterior ao fechamento, não do preço
em que o robô comprou ou vendeu (ele opera na abertura).

## 12. O mapa da decisão (`12_mapa_decisao`)

**O que mostra.** Cada pregão é um ponto. Na horizontal, a previsão do ARIMA;
na vertical, a volatilidade prevista pelo GARCH dividida pelo limiar. As duas
linhas dividem o plano em três regiões: compra (verde, 240 pregões), venda, que
para um robô só de compra significa zerar a posição (cinza, 136), e vetada
(vermelha, 120).

**Como ler.** Esquerda ou direita é o ARIMA; abaixo ou acima é o GARCH. O GARCH
não move ninguém para a esquerda nem para a direita, só para fora.

**Conferência.** A regra "veta se σ prevista > limiar", refeita a partir das
colunas do traço, bate com o veto registrado pelo robô nos 496 pregões, sem
nenhuma diferença.

## 9. O que o ARIMA prevê e o que acontece (`09_previsao_arima`)

**O que mostra.** À esquerda, no tempo, o retorno previsto (azul) e o realizado
(cinza). À direita, um ponto por pregão: previsão contra realizado, verde quando
a direção acertou e vermelho quando errou.

**Como ler.** Se a previsão fosse boa, os pontos seguiriam a diagonal. Eles
formam uma faixa vertical: o desvio-padrão da previsão é 0,64% e o do realizado,
3,69%, cerca de 6 vezes mais. A direção acertou em 249 de 490 pregões (50,8%).

**Como dizer.** É o resultado esperado para preço de ação, e o TG já diz isso:
o ARIMA encontra quase um passeio aleatório. O robô só usa o sinal da previsão.

**Cuidado.** 50,8% é praticamente cara ou coroa. Não foi feito teste formal
aqui, então não dizer "significativo" nem "pior que o acaso".

## 10. O ARIMA mudando (`10_reestimacao`)

**O que mostra.** Em cima, o preço; no meio, as ordens p e q escolhidas; embaixo,
os coeficientes φ₁ e θ₁. As faixas cinza são os trechos em que o ADF escolheu
d = 0.

**Como ler.** A cada 21 pregões o robô refaz o ADF e o AIC (8 combinações
diferentes de (p, d, q) e 14 trocas em dois anos). Entre uma escolha e outra, os
coeficientes são reestimados todo dia. Em 168 dos 496 pregões o escolhido foi o
ARIMA(0,1,0): a previsão é só a constante, o retorno médio da janela.

**Cuidado.** Com d = 0 o modelo trabalha no log-preço e o φ₁ fica perto de 1.
É o caso do `ia/INCERTEZAS.md`, item 34, e é o que gera os saltos da previsão em
abril de 2020 na figura 9.

## 11. O GARCH mudando (`11_garch_no_tempo`)

**O que mostra.** Em cima, a volatilidade prevista contra o limiar, com os 120
pregões vetados em vermelho. No meio, α e β reestimados todo dia. Embaixo, a
persistência α + β, com os 140 pregões em que ela ficou no limite do otimizador.

**Como ler.** O limiar também anda, porque é o percentil 70 da volatilidade
ajustada dentro da própria janela. Na crise de março de 2020 a volatilidade
prevista chegou a 28,3% ao dia (10/03/2020) e o GARCH vetou por semanas.

**Cuidado.** Persistência encostada em 1 quer dizer que, naquela janela, o
modelo tratava a volatilidade alta como quase permanente. Está registrado em
`ia/INCERTEZAS.md`, item 82, e não foi investigado.

## 14. A memória do GARCH (`14_memoria_garch`)

**O que mostra.** Dois conjuntos de parâmetros reais: o da janela da validação
(α = 0,126, β = 0,588) e o do pregão liberado da figura 8 (α = 0,215,
β = 0,707). À esquerda, quanto um choque de hoje aumenta a volatilidade prevista
para amanhã. À direita, depois de um choque de −6,71% (o maior resíduo da janela
da validação), quantos dias a volatilidade leva para voltar ao nível de longo
prazo.

**Como ler.** A curva da esquerda é simétrica: para o GARCH(1,1) só importa o
tamanho do choque, não o sinal. À direita, a meia-vida é de 2,1 dias com
persistência 0,714 e de 8,6 dias com 0,923. Com persistência perto de 1, como em
boa parte de 2020, a volatilidade quase não volta, e o veto se prolonga.

**Cuidado.** A projeção de vários dias à frente é só para ilustrar a equação. O
robô usa apenas a previsão de um dia e reestima tudo no pregão seguinte.

## 13. Quando cada versão ficou comprada (`13_exposicao`)

**O que mostra.** O preço com os vetos e, embaixo, duas faixas: em que pregões o
ARIMA puro (296) e o ARIMA-GARCH (240) estavam comprados.

**Como ler.** As duas recebem os mesmos sinais, então o GARCH só pode tirar
exposição. Em nenhum pregão a versão com GARCH estava comprada com o ARIMA puro
fora, e em 56 o contrário.

**Cuidado, e é o mais importante desta parte.** Na queda de março de 2020 **as
duas versões já estavam fora**: o próprio ARIMA deu sinal de venda em 27/02/2020,
o mesmo pregão em que o GARCH começou a vetar.
Nesta janela o GARCH não foi o que tirou o robô da crise. A diferença entre as
duas aparece depois: em abril de 2020 o ARIMA puro voltou a comprar e o GARCH,
ainda vetando, não; e em fevereiro de 2021 (figura 8). Não usar esta figura para
dizer que o GARCH "fugiu da crise".
