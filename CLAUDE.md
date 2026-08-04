# AlgoTradingLab — ARIMA-GARCH em MQL5

Código do Trabalho de Graduação (FATEC Indaiatuba, ADS) — Bruno Rocha Pereira e
Giovanni Silva Loose. Ativo de estudo: **PETR4**, timeframe **D1**.

O texto do TG em LaTeX fica em `tg/`. **O código e o texto precisam concordar**:
`tg/conteudo/cap2-metodologia.tex` está em voz passada e afirma que o experimento
foi executado de determinada maneira. Toda afirmação metodológica lá tem que ter
contrapartida no código.

## Regra número 1: não misturar Python

Decisão do autor, firme: **tudo em MQL5**. Não sugerir statsmodels, arch, pandas
ou integração via socket/arquivo. Se algo parece exigir Python, a resposta é
implementar em MQL5 ou usar a ALGLIB que já vem com o MetaTrader 5.

(Python é aceitável apenas como conferência descartável fora do repositório,
nunca como dependência do projeto.)

## Arquitetura

```
Include/
  Numerico.mqh       MQO (mínimos quadrados) sobre ALGLIB. Única porta de
                     entrada para álgebra linear.
  Estatistica.mqh    ADF (valores críticos de MacKinnon 2010), Ljung-Box,
                     autocorrelação, AIC/BIC, média/variância.
  Arima.mqh          CArima — estimação por Hannan-Rissanen.
  Garch.mqh          CGarch — máxima verossimilhança com restrições (MinBLEIC).
  SelecaoModelo.mqh  'd' por ADF sequencial; (p,q) por busca em grade no AIC.
  Estrategia.mqh     As três formas de usar o GARCH + limiar absoluto/percentil.

ARIMA-GARCH/
  ARIMA_GARCH_EA.mq5 O EA. `UsarGARCH` alterna entre ARIMA puro e ARIMA-GARCH.
```

Dependência externa: **nenhuma**. A ALGLIB (`MQL5/Include/Math/Alglib/`) e a
`Math/Stat/` já acompanham qualquer instalação do MetaTrader 5.

### Um EA, dois modelos

`UsarGARCH=false` e `UsarGARCH=true` percorrem o **mesmo** código de previsão,
a mesma janela e a mesma execução de ordens. A única diferença é o GARCH vetar
ou redimensionar a operação. Isso é proposital: numa comparação entre os dois
modelos, nenhuma diferença de implementação pode ser confundida com efeito do
GARCH. **Não criar um segundo EA** — quebraria essa garantia.

### Divisão de papéis (não violar)

- **ARIMA → direção.** Média condicional. É quem diz compra ou venda.
- **GARCH → risco.** Variância condicional. **Nunca** gera sinal de direção;
  só veta a operação ou muda o volume.

## Decisões e o porquê

### Log-preço, não preço bruto (`Transformacao = TRANSF_LOG_PRECO`)

A mais importante. Com log-preço e d=1, a série modelada é o **log-retorno**, e
a volatilidade do GARCH sai adimensional: `0.02` significa "2% ao dia" para
qualquer ativo, preço ou ano.

Com preço bruto a volatilidade sai em reais. Para PETR4 o desvio-padrão diário
é ~R$ 0,50, então um limiar de `0.02` significaria "2 centavos" e bloquearia
100% das operações. **Era exatamente esse o defeito da versão anterior do EA.**

### ALGLIB para os núcleos numéricos

Escolha do autor. Não existe ARIMA nem GARCH prontos em MQL5 — a ALGLIB fornece
só as peças (solver linear, otimizador com restrições). Os modelos são escritos
aqui; a ALGLIB entra em dois pontos:

- `CAlglib::RMatrixSolve` / `RMatrixInverse` → MQO em `Numerico.mqh`
- `CAlglib::MinBLEICCreateF` + `MinBLEICOptimize` → verossimilhança do GARCH

### ARIMA por Hannan-Rissanen, não gradiente descendente

Gradiente descendente exige taxa de aprendizado, e o gradiente de uma regressão
cresce com o **quadrado da escala** dos dados — a mesma taxa que converge para
um ativo de R$ 36 diverge num de R$ 5. Hannan-Rissanen é MQO exato em dois
estágios: sem taxa de aprendizado, sem número de iterações, invariante a escala.

Estágio 1 ajusta um AR(m) longo (m ≈ log(N)²) para estimar os erros não
observáveis; estágio 2 regride z(t) contra z e erros defasados. Se `q=0` o
estágio 1 é dispensado (MQO direto).

### AIC sempre sobre amostra comum

`BuscarMelhorPQ()` chama `CArima::DefinirAquecimentoMinimo(max(p_max,q_max))`
em **todos** os candidatos, para que a verossimilhança de cada um seja somada
sobre exatamente as mesmas observações.

Sem isso o ARIMA(0,d,0) avalia 399 observações e o ARIMA(4,d,4) só 395. Como a
log-verossimilhança cresce com o número de parcelas, o modelo menor vence por
construção. Na primeira medição em PETR4 esse viés valia ~22 pontos de AIC,
contra um espalhamento real entre modelos de ~34 — ou seja, dominava a escolha.
**Não remover essa chamada.**

### GARCH por MLE com restrições, não clipping

As restrições ω>0, α,β≥0 e Σα+Σβ<1 entram **no otimizador** (`MinBLEICSetBC` /
`MinBLEICSetLC`), não como clipping depois do passo. Clipping deixa o otimizador
empurrar o parâmetro contra a parede sem nunca convergir.

**Truque de escala:** otimiza-se `omega_rel = ω / variância_amostral`, que é
adimensional e da mesma ordem de α e β. Sem isso o otimizador teria que lidar
com ω ~ 1e-6 ao lado de β ~ 0,9 e não convergiria.

O gradiente é numérico (`MinBLEICCreateF`) — com 3 parâmetros o custo é
irrelevante e elimina uma fonte clássica de erro algébrico.

### Semântica do limiar por percentil

Com `ModoLimiar = LIMIAR_PERCENTIL`, o limiar é o percentil da série de
volatilidade condicional **ajustada dentro da janela**, e é comparado contra a
**previsão de um passo à frente**. Os dois não vêm da mesma distribuição: a
previsão usa os últimos ε e σ² observados, então em janelas que terminam
agitadas ela fica no topo da distribuição. Na prática o percentil 70 chegou a
vetar ~80% dos sinais, não 30%. Isso é comportamento esperado, não bug — mas
ao ajustar o parâmetro, contar o veto real no log em vez de supor.

## Bugs da versão anterior — não reintroduzir

O código antigo (`ARIMA/ARIMA_EA.mq5` e `ARIMA-GARCH/GARCH.mq5`, mantidos no
histórico do git) tinha:

1. **Sinal do gradiente invertido no GARCH.** Calculava ∂ℓ/∂σ² da
   log-verossimilhança e depois fazia `omega -= lr*grad`, ou seja, *minimizava*
   a verossimilhança. Só parava onde o clipping segurava.
2. **Termo ARCH descartado na previsão.** Justificava com "o erro futuro é
   desconhecido", confundindo ε(N) — de fato desconhecido — com ε(N−1), que é o
   último resíduo observado. Subestimava a volatilidade sistematicamente.
3. **Erro de escala.** `omega` inicial `0.1` e limiar `0.02` sobre resíduos em
   reais → o filtro nunca liberava operação.
4. **Off-by-one** em `ForecastVariance` (usava `variance[n-2]` em vez de
   `variance[n-1]`); `last_variances` alocado e nunca usado.
5. **Zeros de aquecimento** iam para o GARCH junto com os resíduos, contaminando
   a variância amostral. Hoje `CArima::ObterResiduos()` corta o aquecimento.
6. **Barra 0 na janela.** Usava `CopyClose(...,0,...)`, incluindo a barra ainda
   em formação. Hoje começa em 1 (só barras fechadas).

## O que o TG promete e onde está implementado

| `cap2-metodologia.tex` | Implementação |
|---|---|
| "ordem d por aplicação sequencial do teste ADF" (l. 94) | `DeterminarOrdemD()` |
| "p e q de 0 a 4, seleção por AIC" (l. 96) | `BuscarMelhorPQ()`, inputs `Max_p`/`Max_q` |
| "estacionariedade dos resíduos por ADF" (l. 132) | `TesteADF` + `TesteLjungBox` |
| "resíduos do ARIMA como entrada do GARCH" (l. 100) | `CArima::ObterResiduos()` → `CGarch::Ajustar()` |
| "foco na especificação GARCH(1,1)" (l. 104) | `GARCH_p=1`, `GARCH_q=1` |
| Filtro de volatilidade como "abordagem mais prudente" (cap1) | `EST_FILTRO_VOLATILIDADE`, padrão |

Ligar `RelatorioInicial=true` faz o EA imprimir a sequência do ADF e a grade de
AIC completa no log — é o material das tabelas do TG.

## Compilar e testar pela linha de comando

O MetaTrader roda sob Wine (o ambiente Windows foi perdido — está documentado
como obstáculo em `cap2-metodologia.tex`).

**Compilar** (caminho relativo à raiz do MT5, `/log` sem argumento):

```bash
cd "/home/dark/.wine-mt5/drive_c/Program Files/MetaTrader 5"
wine MetaEditor64.exe /compile:"MQL5\Experts\AlgoTradingLab\ARIMA-GARCH\ARIMA_GARCH_EA.mq5" /log
iconv -f UTF-16LE -t UTF-8 "MQL5/Experts/AlgoTradingLab/ARIMA-GARCH/ARIMA_GARCH_EA.log" | grep -i "error\|Result:"
```

O log sai em **UTF-16LE** — sem o `iconv` parece binário.

**Rodar um script**: usar `/config:` com `[StartUp]`, mas **sem**
`ShutdownTerminal=1` — sob Wine ele mata o script antes do `OnStart`. Rodar em
background, esperar, e depois `pkill -f terminal64.exe`.

**Backtest**: `/config:` com seção `[Tester]` e `[TesterInputs]`.

## Validação numérica já feita

Recuperação de parâmetros em dados sintéticos com verdade conhecida:

| | Verdadeiro | Estimado |
|---|---|---|
| ARMA(1,1) φ₁ / θ₁ | 0,600 / 0,400 | 0,5799 / 0,4105 |
| AR(2) φ₁ / φ₂ | 0,500 / −0,300 | 0,4815 / −0,2891 |
| GARCH ω / α / β | 1,00e-5 / 0,090 / 0,890 | 1,17e-5 / 0,0825 / 0,8941 |

ADF discrimina corretamente: passeio aleatório −1,48 (não rejeita), AR(1) φ=0,5
−17,92 (rejeita), primeira diferença do passeio −46,19 (rejeita).

Em PETR4 D1 real (500 barras): ADF log-preço −0,95 (não estacionário), ADF
log-retorno −21,37 (estacionário) → **d=1 confirmado empiricamente**.
ARIMA(1,1,1) → GARCH(1,1) dá volatilidade diária prevista de ~1,6%.
Ljung-Box nos resíduos padronizados ao quadrado: p=0,79 → o GARCH capturou a
heterocedasticidade.

Observação útil: o Ljung-Box nos resíduos do ARIMA(1,1,1) deu p=0,021, ou seja,
ainda sobra autocorrelação nessa especificação — é justamente o argumento a
favor da busca em grade em vez de fixar (1,1,1).

## Resultados do walk-forward (PETR4 D1, 300 passos, janela móvel 250)

Reestimação a cada passo usando **apenas** dados anteriores à barra prevista.

Seleção com amostra comum: **ARIMA(4,1,0)**, AIC −2155,368.

|  | operações | acertos | taxa | retorno log acum. |
|---|---|---|---|---|
| ARIMA puro | 243 | 124 | 51,0% | +0,2291 |
| ARIMA-GARCH (filtro) | 127 | 61 | 48,0% | +0,0768 |

**Três ressalvas que precisam acompanhar esses números em qualquer texto:**

1. **Nada aqui é estatisticamente significativo.** 51,0% em 243 operações tem
   erro-padrão de 3,2 pontos (z = 0,31 contra a hipótese de 50%). 48,0% em 127
   operações dá z = −0,45. Ambos são indistinguíveis de cara ou coroa. **Não
   escrever no TG que o ARIMA puro "superou" o ARIMA-GARCH** — a diferença de
   retorno é ruído.

2. **A seleção de ordens não é decisiva.** Os cinco melhores AIC ficam dentro
   de ~2 pontos entre si ((4,0)=−2155,4; (0,4)=−2153,8; (0,0)=−2153,5;
   (0,1)=−2152,6; (1,4)=−2152,6). Diferença de AIC menor que 2 é
   convencionalmente tratada como empate. A escolha de (4,1,0) é frágil.

3. **O filtro de volatilidade corta exposição sem discriminar direção.** Antes
   da correção do AIC comum a grade escolhia ARIMA(0,1,0), o modelo perdia, e o
   filtro cortava a perda (−0,1218 → −0,0017). Com ARIMA(4,1,0), que teve
   retorno positivo, o mesmo filtro cortou o ganho (+0,2291 → +0,0768). É
   coerente com a teoria: o GARCH modela variância, não direção, então não há
   razão para ele melhorar acerto direcional. Ele é ferramenta de **redução de
   risco**, não de alfa — e é assim que deve ser apresentado no TG (hipótese de
   Adequação ao Risco, não de Potencialização Preditiva).

Esse episódio também é a evidência de que a correção do AIC importou: o bug
mudava a especificação selecionada de (4,1,0) para (0,1,0).

## Scripts de validação (fora do repositório)

Ficam em `MQL5/Scripts/`, **não versionados** (o repositório é só
`Experts/AlgoTradingLab`), porque o empacotamento escolhido foi "um EA só":

- `ValidacaoAlgoLab.mq5` — recuperação de parâmetros em dados sintéticos com
  verdade conhecida + pipeline completo em PETR4.
- `WalkForwardAlgoLab.mq5` — seleção de ordens + walk-forward comparando
  ARIMA puro contra ARIMA-GARCH.

São eles que geram a sequência do ADF e a grade de AIC para as tabelas do TG.
Se forem úteis a longo prazo, mover para dentro do repositório.

## Pendências

- Decidir o benchmark da comparação final: **Selic** ou **ARIMA puro vs
  ARIMA-GARCH**. Ainda em aberto. O EA já suporta o segundo caso via
  `UsarGARCH`; para a Selic seria preciso uma série externa de referência.
- Inserir os resultados de backtest em `cap2-metodologia.tex`, seção
  "Limitações e Trabalhos Futuros" (hoje diz "ainda estão sendo consolidados").
- O p-valor do ADF é **aproximado** (interpolação entre os valores críticos).
  A decisão do teste usa os valores críticos, que são exatos. Não reportar o
  p-valor do ADF no TG como se fosse exato.
- `ARIMA/ARIMA_EA.mq5` e `ARIMA-GARCH/GARCH.mq5` são a implementação antiga,
  substituída. Decidir se saem do repositório (o Apêndice A do TG referencia
  código MQL5 — conferir qual versão está lá antes de apagar).
