# Parâmetros: o que foi escolhido e por quê

Levantamento de **todas** as escolhas numéricas do experimento, com a origem de
cada uma. Serve de base para a metodologia do TG e para responder à banca.

Cada item traz um **status**, que é o que importa numa arguição:

| Status | Significado |
|---|---|
| **teoria** | vem da definição do modelo ou de resultado estatístico conhecido |
| **convenção** | prática comum em séries financeiras diárias; não foi testado aqui |
| **experimento** | escolhido pela calibração, entre valores testados |
| **ambiente** | imposto por limitação do MetaTrader, dos dados ou da B3 |
| **projeto** | decisão de escopo do trabalho |
| **arbitrário** | escolhido por julgamento, sem teste e sem fonte — os que a banca pode cobrar |

---

## 1. Modelagem

### 1.1 Transformação: log-preço (`Transformacao = TRANSF_LOG_PRECO`) — **teoria**
Com log-preço e d=1, a série modelada é o log-retorno. A volatilidade do GARCH
sai adimensional: 0,02 significa "2% ao dia" para qualquer ativo e qualquer
preço. Com preço bruto ela sairia em reais, e um limiar de 0,02 significaria
"2 centavos", bloqueando todas as operações — era o defeito da versão anterior
do EA.

### 1.2 Ordem de integração `d` por ADF sequencial, `Max_d = 2` — **teoria** / teto **arbitrário**
Diferencia enquanto o ADF não rejeita raiz unitária. Em PETR4 o resultado é
sempre d=1 (ADF do log-preço −0,95, do log-retorno −21,37). O teto de 2 nunca
foi atingido: é só uma trava de segurança.

### 1.3 Defasagens do ADF: automáticas por AIC, teto pela regra de Schwert — **teoria**
`k_max = floor(12 × (T/100)^(1/4))`, limitado a `(n−10)/4`; entre 0 e esse teto,
escolhe o k de menor AIC da regressão auxiliar. Regra padrão da literatura de
raiz unitária.

### 1.4 Valores críticos do ADF: MacKinnon (2010) — **teoria**
A distribuição nula do ADF não é padrão; usa-se a superfície de resposta de
MacKinnon. A decisão do teste usa os valores críticos (exatos); o p-valor
reportado é interpolado e **aproximado** (ver `ia/INCERTEZAS.md`).

### 1.5 Termo determinístico do ADF: constante, sem tendência — **convenção**
Preços têm média diferente de zero; manter a constante também nas diferenças é
a escolha conservadora.

### 1.6 Faixa de busca `p` e `q`: 0 a 4 — **projeto** (vem do texto do TG)
A metodologia escrita promete "múltiplas combinações de 0 a 4". Ordens acima de
4 não foram testadas. Para série diária, ordens altas raramente sobrevivem ao
AIC.

### 1.7 Critério de seleção: AIC (não BIC) — **projeto**
Também vem do texto. O BIC é calculado e aparece no relatório, mas não decide.
O BIC penaliza mais parâmetros e escolheria modelos ainda menores.

### 1.8 AIC sobre amostra comum — **experimento**
Todos os candidatos descartam o mesmo aquecimento inicial,
`max(p_max, q_max) = 4` observações. Sem isso o modelo menor vence por
construção: a log-verossimilhança soma mais parcelas. Na primeira medição em
PETR4 esse viés valia ~22 pontos de AIC, contra um espalhamento real de ~34
entre modelos.

### 1.9 Estimação do ARIMA: Hannan-Rissanen — **teoria**
Dois mínimos quadrados em sequência: um AR longo estima os erros não
observáveis, depois regride a série contra defasagens e erros. É exato, não tem
taxa de aprendizado e é invariante à escala dos preços. A alternativa usada na
versão antiga (gradiente descendente) diverge quando muda a faixa de preço do
ativo.

### 1.10 Ordem do AR longo: `m = floor(log(N)²)`, com piso `p+q+1` e teto `N/5` — **teoria** / limites **convenção**
A regra log(N)² é a do próprio método. O piso garante graus de liberdade; o teto
evita consumir a amostra. Os dois limites são convencionais, não testados.

### 1.11 Especificação GARCH(1,1) — **projeto** (vem do texto) + **convenção**
O texto promete "foco inicial e principal na especificação GARCH(1,1)". Ordens
maiores existem no código (`GARCH_p`, `GARCH_q`) mas **não foram testadas**.

### 1.12 Estimação do GARCH: máxima verossimilhança com restrições — **teoria**
Restrições ω>0, α≥0, β≥0 e Σα+Σβ ≤ 0,9999 entram no otimizador (MinBLEIC), não
como corte depois do passo. São as condições de variância positiva e de
estacionariedade da variância. Cortar depois faz o otimizador empurrar o
parâmetro contra a parede sem convergir.

### 1.13 Reescala `omega_rel = ω / variância amostral` — **teoria**
ω tem a unidade da variância (~1e-6 em log-retornos) enquanto α e β ficam entre
0 e 1. Otimizar grandezas de ordens tão diferentes não converge. A versão
adimensional resolve.

### 1.14 Valores iniciais: ω_rel = 0,05; α = 0,10; β = 0,85 — **convenção**
Valores típicos de séries financeiras diárias (persistência alta, reatividade
baixa). Aceleram a convergência. **A sensibilidade a esse ponto de partida não
foi testada.**

### 1.15 Otimizador: gradiente por diferenças finitas, passo 1e-6; tolerâncias 1e-8; máximo de 300 iterações — **arbitrário**
Com 3 parâmetros o custo do gradiente numérico é irrelevante e evita erro
algébrico ao derivar a verossimilhança à mão. Passo e tolerâncias são os valores
usuais; **não foram variados**. As falhas de convergência são contadas no log.

---

## 2. Janelas de dados

### 2.1 Janela de estimação: 120 ou 240 barras — **experimento**
Testados os dois (≈ 6 meses e ≈ 1 ano). Nas 48 escolhas da rodada 4 (4 ativos ×
3 períodos × 2 famílias × 2 critérios), **240 foi escolhida 30 vezes e 120, 18**.
Janela curta adapta rápido e estima com mais ruído; longa faz o contrário.

**Atenção:** o valor padrão que está hoje no EA é 120, herdado da rodada 1, cujos
dados foram descartados. Ele não corresponde à escolha majoritária da rodada 4.
O padrão do código precisa ser atualizado ou o texto deve deixar claro que cada
período tem sua própria configuração escolhida.

### 2.2 Janela de seleção de ordens: 240 barras — **ambiente**
O Strategy Tester só entrega histórico a partir de 1º de janeiro do ano anterior
ao início do teste. Com 240 a seleção funciona já na primeira barra; com 500
ficaria adiada por meses, silenciosamente. Foi o que aconteceu na primeira
tentativa.

### 2.3 Reavaliação das ordens a cada 21 barras — **convenção**
21 pregões ≈ 1 mês. Foi comparado com "só no início" na rodada 1 (dados hoje
descartados), onde a mediana favoreceu a reavaliação mensal, e desde então ficou
**fixo**: as rodadas 3 e 4 não testaram alternativas. É, portanto, convenção, e
não resultado.

### 2.4 Constante (drift) no ARIMA: testada ligada e desligada — **experimento**
Nas 48 escolhas da rodada 4, a versão **sem constante foi escolhida 30 vezes** e
a versão com constante, 18. Com constante e ordens automáticas, o AIC escolhe
ARIMA(0,1,0) e a previsão vira a média da janela: o robô compra e segura, com
uma operação no período inteiro. Sem constante, a previsão depende só da
estrutura de autocorrelação.

---

## 3. Uso do GARCH na decisão

### 3.1 As quatro estratégias — **projeto** (vêm da fundamentação teórica)
Filtro de volatilidade, volatility targeting, intervalo de confiança e a
combinação filtro+targeting. As três primeiras são as descritas no capítulo 1 do
TG; a quarta é a combinação natural.

### 3.2 Limiar: percentil (50, 70, 90) ou fixo (2%, 3%, 4% ao dia) — **experimento**, faixa **arbitrária**
O percentil se adapta ao regime ("opere nos X% dias mais calmos"); o fixo não se
acostuma com a crise. A faixa de 2% a 4% cobre a volatilidade diária típica da
PETR4 (~1,6%) até o dobro dela. **Valores fora dessa faixa não foram testados.**

### 3.3 Volatilidade alvo do targeting: 1% e 2% ao dia — **arbitrário**
Um abaixo e um acima da volatilidade típica. Não foram testados outros.

### 3.4 `k` do intervalo de confiança: 0,05 e 0,15 — **experimento**
Com previsões da ordem de 0,1% a 0,3% e volatilidade de 1,6%, exigir
|previsão| > k × volatilidade com k = 0,5 (o padrão antigo) bloqueava quase
tudo. Os valores atuais foram calibrados por observação do número de vetos.

### 3.5 Limiar de sinal: 0 e 0,1% — **experimento**
Filtra previsões muito pequenas mesmo sem GARCH.

### 3.6 Zerar a posição no veto: testado nos dois modos — **experimento**
Foi o que revelou o achado central: só as variantes que **reduzem** a posição
protegem; as que apenas congelam, não.

### 3.7 Limites do targeting: entre 0,25× e 2× o volume base — **arbitrário**
Evita que a posição exploda em mercado parado ou vire pó em mercado agitado.
Não testado.

---

## 4. Negociação

### 4.1 Fração do capital: 95% — **projeto**
Deixa folga para o arredondamento ao lote e evita recusa por margem. Com volume
fixo pequeno (as 100 ações do teste antigo), o resultado seria dominado pelo
caixa parado, não pelo modelo.

### 4.2 Só compra — **experimento** (rodada 4)
Testado contra compra e venda. Operar vendido piorou a mediana em 11 dos 12
casos e levou algumas configurações à ruína. Também é o realista para pessoa
física: vender a descoberto exige aluguel de ações, que não foi simulado.

### 4.3 Sem stop loss e sem take profit — **projeto**
Para isolar o efeito dos modelos. Na réplica do trabalho de Almeida os stops
dele (50 e 100 pontos) foram testados.

### 4.4 Reversão de posição ligada — **projeto**
Ao inverter o sinal, fecha a posição oposta antes de abrir a nova.

### 4.5 Execução na abertura da barra seguinte, modelo "somente preços de abertura" — **ambiente**
Os dados são diários: não existe tick para simular. O EA decide uma vez por dia,
sobre barras fechadas.

---

## 5. Avaliação

### 5.1 Custo de 0,03% por execução — **arbitrário**
Aproximação de emolumentos + liquidação da B3 com corretagem zero. **A tabela de
tarifas da B3 não foi consultada**, e o valor é o mesmo para todos os anos.

### 5.2 Capital inicial R$ 100.000, alavancagem 1:1 — **projeto**
Na réplica de Almeida: R$ 50.000 e 1:100, como no trabalho dele.

### 5.3 Caixa parado rendendo Selic — **projeto**
Sem isso, qualquer estratégia que fique fora do mercado parte do tempo perde da
Selic por construção.

### 5.4 Critérios de escolha: maior Sharpe e maior Calmar na calibração — **projeto**, declarado antes
Registrados em `dados/resultados/rodada3_b3_oficial/PROTOCOLO.md` antes de ver
qualquer resultado. Desempate por menor número de operações.

### 5.5 Períodos: teste de 2007–2011, 2013–2016 e 2025–2026; calibração nos 3 anos anteriores — **projeto**
Os dois primeiros são os períodos de Almeida (2016); o terceiro é o mais
recente possível. Três anos de calibração é escolha nossa, não testada contra
outras durações.

---

## 6. O que um avaliador pode cobrar

Os itens marcados **arbitrário** são os pontos fracos conhecidos:

1. Custo de 0,03% sem fonte primária.
2. Valores iniciais e tolerâncias do otimizador do GARCH, sem teste de
   sensibilidade.
3. Faixa dos limiares (2–4%) e da volatilidade alvo (1–2%).
4. Limites do targeting (0,25× a 2×).
5. GARCH(1,1) fixo, sem testar (2,1) ou (1,2).
6. Duração da calibração (3 anos), sem alternativa testada.
7. Reavaliação mensal das ordens, fixada sem teste nas rodadas válidas.

Nenhum deles invalida o resultado principal — que o GARCH reduz risco quando
reduz posição, em 4 ativos e 3 períodos —, porque esse resultado é a mediana de
centenas de configurações, e não depende de um valor específico. Mas todos
devem estar escritos como limitação, e não descobertos pela banca.
