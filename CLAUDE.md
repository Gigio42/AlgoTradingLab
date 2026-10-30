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

## Regra número 2: todo dado tem procedência

Isto é um trabalho acadêmico: cada número tem de poder ser rastreado até a
origem.

- **Dado externo novo** (preço, taxa, provento, qualquer série) só entra depois
  de registrado em `dados/FONTES.md`: fonte, URL, data e hora do download,
  filtro, transformação e como foi conferido. O arquivo bruto vai para
  `dados/fontes/`; a série pronta que o MT5 lê vai para `dados/series/`.
- **Nunca digitar valor à mão** nem escrever número de memória. Se um número não
  saiu de um arquivo ou log gerado nesta análise, ele não existe.
- **Estimativa, suposição ou coisa não confirmada** vai para `notas/INCERTEZAS.md` e é
  dita explicitamente ao autor, com a palavra "estimativa" ou "não confirmado".
- **Arquivo de dado e obra que se cita moram em lugares diferentes, e nunca nos
  dois.** Obra (artigo, livro, TCC — coisa que entra no `.bib`) vai para
  `bibliografia/pdfs/`, com o nome `Autor-Ano.pdf`. Arquivo de dado (COTAHIST,
  SGS, CSV de cotação) vai para `dados/fontes/`. Quando um número vem de uma
  obra — como os resultados de Almeida (2016) —, o registro fica em
  `dados/FONTES.md` e **aponta** para o PDF na bibliografia; não se faz uma
  segunda cópia. Em 28/09 o trabalho de Almeida ficou duplicado nas duas pastas
  até o autor notar.
  Casos de fronteira já decididos: o `Manual-de-Normas-2021.pdf` e o PTG de 2025
  ficam em `dados/fontes/`, porque são documentos de apoio arquivados junto com
  o material que veio com eles. Se algum deles passar a ser citado no `.bib`,
  muda para `bibliografia/pdfs/`.
- **Preferir fonte oficial**: B3 (COTAHIST) para preços, BCB (SGS) para taxas.
  Yahoo ou corretora só para conferência, ou onde não houver oficial (e então
  marcado como não oficial).
- **Antes de trocar a fonte de dados, perguntar ao autor.** Em 21/09 o Yahoo foi
  usado sem checar o que a Clear e a B3 ofereciam; custou duas rodadas de
  resultados descartados.

## Regra número 3: o escopo é de ADS, e quem escreve é o autor

Isto é um trabalho de graduação em **Análise e Desenvolvimento de Sistemas**, não
uma tese de economia ou finanças. O autor deixou isso explícito em 28/09/2026,
depois de o escopo ter escorregado duas vezes.

**O foco do trabalho:**
1. **Os modelos e a implementação deles**: ARIMA e GARCH escritos em MQL5,
   estimação, seleção de ordens, diagnóstico, arquitetura do EA.
2. **A operação dos modelos**: como eles geram sinal, como o GARCH entra na
   decisão, o que acontece em cada regime de mercado.
3. **A comparação**: ARIMA × ARIMA-GARCH × médias móveis de Almeida (2016), que
   é o trabalho que este TG continua.

**O que é acessório** (pode existir como seção adicional, nunca como eixo):
custo de corretagem e emolumentos, remuneração do caixa pela Selic, proventos,
comparação com a taxa livre de risco, discussão de finanças em geral. São
refinamentos da medição, não o assunto do trabalho.

**Sinal de que o escopo escorregou:** se a conversa virar sobre retorno,
benchmark ou mercado por várias mensagens seguidas sem falar de código, modelo ou
comparação entre modelos, parar e perguntar.

**Sobre referências e escrita:**
- **Não inserir citação no texto de obra que o autor ainda não leu.** O fluxo é:
  eu busco e entrego a lista com o que cada obra sustenta; ele lê; ele decide se
  entra e onde.
- O objetivo dele é conseguir apresentar e defender cada escolha com as próprias
  palavras. Produzir texto que ele não domina destrói o trabalho, mesmo que o
  texto esteja correto.
- Vale também para análises e gráficos: entregar em porções que ele consiga
  acompanhar, e explicar antes de ampliar.

## Regra número 4: as normas da FATEC-ID mandam no texto

O autor trouxe as normas oficiais em 28/09/2026 e foi explícito: **tem que
obedecer tudo.** O resumo operacional está em **`notas/NORMAS-FATEC.md`** (na raiz) e as fontes em
`dados/fontes/normas-fatec/` e no `Manual-de-Normas-2021.pdf` da raiz.

**Antes de escrever ou alterar qualquer coisa em `tg/`, ler `notas/NORMAS-FATEC.md`.**
O que mais pega neste trabalho:

- **Estrutura**: Capítulo I Fundamentação · Capítulo II Percurso Metodológico ·
  **Capítulo III Análise e Discussão dos Dados** · Considerações Finais. Hoje o
  Capítulo III **não existe** — os resultados estão dentro do `cap2`.
- **Capítulo II tem numeração obrigatória** (2.1 Caracterização, 2.1.1 quanto aos
  objetivos, 2.1.2 quanto ao delineamento, 2.2 lugar e amostra, 2.3 procedimentos,
  2.3.1 técnicas, 2.3.2 natureza da análise). O delineamento deste TG é
  **Pesquisa Quase Experimental** — o caderno institucional lista "desenvolvimento
  de softwares" e "análise de algoritmos" como os casos típicos dela.
- **Nome da ilustração é norma**: Quadro para dado qualitativo, Tabela para dado
  numérico, Gráfico para representação geométrica, Figura para o resto. Título em
  cima com travessão, fonte embaixo, sempre citada no texto.
- **Impessoalidade** (terceira pessoa com "se", ou primeira do plural) — é a mesma
  voz passada que o TG já adota.
- **Citação direta exige página**, indireta, autor e ano. **Caixa mista sempre**,
  inclusive dentro dos parênteses (NBR 6023:2025). Em citação direta curta, o
  ponto final vai **depois** do parêntese da autoria.
- **Considerações Finais** têm de responder à pergunta-problema, revisitar cada
  hipótese confirmando ou refutando, e dizer se os objetivos foram alcançados.
- **Sem afastamento entre parágrafos** no texto — hoje o `main.tex` faz o
  contrário (ver `notas/NORMAS-FATEC.md`, item 6).

**Os `.md` deste repositório são notas internas, não material do TG.** Eles
existem para eu obedecer às regras e para o autor acompanhar o que foi feito.
Nenhum deles é fonte: não se cita `notas/NORMAS-FATEC.md`, `FONTES.md`, `notas/INCERTEZAS.md`
nem `CLAUDE.md` no trabalho. Toda definição que precise aparecer no TG — a
classificação da pesquisa, o delineamento, um critério de avaliação — é decisão
do autor, vai escrita no `.tex` e cita a obra original (o livro, o artigo). **Documentos da própria FATEC-ID
(manual, caderno de delineamentos) não entram como referência** (pedido do autor,
19/10/2026): eles guiam a forma, mas não são citados. Dito pelo autor em 28/09/2026: usar um
arquivo de apoio da IA como definição do trabalho fica ruim na apresentação.

**A pasta `tg/` só contém o que vai ser entregue**: `.tex`, `.bib`, figuras,
gráficos e o `Makefile`. Nota de trabalho, dado bruto e script vão para a raiz,
`dados/` ou `ferramentas/`.

**O manual vigente foi obtido em 01/10/2026**: biênio **2026-2027**, 45 páginas,
em `dados/fontes/normas-fatec/Manual-de-Normas-2026-2028.pdf`. Comparado com o de
2021 parágrafo a parágrafo: formatação, estrutura e ilustrações **não mudaram**.
As **citações mudaram**: a NBR 6023:2025 manda o sobrenome em **caixa mista
inclusive dentro dos parênteses**, ou seja `(Almeida, 2016)` e não
`(ALMEIDA, 2016)`. Já aplicado ao `tg/` por redefinição de `\abntrefinfo` no
`main.tex`. A lista de referências continua em caixa alta.

## Arquitetura

```
Include/
  Numerico.mqh             MQO sobre ALGLIB. Única porta de entrada para
                           álgebra linear.
  Estatistica.mqh          ADF (valor crítico a 5% de MacKinnon 2010),
                           Ljung-Box, AIC/BIC, média, variância, percentil.
  Arima.mqh                CArima — Hannan-Rissanen.
  ArimaVerossimilhanca.mqh Opção experimental: refino por máxima
                           verossimilhança (MetodoARIMA=1). Fora do TG.
  Garch.mqh                CGarch — máxima verossimilhança com restrições
                           (MinBLEIC). Previsão de um passo.
  GarchDistribuicao.mqh    Normal (a do TG) e t de Student (experimental).
  SelecaoModelo.mqh        'd' por ADF sequencial; (p,q) por grade no AIC
                           (BIC opcional, experimental).
  Estrategia.mqh           DecidirOperacao: as formas de usar o GARCH.
  Negociacao.mqh           CNegociacao (ordens, posição, volume) e
                           VolumePorCapital. Usado pelos dois EAs.
  Desempenho.mqh           Avaliação em camadas no Strategy Tester e
                           CompararCurvas. Usado pelos dois EAs.

ARIMA-GARCH/
  ARIMA_GARCH_EA.mq5 O EA: inputs, OnInit, OnTick e execução. `UsarGARCH`
                     alterna entre ARIMA puro e ARIMA-GARCH.
  Diagnostico.mqh    CDiagnostico: mensagens, contadores e traço por barra.
  Avaliacao.mqh      Registro por barra e OnTester (linha de métricas).
                     Os dois leem os inputs do EA e só observam.

MediasMoveis2/
  MediasMoveis2.mq5  A MM 10/20 de Almeida, reimplementada.
```

**Limpeza de 18/10/2026 (pedido do autor):** código sem comentário-documentação
(só uma linha por input e o "porquê" curto onde não é óbvio), nomes por extenso,
log e avaliação fora do EA, opções experimentais em módulos próprios, código
morto retirado (p-valor aproximado do ADF, previsão do GARCH h passos, campos da
decisão que ninguém lia). **Os nomes dos inputs e das colunas dos CSVs não
mudaram** (scripts, `.set` e resultados guardados dependem deles). Regressão em
`ferramentas/scripts/regressao_codigo.sh`: 13 casos que passam por todos os
caminhos dos dois EAs, comparados byte a byte (métricas, curva e traço) antes e
depois. **Rodar de novo a cada mudança que não deveria alterar resultado.**

Desde 05/10/2026 o **Apêndice A do TG é o ARIMA_GARCH_EA.mq5 reduzido**: sem
comentários e sem log, diagnóstico, traço e avaliação no testador ("só o modelo
puro", pedido do autor). Gerado pelo `tg/Makefile` em `tg/codigo/` com
`ferramentas/scripts/codigo_apendice.sh`. O que sai está marcado **no próprio
EA** com comentários: `//@omitir-inicio`/`//@omitir-fim` (bloco), linha
terminada em `//@omitir`, e `//@apendice: CODIGO` (o que entra no lugar). São só
comentários: o EA sem comentários ficou idêntico ao de antes dos marcadores
(conferido com `diff`). Desde a limpeza de 18/10/2026 o log mora em
`ARIMA-GARCH/Diagnostico.mqh` e a avaliação em `Avaliacao.mqh`; no EA sobram
chamadas de uma linha com `//@omitir`, e o script ainda tira as linhas que só
tinham comentário e as chaves de um `if` que ficou com uma instrução. A listagem
reduzida (216 linhas desde 29/10/2026, quando saíram também as opções que os experimentos não usam: preço bruto, ordens manuais, volume fixo, StopLoss/TakeProfit, reversão desligável, GARCH_p/q trocado por `Definir(1, 1)`, input group, validação, Iteracoes_GARCH, tipo de ADF e destrutores; INCERTEZAS item 81) e o EA compilam com 0 erros e 0 avisos. **Ao acrescentar
log ou diagnóstico novo, pôr no `Diagnostico.mqh` e chamar com uma linha
terminada em `//@omitir`** (chamada de várias linhas quebra o marcador), e
recompilar a listagem para conferir.
**Desde 27/10/2026 há o Apêndice B** (`tg/conteudo/apendice-b.tex`): `Arima`,
`SelecaoModelo`, `Garch` e `Estrategia` reduzidos pelo mesmo script (regra
`codigo/%.mqh` do `tg/Makefile`), sem as opções experimentais. **Opção
experimental nova nesses `.mqh` tem de levar o marcador** (INCERTEZAS item 80).

```
```

### Traço por barra (`Arquivo_Traco`, acrescentado em 30/09/2026)

Input **desligado por padrão** (string vazia). Com um nome preenchido, o EA grava
`Common/Files/AlgoLab/traco_<nome>.csv` com **39 campos por barra**: as ordens
(p,d,q) em uso, a constante e os coeficientes φ₁–φ₄ e θ₁–θ₄ do ARIMA, σ², logL,
AIC, BIC e número efetivo de observações, a previsão no espaço diferenciado e no
nível, ω/α₁/β₁/persistência/variância de longo prazo do GARCH, σ prevista, σ
atual, limiar, e a decisão com `vetou`, `ordem_enviada`, posição e motivo.

É **só diagnóstico**: nada ali influencia a decisão de operar. Serve para ver o
modelo sendo reestimado dia a dia (é o que alimenta o painel de demonstração).

**Verificado em 30/09:** o teste `R6_GS` da rodada 6 foi reexecutado com o EA
modificado e comparado ao arquivo guardado — **72 campos, zero diferenças**.
A alteração não muda nenhum resultado.

**O campo `ordem_enviada` importa.** Ele é escrito depois da execução,
comparando o contador de ordens antes e depois, e diz se o EA **de fato** mandou
ordem naquela barra. Não dá para inferir isso de fora: "o modelo decidiu uma
direção" (377 dias nesta janela) é diferente de "o EA enviou ordem" (69). Uma
versão anterior do painel de demonstração desenhou uma seta por decisão e
sugeria um giro cinco vezes maior que o real.

O mapa completo do repositório está no `README.md` da raiz. As pastas, em uma
linha cada: `Include/` e `ARIMA-GARCH/` e `MediasMoveis2/` são o código que roda;
`ferramentas/` são scripts de apoio (.mq5 e .sh); `dados/` é fonte, série pronta,
verificação e resultado; `bibliografia/` é a literatura; `tg/` é só o que vai ser
entregue; `notas/` são as notas internas; `legado/` é a implementação antiga,
guardada para consulta.

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

### Por que ARIMA, e não GARCH sozinho, continua o trabalho de Almeida

Argumento do autor, dito em 28/09/2026, e que ele quer poder defender: o GARCH
sozinho não serve para operar, porque só modela **variância** — não diz direção.
Almeida sugeriu ARCH/GARCH como trabalho futuro, mas para fechar o ciclo é
preciso alguém que dê o sinal. O ARIMA é esse alguém, e é o passo natural a
partir da média móvel dele.

**A ponte, dita com precisão** (para não escorregar na defesa): a média móvel de
Almeida é um **filtro linear de pesos fixos** sobre o preço — a MMS de 10 dá peso
1/10 a cada um dos 10 últimos fechamentos — e a regra de decisão é o sinal do
cruzamento. Um AR(p) sobre o log-retorno é o **mesmo tipo de filtro linear com os
pesos estimados dos dados** em vez de fixados por convenção, e a decisão passa a
ser o sinal da previsão. Nesse sentido o ARIMA generaliza a média móvel: mesma
família de operação, coeficientes ajustados ao ativo e ao período.

**O que NÃO dizer:** que o "MA" do ARIMA é a média móvel da análise técnica. Não
é. O MA do ARIMA é média móvel dos **erros** (ruídos passados), não dos preços.
São coisas diferentes com o mesmo nome, e confundir as duas é o tipo de erro que
uma banca pega. A ponte correta é a do parágrafo acima, pelo lado do AR.

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

O código antigo (`legado/ARIMA_EA.mq5` e `legado/GARCH.mq5`, mantidos no
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
| Filtro de volatilidade como "abordagem mais prudente" (cap1) | `FILTRO_VOLATILIDADE`, padrão |

Ligar `RelatorioInicial=true` faz o EA imprimir a sequência do ADF e a grade de
AIC completa no log — é o material das tabelas do TG.

## MetaTrader sob Wine: onde as coisas estão

O MetaTrader roda sob Wine (o ambiente Windows foi perdido — está documentado
como obstáculo em `cap2-metodologia.tex`).

**Existem DOIS prefixos Wine com MT5. Conferir qual antes de mexer em qualquer
coisa.** Em 2026-09-12 um conserto de som foi aplicado no prefixo errado porque
isso foi suposto em vez de verificado.

| Prefixo | Papel |
|---|---|
| `~/.wine-mt5-novo` | **O que está em uso.** Instalação refeita em 2026-08-04. É o que `~/.local/bin/launch-mt5.sh` e todos os atalhos `.desktop` abrem. Tem **um clone próprio deste repositório** em `MQL5/Experts/AlgoTradingLab`. |
| `~/.wine-mt5` | O antigo, mantido como reserva (build 6090). É onde **este** clone do repositório fica. |

Consequência: editar aqui não muda o que o MT5 em uso executa. É preciso
`git pull` no clone do prefixo novo e recompilar lá. Para saber o prefixo de um
MT5 aberto: `tr '\0' '\n' < /proc/<pid>/environ | grep WINEPREFIX`.

Outros fatos do ambiente:

- **O MT5 se atualiza sozinho** (LiveUpdate) ao abrir com internet. Em
  2026-09-12 passou de 6093 para 6182 sem ninguém pedir. Os executáveis
  mudam de data; o log do terminal registra `LiveUpdate ... new version`.
- **Som desligado** nos dois prefixos, por pedido do autor:
  `HKCU\Software\Wine\Drivers` com `Audio=""`. Não usar `PlaySound()` nem
  alerta sonoro no código.
- Logs do terminal, do tester e do agente saem em **UTF-16LE**. Sem
  `iconv -f UTF-16LE -t UTF-8` parecem binários. Ficam em `logs/`,
  `Tester/logs/` e `Tester/Agent-127.0.0.1-3000/logs/` da raiz do MT5.

## Compilar e testar pela linha de comando

**Compilar** (caminho relativo à raiz do MT5, `/log` sem argumento):

```bash
cd "/home/dark/.wine-mt5-novo/drive_c/Program Files/MetaTrader 5"
WINEPREFIX=~/.wine-mt5-novo wine MetaEditor64.exe /compile:"MQL5\Experts\AlgoTradingLab\ARIMA-GARCH\ARIMA_GARCH_EA.mq5" /log
iconv -f UTF-16LE -t UTF-8 "MQL5/Experts/AlgoTradingLab/ARIMA-GARCH/ARIMA_GARCH_EA.log" | grep -i "error\|Result:"
```

**Rodar pelo `/config:`** (script ou backtest). O `.ini` pode ficar em qualquer
lugar: `wine terminal64.exe '/config:Z:\caminho\arquivo.ini'`. Armadilhas, todas
já pagas:

- **`[Common]` com `Login=` e `Server=` é obrigatório.** Sem ele o terminal loga
  `tester not started because the account is not specified`. Sem `Password=`
  ele usa a senha gravada.
- **`ShutdownTerminal=1` não**: sob Wine ele derruba o terminal antes do
  `OnStart` do script. Rodar em background e encerrar depois com
  `WINEPREFIX=... wineserver -k`.
- **Script com `#property script_show_inputs` trava pelo `[StartUp]`**: a janela
  de parâmetros abre e espera um clique que ninguém dá, e o `OnStart` nunca roda.
  Por isso o `Import_B3_Custom` ficou meses sem importar nada.
- **`[StartUp]` precisa de `Symbol=` e `Period=`** para ter um gráfico onde
  anexar o script.
- O `launch-mt5.sh` testa `pgrep -f terminal64.exe`. Se o **seu** comando de
  shell contém esse texto, o launcher acha que o MT5 já está aberto e sai sem
  abrir nada.
- **Script pelo `[StartUp]` precisa de `[Experts]` com `AllowLiveTrading=1`.**
  Com `0`, o log diz `script ... loaded successfully` e o `OnStart` nunca roda:
  sem erro e sem saída. Parâmetros de script vão em `ScriptParameters=x.set`,
  com o `.set` em `MQL5\Presets\` (a pasta pode não existir; criar).
- **Símbolo personalizado só vai para o disco quando o terminal fecha
  normalmente** (`Bases/symbols.custom.dat`). Se o terminal for derrubado com
  `wineserver -k` logo depois do import, o histórico (`Bases/Custom/history/`)
  fica gravado, mas o tester responde `symbol X not exist`. Para fechar
  normalmente: `WINEPREFIX=... wine taskkill /im terminal64.exe` (sem `/f`).
  Para backtest, `wineserver -k` continua servindo.
- **O tester só entrega histórico a partir de 1º de janeiro do ano anterior
  ao início do teste.** Teste começando em 02/01/2025 enxerga ~250 barras.
  Com `Janela_Selecao=500` a seleção de ordens fica adiada por meses, sem erro
  (aparece `Selecao adiada` só no log). Por isso os experimentos usam 240.
- **Sem 100 barras de histórico antes da data inicial, o testador adia o
  início sozinho**, sem erro: só o log diz `start time changed to ... to
  provide data at beginning`. Símbolo com histórico desde 02/01/2008 começa o
  teste em 02/06/2008. Provável origem da contagem de Almeida (réplica v2,
  21/10/2026, INCERTEZAS item 74).
- **Importar com `PERFIL=AlgoLab`** (`importar.sh`): o perfil Default do autor
  está no limite de 100 gráficos e bloqueia o script; o `common.ini` dele é
  devolvido no fim.
- **Input que não está no `[TesterInputs]` NÃO vem do padrão do código**: vem
  de `MQL5/Profiles/Tester/ARIMA_GARCH_EA.set`, gravado automaticamente com os
  últimos valores usados. Em 21/09 um teste "com os padrões" rodou com
  Janela 500 e percentil 70 da semana anterior. Pelo `/config`, listar todos
  os inputs; pela interface, clicar em "Redefinir" na aba Entradas.
- **Na otimização, listar o input não basta: linha sem `||` herda do `.set` a
  marca de otimizar (`Y`) e a faixa.** Em 26/10/2026, depois de uma grade com
  `Limiar_Percentil=50||50||20||90||Y`, a grade seguinte com
  `Limiar_Percentil=50` também variou o percentil, e a C3 da PETR4 rodou 960
  passagens em vez de 312, sem erro nenhum. Toda linha numérica ou lógica de
  grade vai com a faixa explícita e `N` (`k=v||v||1||v||N`), e o `.set` é
  apagado antes de cada otimização (`janelas_240_500.sh`, função `explicitar`).
  Conferir a contagem de passagens de cada grade. A refação de 05/10 não foi
  afetada (688 passagens em toda janela, 344 na C4, conferido em 26/10).
- **Otimização refeita com os mesmos parâmetros vem do cache**
  (`Tester/cache/`) e o `OnTester` não roda: os CSVs de resultado não saem.
  Apagar o cache antes.

**Símbolos personalizados da B3.** `MQL5/Scripts/B3_Setup/Import_B3_Custom`
lê `MQL5/Files/B3_Historical/*.csv` e cria `PETR4_B3`, `VALE3_B3`... (14
papéis, D1, 26/04/2021 a 24/04/2026, 1248 barras) em `Bases/Custom`. O
resultado sai em `MQL5/Files/import_b3_resultado.txt`. Foi importado no prefixo
novo em 2026-09-12. O sufixo `_B3` evita colisão com o `PETR4` da corretora.

**Para backtest usar `PETR4_OFICIAL` (B3 COTAHIST, ver `dados/FONTES.md`).** Os `_B3`,
`_AJ`, `_AJL` e `_BRL` são das rodadas com Yahoo e estão superados. Os `_B3` tinham ainda
este defeito: foram criados com `SYMBOL_CHART_MODE_LAST`. Nesse modo o tester
atualiza só o preço "last" e deixa bid/ask parados no primeiro tick; patrimônio
e fechamento de posição usam bid, então **o lucro sai 0,00 com a posição aberta
o ano inteiro**. O importador foi corrigido para `CHART_MODE_BID` em
21/09/2026. Além disso, a definição deles provavelmente nunca foi gravada
(`symbols.custom.dat` não existia até 21/09; ver armadilhas acima).

**Os CSVs de `B3_Historical/` são preço BRUTO** (`auto_adjust=False` no
downloader), sem ajuste por proventos. Na PETR4 isso é grave: de 04/2021 a
04/2026 o preço foi de 23,78 para 47,16 (2,0×), mas o retorno total com
dividendos foi 6,8×. Cada data-ex aparece como uma queda de 5% a 14%, a
posição comprada perde o dividendo e a vendida ganha um dividendo que na vida
real pagaria. **O backtest do TG usa `PETR4_AJ`**: mesmos pregões, OHLC
multiplicado por `Adj Close / Close` do Yahoo (retorno total). O CSV está em
`MQL5/Files/B3_Ajustado/PETR4.csv` e em `dados/` neste repositório.

**Selic diária** (série 11 do SGS/BCB, % ao dia) fica em
`MQL5/Files/selic_diaria.csv`, também copiada em `dados/`. O EA a declara com
`#property tester_file` e a usa só na avaliação (`Desempenho.mqh`).

## Strategy Tester travado ("Waiting For Update") — diagnóstico de 2026-09-12

**Sintoma.** Clicar em Iniciar abre a janela de visualização com "Waiting For
Update" e nada acontece, nem com o modo visual desligado. Terminal e agente
ficam com 0% de CPU.

**Causa: o terminal não autenticava em nenhum servidor de negociação.** A conta
demo `1199505191` da `ClearInvestimentos-DEMO` autenticou até 17/06/2026 e passou
a dar `Invalid account` em 03/08/2026. **Não era a conta que tinha morrido, era a
senha**: em 12/09/2026 a senha foi trocada pelo site da Clear e a mesma conta
voltou a autenticar (`authorized on ClearInvestimentos-DEMO ... 57830 symbols`).
Todos os travamentos do tester nos logs são do período sem autenticação. Sem
servidor, o tester se comporta assim:

| Situação (sem autenticação) | O que o log mostra | O que acontece |
|---|---|---|
| Símbolo da corretora (EURUSD), teste iniciado pela interface | `common synchronization completed` na hora, e depois silêncio | Espera o servidor por **exatamente 0:08:20 (500 s)** e então segue com o histórico local: `EURUSD: load 477 bytes of history data to synchronize in 0:08:20.309` (12/09) e `0:08:20.480` (05/08). É um timeout fixo. Ninguém espera 8 min olhando "Waiting For Update", e por isso parecia travado para sempre. |
| Símbolo da corretora, teste pelo `/config` ou em modo visual | `testing of ...` e **nem** `common synchronization completed` | Ficou parado por 6 a 9 min até ser encerrado; o terminal envia ~83 KB ao agente e para. **Causa exata não determinada.** Só aconteceu sem autenticação. |
| Símbolo personalizado (`PETR4_B3`) | `tester not started because terminal is not synchronized with the trade server [connect status 0, 100]` | Recusa na hora. Com a rede cortada dá `[connect status 1, 100]`, a mesma recusa. |

Com a conta autenticada, o mesmo teste EURUSD sincroniza em `0:00:00.030`. As
mensagens de recusa existem nos executáveis 6090 e 6182, então isso não é
novidade de build. A anotação antiga de "Wine lento em loopback, ~2 KB/s" estava
errada: eram os 500 s de timeout divididos pelos poucos bytes transferidos.

**O que NÃO é a causa** (cada item testado em 2026-09-12 com o mesmo config,
e em todos o terminal parou no mesmo ponto). Não reabrir essas pistas:

| Suspeita | Teste | Resultado |
|---|---|---|
| Rede/loopback lento sob Wine | `ss -tni dst 127.0.0.1:3000` durante o travamento | RTT 0,2 ms, fila vazia, `app_limited`: o socket fica ocioso esperando o terminal enviar. |
| Modo visual | Mesmo teste com `Visual=0` | Trava igual. |
| ntsync (`/dev/ntsync`, que chegou com o pacote `ntsync-autoload` junto do wine-staging 11.16 em 28/08) | MT5 dentro de `bwrap --bind <arquivo-sem-permissão> /dev/ntsync`; o `wineserver` ficou com 0 descritores de ntsync | Trava igual; as threads só trocam `ntsync_schedule` por `anon_pipe_read`. |
| Wine 11.16 | Wine 11.9 oficial (Arch Linux Archive) extraído localmente, rodando numa cópia do prefixo | Trava igual. |
| Build 6182 | Prefixo antigo, build 6090 | Trava também. |

**Conserto: manter a conta autenticada.** O `Invalid account` da Clear era
senha expirada. Para trocar: site da Clear → Plataformas e serviços → Contratos
ativos → Automações → MetaTrader 5 (Simulador) → **Recuperar senha**. O
"Resetar limite" ao lado só zera o saldo fictício e não resolve. Depois, no MT5:
Arquivo → Conectar-se à conta de negociação, com o mesmo login. Se a Clear falhar
de vez, uma demo da MetaQuotes (Arquivo → Abrir uma Conta) também serve.

- Os símbolos da corretora (EURUSD, PETR4 etc.) baixam o histórico do servidor.
- O backtest do TG pode usar `PETR4_B3`: histórico local vindo do CSV, que não
  muda se a corretora mexer nos dados. Mas ele também exige terminal
  autenticado.

**Se o tester voltar a travar, a primeira coisa a olhar é o log do terminal**:
`authorized on ...` significa que a conexão está ok; `authorization ... failed`
significa que a senha expirou de novo.

```bash
iconv -f UTF-16LE -t UTF-8 "$HOME/.wine-mt5-novo/drive_c/Program Files/MetaTrader 5/logs/$(date +%Y%m%d).log" | grep -E "authoriz|not synchronized|tester not started"
```

**Armadilhas da interface do tester** (vistas em 12/09/2026):

- **A janela de execução em tempo real só abre com a caixa "modo visual"
  marcada** (aba Configurações, embaixo). O estado fica em `Config/terminal.ini`,
  seção `[Tester]`, `Visualization=`. Estava em `0` depois dos reinícios. Pelo
  log dá para conferir: teste visual aparece como `visual testing of`, o normal
  como `testing of`.
- **A lista de símbolos do tester mostra os 57 830 símbolos do servidor da
  Clear** (ações, BDRs como `A1AP34`, opções...) e não tem filtro. Digitar o
  código direto no campo (ex.: `PETR4`). Os personalizados ficam em
  `Custom\B3` (`PETR4_B3`).

## Validação numérica já feita

> **Fora do texto do TG desde 18/10/2026, a pedido do autor**: os testes do
> código (recuperação de parâmetros, ADF em séries artificiais, ADF/Ljung-Box na
> PETR4) fogem do escopo apresentado. Os números abaixo continuam valendo e
> podem voltar ao texto depois; o trecho antigo está em
> `notas/rascunhos/antes_tirar_validacao_2026-10-18/`. **Não reinserir sem
> pedido.**

Recuperação de parâmetros em dados sintéticos com verdade conhecida:

| | Verdadeiro | Estimado |
|---|---|---|
| ARMA(1,1) φ₁ / θ₁ | 0,600 / 0,400 | 0,5799 / 0,4105 |
| AR(2) φ₁ / φ₂ | 0,500 / −0,300 | 0,4815 / −0,2891 |
| GARCH ω / α / β | 1,00e-5 / 0,090 / 0,890 | 1,17e-5 / 0,0825 / 0,8941 |

ADF discrimina corretamente (arquivo `dados/verificacao/validacao_numerica_2026-10-05.txt`,
depois da correção do ADF por amostra comum, INCERTEZAS item 46): passeio
aleatório −1,41 (não rejeita), AR(1) φ=0,5 −26,87 (rejeita), primeira diferença
do passeio −46,19 (rejeita). Antes da correção eram −1,48 / −17,92 / −46,19.

Em PETR4_OFICIAL (B3, 500 barras até 18/09/2026), mesmo arquivo: ADF log-preço
−0,95 (não estacionário), ADF log-retorno −6,14 (estacionário). ARIMA(1,1,1) →
GARCH(1,1) dá volatilidade diária prevista de 1,643%. Ljung-Box nos resíduos
padronizados ao quadrado: p = 0,75 → o GARCH capturou a heterocedasticidade.
Ljung-Box nos resíduos do ARIMA(1,1,1): p = 0,009, ou seja, ainda sobra
autocorrelação nessa especificação — é o argumento a favor da busca em grade em
vez de fixar (1,1,1). Reproduzir: `ferramentas/scripts/validar.sh` (o script
`ferramentas/ValidacaoAlgoLab.mq5` agora é versionado). A versão de 29/09 usava
a série da corretora (0,12 / −20,83 / p = 0,34) e está superada. E d não é
sempre 1: INCERTEZAS, item 34.

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

## Backtest otimizado no Strategy Tester (21/09/2026) — resultado principal

> **SUPERADO pela rodada 3** (dados do Yahoo, com lacunas). Números desta
> seção não vão para o TG. Ver `dados/resultados/rodada3_b3_oficial/RELATORIO.md`.

**Por que o teste de 14/09 deu "−R$ 50 em um ano".** Foi rodado em **PETR4 M1**
(99.386 barras de um minuto, com janela de 250 minutos), com 100 ações
(~R$ 3 mil) numa conta de R$ 10 mil, e o GARCH vetou 96% dos sinais. Nenhum
desses números diz nada sobre o modelo em D1.

**Configuração do experimento:**
- `PETR4_AJ` (ajustado por proventos), D1, modelo "somente preços de
  abertura", depósito de R$ 100 mil, alavancagem 1:1.
- Volume = 95% do patrimônio (`ModoVolume=VOLUME_CAPITAL`).
- Custo B3 de 0,03% por lado. Caixa parado rendendo Selic diária, via
  `Desempenho.mqh`.
- **Calibração** 02/05/2022 a 30/12/2024; **validação** 02/01/2025 a
  24/04/2026, nunca usada para escolher nada.
- Grade completa de 13.824 passagens por período (1.920 configurações
  distintas): GARCH on/off, 4 estratégias, percentil 50/70/90,
  k 0,05/0,15/0,25, janela 120/240, limiar de sinal 0/0,1%/0,2%,
  só-compra, zerar no veto, reseleção mensal, ordens auto × (1,1,1),
  com/sem constante.
- Critério de escolha declarado antes: maior excesso sobre a Selic na
  calibração (valor de retorno do `OnTester`).

**Configuração escolhida (hoje é o padrão do EA):**
- ARIMA com ordens automáticas **sem constante**, reseleção a cada 21 barras,
  janela 120.
- GARCH(1,1) como **filtro, percentil 50, sem zerar no veto**.
- Só compra, sem limiar de sinal.

|  | Calibração | Validação | Período inteiro |
|---|---|---|---|
| ARIMA-GARCH escolhido | +212,9% · DD 10,7% · 77 op. | **+75,1%** · DD 10,2% · Sharpe 1,46 | +355,6% · DD 18,7% |
| Mesmo ARIMA sem GARCH | +38,7% · DD 20,8% · 174 op. | +42,8% · DD 12,3% · Sharpe 0,81 | +89,8% · DD 20,8% |
| Selic | +36,1% | +19,1% | +62,2% |
| Buy-and-hold PETR4 (c/ proventos) | +178,8% · DD 38,5% | +46,2% · DD 20,0% · Sharpe 0,72 | +310,3% |

(Retornos líquidos de custo, com o caixa parado na Selic; Sharpe do excesso
diário sobre a Selic, anualizado.)

Esses números são da 1ª rodada, em `PETR4_AJ` (lote de 100). Na 2ª rodada, em
`PETR4_AJL` (mesma série ×10, lote de 1), a mesma configuração deu na
validação **+87,2% e Sharpe 1,66** (ARIMA puro: +50,5% e 1,00). A diferença
vem só do arredondamento e do tamanho do lote, que mudam alguns sinais. Isso
também é um indício de fragilidade. **Para o texto, usar os números da 2ª
rodada**, que são os que têm gráficos e testes.

**Leitura que precisa acompanhar esses números:**

1. **O ADF+AIC encontra quase um passeio aleatório.** Com constante, a grade
   escolhe ARIMA(0,1,0): a previsão é só a média da janela, e o EA vira
   buy-and-hold (1 operação). Sem constante, sobram ordens baixas, como (1,1,0)
   e (0,1,1), com coeficientes pequenos. É evidência a favor da forma fraca da
   hipótese de mercado eficiente, e o texto deve dizer isso.
2. **O ganho do GARCH não vem de fugir da turbulência.** O veto bloqueia a
   ordem, não a posição. Com `ZerarNoVeto=false`, dia agitado = carteira
   congelada, e os sinais do ARIMA são ignorados justamente quando são mais
   ruidosos. O giro cai de 174 para 77 operações, com menos custo e menos
   whipsaw. As versões que **zeram** no veto (fogem da turbulência) ficaram
   perto de zero na validação.
3. **Efeito médio do GARCH na grade inteira** (pares com o mesmo ARIMA):
   - reduziu o drawdown em 87% dos pares na calibração e em 61% na validação;
   - reduziu a volatilidade em 87% e 69%;
   - **aumentou o retorno em só 34% dos pares na validação**; a mediana do
     filtro foi −10 p.p.

   Em geral, o GARCH é ferramenta de risco, não de retorno. A configuração
   escolhida é a exceção, e o mecanismo dela é o do item 2.
4. **Persistência fraca entre períodos.** Spearman entre o excesso na
   calibração e na validação = 0,18. O decil mais alto da calibração teve
   mediana de +13 p.p. na validação, e o mais baixo, −4 p.p. Parte do
   resultado da configuração escolhida é sorte da seleção entre 1.920
   candidatas. O que depõe a favor é que ela está num **platô**: as vizinhas
   (percentil 70/90, filtro+targeting) deram de +39 a +59 p.p. na validação.
5. **A validação depende de UMA operação.** Das 36 saídas, a compra de
   20/01/2026 (R$ 30,26), mantida até o fim do teste (R$ 44,97), respondeu
   por R$ 51,5 mil dos R$ 65,6 mil de lucro bruto (78%). O filtro congelou a
   posição durante a alta volátil de 2026; o ARIMA puro entrou e saiu várias
   vezes. **Sem ela, a validação fica em torno de +25%**: acima da Selic
   (+19%), abaixo do buy-and-hold (+46%). No período inteiro, as 3 maiores
   operações somam 59% do lucro. Esse é o dado mais importante para calibrar o
   tom do texto.
6. **Significância.** Sharpe de 1,46 em 1,3 ano dá t ≈ 1,7 (p ≈ 0,05
   unilateral) **contra a Selic**. Contra o buy-and-hold não foi testado
   formalmente. Não escrever que "supera o mercado" como fato estabelecido.
7. **Vender a descoberto destrói resultado** (mediana −33 p.p. na calibração)
   num período de alta da PETR4 com dividendos altos. Só-compra também é o
   realista para pessoa física (vender a descoberto exige aluguel).
8. **Um ativo, um regime.** A PETR4 subiu 3× no período; bater a Selic foi
   fácil (62% das configurações bateram). A comparação que mede habilidade é
   contra o buy-and-hold.

Resultados brutos em `dados/backtest-2026-09-21/`: as 1.920 configurações com
calibração × validação lado a lado, o resumo da análise, a grade, a config
escolhida e os relatórios do MT5 (htm + curva png) da escolhida e do gêmeo sem
GARCH, nos três períodos. A análise em si foi feita com pandas, descartável e
fora do repositório (regra nº 1).
Para refazer: grade em `[TesterInputs]` com `Optimization=1`,
`OptimizationCriterion=6`, cache apagado. Cada passagem grava uma linha em
`Common/Files/AlgoLab/` (pasta comum dos agentes, em
`drive_c/users/dark/AppData/Roaming/MetaQuotes/Terminal/Common/Files`).
Roda a ~10 passagens/s.

## Comparação com Almeida (2016) e entre modelos (21/09/2026, 2ª rodada)

> **SUPERADO pela rodada 3** (dados do Yahoo, com lacunas). Números desta
> seção não vão para o TG. Ver `dados/resultados/rodada3_b3_oficial/RELATORIO.md`.

Os dois EAs (ARIMA_GARCH_EA e MediasMoveis2) usam o mesmo `Desempenho.mqh`.
Com o input `Rotulo` preenchido, o EA grava `metricas_<rotulo>.csv` e
`curva_<rotulo>.csv` (diária, base 1) em `Common/Files/AlgoLab/`. O script
`MQL5/Scripts/CompararModelos.mq5` (fora do repo) cruza as curvas dois a dois
com `CompararCurvas()`: diferença de Sharpe (Memmel) e teste t pareado do
retorno diário.

**Métricas** (todas sobre o retorno diário em excesso sobre a Selic):
- **Sharpe**: a Selic é o ativo livre de risco, então Sharpe > 0 significa
  que a estratégia rendeu mais que a Selic por unidade de risco. A própria
  Selic tem Sharpe 0.
- **t e p do Sharpe**: erro-padrão de Lo (2002).
- **Sortino**: só penaliza os dias abaixo da Selic.
- **Calmar**: CAGR / drawdown máximo.
- **alfa/beta**: regressão contra o excesso do buy-and-hold.
- **z (SR − SR_bh)**: Jobson-Korkie-Memmel.

Tudo foi conferido por recálculo independente a partir das curvas (diferença
0,0000).

**Cenários:**
- **A, réplica do Almeida**: `PETR4_BRL` (preço bruto), R$ 50 mil, volume fixo
  (100 ações em 2007–11 e 1.000 em 2013–16), sem custo. A MM é long-short,
  como a dele.
- **B, justo**: `PETR4_AJL` (ajustado), R$ 100 mil, 95% do patrimônio, só
  compra para os três modelos, custo B3 e caixa na Selic.

Configuração de ARIMA/ARIMA-GARCH = a escolhida na calibração 2022–24, **sem
reotimizar**; nos períodos do Almeida é um teste fora da amostra no passado.

Cenário A, lucro em R$ (Almeida reportou +10.430 em 2013–16, 38 operações; e
−2.542 em 2007–11, 52 operações):

| | MM c/ SL50/TP100 | MM sem SL/TP | ARIMA | ARIMA-GARCH |
|---|---|---|---|---|
| 2007–2011 | +677 | −60 | −2.135 | −769 |
| 2013–2016 | +7.330 | **+11.980** (49 op.) | −2.370 | −3.170 |

A réplica da MM chega perto do número dele em 2013–16, o que valida a
reimplementação e os dados.

Cenário B, Sharpe sobre a Selic (p unilateral de Sharpe > 0):

| Período | Selic | B&H | MM | ARIMA | ARIMA-GARCH |
|---|---|---|---|---|---|
| 2007–11 | +65,5% | −1,2% (SR −0,03) | −0,14 | −0,45 | −0,20 |
| 2013–16 | +53,7% | −17,4% (SR 0,01) | **0,57** (p 0,13) | −0,16 | −0,16 |
| 2022–24 (calib.) | +36,1% | +178,7% (SR 0,94) | 0,75 | 0,18 | **1,55** (p 0,01) |
| 2025–26 (valid.) | +19,1% | +46,2% (SR 0,70) | 0,31 | 1,00 | **1,66** (p 0,03) |

GARCH × ARIMA pareado (mesmos dias):
- p do Sharpe: 0,46 (2007–11), 1,00 (2013–16), 0,01 (calibração) e 0,24
  (validação).
- O GARCH nunca foi pior de forma significativa. Só foi melhor de forma
  significativa no período usado para escolher a configuração.

**Leitura:**
- Nos períodos do Almeida **nenhum modelo estatístico bateu a Selic**. A Selic
  rendeu +54% a +66% com a PETR4 de lado ou caindo.
- A configuração escolhida é boa em 2022–26 e **não generaliza para
  2007–16**: depende do regime.
- A MM do Almeida foi a melhor em 2013–16 e a pior em 2022–24.
- Resultados em `dados/comparacao-2026-09-21/`; gráficos (pgfplots, lendo as
  curvas) em `tg/graficos/`.

**Armadilhas desta rodada:**
- **Tick com mais de 2 casas vira zero**: símbolo com `DIGITS=4` teve todo
  negócio com lucro 0,00. Reescalar o preço (×10) e manter 2 casas.
- **O agente guarda histórico próprio** em `Tester/bases/<servidor>/history/<símbolo>/*.hcs`.
  Depois de reimportar um símbolo, apagar essa pasta e `Tester/cache/`, senão o
  tester mistura a série nova com a antiga. Aqui ele juntou 2005–23 reescalado
  com 2024–26 antigo, e o buy-and-hold saiu −72%.
- O `PETR4_BRL` só contabilizou lucro depois de reimportado e com o cache
  limpo.
- No zsh, `rm` com um glob sem correspondência aborta o comando INTEIRO, e
  `set -- $var` não separa palavras. Os scripts de bateria rodam em bash.
  **Isso vale também para laço escrito direto na linha de comando**: sem
  separação de palavras, `set -- $cfg` deixa `$2` vazio, o `sed` do `rodar.sh`
  grava `Volume_Fixo_Input=` sem valor e o teste roda com volume errado, sem
  erro nenhum. Pôr o laço num `.sh` e chamar com `bash`.

## Refação de 05–06/10/2026 — RESULTADO VIGENTE

Todos os experimentos do ARIMA e do ARIMA-GARCH foram refeitos com o EA
corrigido (erros com d = 0 e no ADF; `notas/INCERTEZAS.md`, itens 43 a 47).
Pasta `dados/resultados/refeito_2026-10-05/` (LEIAME, PROTOCOLO,
`analise_grades.txt`, `testes/comparacoes.csv`). **Os números das seções
"Rodada 3", "Rodada 4" e "Rodada 5" abaixo são do EA antigo** e servem só de
histórico. O Cap. III já está com os números novos.

Resumo do que mudou (INCERTEZAS, item 52): a proteção se manteve (queda menor
que a gêmea nos 11 pares); a significância caiu (GARCH × gêmea 1 de 11; contra
a Selic, nenhum p < 0,05); o +325% de 2013–2016 e o p = 0,041 de 2005–2026
sumiram porque a calibração corrigida escolheu outras configurações.

**Auditoria de 12/10/2026 (INCERTEZAS, item 55):** Cap. III conferido número a
número, tudo bate. Corrigido no texto: a comparação com a compra e manutenção e
com as médias móveis é **sem proventos** (`bh_preco`, `ret_selic`). Com
proventos (B3 desde 21/10/2026, INCERTEZAS item 75), em 2017–2024, compra e manutenção +777,9%, MM +396,0% e ARIMA +356,6% passam a GS
(+353,0%); GARCH × gêmea não muda de sentido. **Ao comparar com a PETR4 no texto,
dizer sempre que é pela variação do preço.**

**Foco do texto mudou para o risco (13/10/2026, INCERTEZAS item 57), pedido do
autor:** volatilidade e queda máxima são as medidas centrais; Sharpe e Selic são
referência complementar, nunca meta. Volatilidade comparada pelo teste de
Pitman-Morgan (`CompararCurvas` em `Desempenho.mqh`, colunas `vol_a`, `vol_b`,
`r_pm`, `t_pm`, `p_pm`; saída em `refeito_2026-10-05/testes/comparacoes_risco.csv`).
GARCH oscilou menos que a gêmea (11/11) e que as médias móveis (todas as janelas),
p < 0,001; ARIMA isolado × médias móveis sem padrão. Seletividade
(`seletividade.sh`): GARCH 0,65–0,91 em 11 de 12, demais 0,87–1,14.

**Nomes no texto desde 19/10/2026 (INCERTEZAS item 68), pedido do autor:**
**ARIMA-GARCH Sharpe** (GS) e **ARIMA-GARCH Calmar** (GC); "versão A/B" (de
14/10, item 58) saiu. O nome é o critério da escolha, não o resultado no teste.
Gêmea = grupo de controle.

**Intervalo de confiança fora do escopo desde 21/10/2026 (INCERTEZAS item 71),
pedido do autor**: o texto só usa filtro e ajuste da posição (volatility
targeting, com Harvey et al., 2018, no Cap. I). Grade do texto = 312 (rodada 4:
624 e 14.976 simulações). A PETR4 não muda; nas outras ações, scripts com
`SEM_IC`. **Desde a noite de 21/10 a forma saiu também do código** (enum, input `K_Confianca` e coluna das métricas; `FILTRO_E_TARGETING` continua = 3; INCERTEZAS item 75). Resultados antigos com `Estrategia=2` não são reproduzíveis com o EA atual.

**Capítulos separados desde 14/10/2026 (INCERTEZAS item 59), pedido do autor:**
Cap. II diz só COMO (definições de versão A/B e gêmea ficam no plano
experimental, NÃO num quadro de termos); Cap. III diz só O QUE DEU, uma seção por
pergunta (validação → réplica → risco → mecanismo → retorno), sem repetir método
nem limitações (estas ficam só nas considerações). Detalhe vai para o Apêndice B.
Tom do PTG: frase direta, uma ideia por parágrafo, a tabela guarda os números.
**Desde a noite de 14/10 (INCERTEZAS item 60), molde do Almeida**: Cap. III por
período (crise / fora da crise / recente / pandemia), robôs lado a lado;
estatística formal (Pitman-Morgan, testes de Sharpe) só na ÚLTIMA SEÇÃO do Cap. III
(o Apêndice B foi extinto em 15/10, a pedido do autor); sem "gêmea" nem "razão de
seletividade" no corpo; nas tabelas e gráficos com dados nossos, "médias móveis
reproduzidas", e "Almeida (2016)" só para os números dele. Sem "equação (x.y)" no
texto. **Ilustrações em `[htbp]` com placeins desde 22/10/2026** (pedido do autor,
menos espaço em branco). **A regra das figuras fixas (`[H]`, de 15/10) foi
retirada pelo autor em 22/10 e o pacote `float` saiu**: não voltar a ela sem pedido
(INCERTEZAS item 76). **Cap. III com 3.3.1/3.3.2 (2008) e 3.5.1/3.5.2 (2020) desde 22/10**: o ano da crise é recorte do mesmo teste; `\FloatBarrier` antes de cada "O ano de". **Build (15/10, INCERTEZAS 61):** se o pacote `float` voltar, ele tem de vir DEPOIS
dos `\newfloat` do Quadro e do Gráfico no `main.tex`; o `Makefile` não depende dos
PDFs dos gráficos (depois do `graficos_cru.sh`, `touch main.tex`); e o `tg/.latexmkrc` faz a
compilação automática do VS Code rodar o `citacoes_abnt.pl` (sem ele, as citações
saem em caixa alta). Régua: "não pode parecer mestrado". Mudanças novas entram
em camadas pequenas, uma por vez, com o autor digerindo antes da próxima.

**Preparação da entrega à orientadora (18/10/2026), a pedido do autor:** título
novo ("Desenvolvimento e comparação de modelos de negociação algorítmica:
ARIMA-GARCH e médias móveis"); validação do código fora do texto (ver "Validação
numérica já feita"); seção de verificação estatística oculta com
`\iffalse` e **removida de vez em 21/10/2026** (pedido do autor; cópia em
`notas/rascunhos/antes_remover_estatistica_2026-10-21/`); **seção de camadas do
Cap. III (custos, Selic, proventos) também removida em 21/10/2026** (voltou
em 27/10/2026 com os proventos da B3, a pedido do autor depois da leitura da
orientadora; INCERTEZAS item 80): o Cap. III
mostra só o resultado bruto, e custo e Selic aparecem no Cap. II apenas como
parte da escolha das configurações (INCERTEZAS item 75); em 22/10/2026 as
hipóteses foram reescritas e **voltaram às do PTG no mesmo dia**, a pedido do
autor (INCERTEZAS item 76): não trocar as hipóteses de novo sem pedido; caderno de
delineamentos da FATEC-ID citado e depois retirado em 19/10 (o autor não quer
referência da própria faculdade); `citacoes_abnt.pl`
passou a ler o `.bbl` inteiro (nome longo quebrava em duas linhas e saía em caixa
alta). Os 252 dias continuam sem fonte: nenhuma obra do projeto traz a convenção,
nem a página da Selic do BCB.

**Bateria de 15/10/2026 (INCERTEZAS item 62; NÃO está no TG ainda):**
`dados/resultados/bateria_2026-10-15/` (LEIAME, PROTOCOLO, resumo.txt). Critério
único = fator de recuperação do MT5 (coluna `fator_recuperacao_mt5`, gravada pelo
EA desde 15/10), resultado principal na camada 1 (crua), pandemia 2017-2019 →
2020-2021. Máxima verossimilhança no ARIMA (`MetodoARIMA=1`, `//@omitir`)
implementada e rejeitada pela validação; o padrão segue Hannan-Rissanen.
Scripts: `bateria_2026_10_15.sh`, `escolher_rf.sh`, `resumo_bateria.sh`,
`recorte_ano.sh` (COL=puro), `validar_mv.sh`. **Armadilha paga de novo:** rodar
`rodar.sh` com `$cfg` direto no zsh não separa as palavras e o teste roda com a
base (a 1ª regressão "falhou" por isso); sempre dentro de `bash`.

**GARCH com erros t de Student (13/10/2026, INCERTEZAS item 56; NÃO está no TG):**
input `DistribuicaoGARCH` (padrão `DIST_NORMAL`, marcado `//@omitir`, o
Apêndice A não muda). ν entra no otimizador como η = 1/ν ∈ [0,005; 0,45].
Validado em séries sintéticas e com regressão byte a byte do caminho normal.
Trocando só a distribuição nas 12 configurações do TG: pior em 9 de 12
(retorno, queda e Sharpe), nada significativo, proteção contra a gêmea mantida.
Resultado em `dados/resultados/garch_t_2026-10-13/`. A métrica grava
`DistribuicaoGARCH` e `nu_medio` em duas colunas novas.

Ferramentas novas, todas versionadas e conferidas contra os resultados antigos:
`escolher.sh` (critério do protocolo), `parear.sh`, `analisar_grades.sh`
(substitui o pandas), `anual.sh`, `resumo_testes.sh`, `comparar.sh` +
`ferramentas/CompararModelosEA.mq5` (teste pareado rodando **no testador**, sem
gráfico), `refazer_calibracoes.sh` e `refazer_testes.sh` (a refação inteira,
~2 h).

**Armadilhas desta refação:**
- **Glob em Common pega arquivo velho.** `metricas_L1_*` trouxe junto os
  `L1_GF/GT/AR` de 30/09. Copiar só os rótulos rodados na execução.
- **Perfil do terminal com 100 gráficos** bloqueia todo script por `[StartUp]`
  ("open charts limit reached", sem erro visível). INCERTEZAS, item 54.
- **`sort -g` no locale pt_BR** espera vírgula decimal e ordena errado a saída
  do awk. Usar `LC_ALL=C sort`.

## Rodada 3 (22/09/2026) — histórico (EA antigo)

Relatório completo: `dados/resultados/rodada3_b3_oficial/RELATORIO.md`. O
protocolo foi escrito antes dos resultados, em `PROTOCOLO.md`.

**Montagem:**
- Série `PETR4_OFICIAL` (B3 COTAHIST, só desdobramentos). Selic do BCB.
  Proventos do Yahoo só na camada 4.
- Grade de 344 configurações distintas, calibrada nos 3 anos anteriores a cada
  teste. Testes em T1 = 2007–2011, T2 = 2013–2016, T3 = 2025–26/09/2026.
- Escolha por maior Sharpe e por maior Calmar na camada 3 (custos + caixa na
  Selic).

**Conclusões:**
1. **O ARIMA-GARCH protege nas crises**: queda máxima de 7–26%, contra 43–52%
   do ARIMA, 38–58% da MM e 67–83% da PETR4. Em 2008 fez +4,8% com a ação em
   −47,3%. Isso vale para a maioria das configurações, desde que o GARCH
   **reduza** a posição (targeting ou zerar no veto). O filtro que só congela a
   posição não protege.
2. **Raramente supera a Selic**: só GS em T2, com Sharpe 0,80 e p = 0,056. Essa
   configuração foi escolhida com Sharpe negativo na calibração.
3. **ARIMA-GARCH × ARIMA**: risco menor nos três períodos; Sharpe
   significativamente melhor só em T2.
4. **× MM de Almeida**: nenhuma diferença de Sharpe significativa. A MM ganha
   nas retomadas fortes (2016) e perde nas quedas.
5. **Escolher pelo retorno não persiste** (Spearman do Sharpe ≈ 0); pela
   segurança persiste em parte (Calmar 0,28–0,41).

Gráficos em `tg/graficos/rodada3/`: `curva_T*.pdf` (patrimônio e queda) e
`anual_T*.pdf` (retorno por ano).

**Armadilhas novas:**
- **Importador**: o modo de cálculo precisa vir ANTES do valor do tick. Senão,
  na 1ª importação de um símbolo novo, o tick fica zerado e todo negócio sai
  com lucro 0,00. Corrigido em 22/09.
- **Script pelo `[StartUp]`** às vezes nem carrega sem `Symbol=`/`Period=`,
  depois de vários encerramentos forçados. Sempre incluir.
- **Arquivo de dados com comentário**: ler linha a linha
  (`CDesempenho::LerSerie`). Lendo campo a campo em modo CSV, uma linha com
  outro número de campos desalinha o arquivo inteiro. Foi o que fez os
  proventos saírem zerados.
- **Input repetido no `[TesterInputs]`**: vale a PRIMEIRA ocorrência. Um
  `Rotulo=` vazio herdado da grade apagou o rótulo acrescentado depois.
- **Grade com parâmetros irrelevantes** multiplica passagens idênticas (9.216
  para 344 distintas). Usar sub-grades, uma por estratégia
  (`dados/resultados/rodada3_b3_oficial/grades/*.txt`).
- **Símbolo personalizado novo precisa ser importado DUAS vezes.** Na primeira
  importação o valor do tick não cola e todo negócio sai com lucro 0,00; na
  segunda funciona. Reordenar as propriedades no importador não resolveu
  (testado em 22 e 23/09). Depois de reimportar, apagar `Tester/cache/` e
  `Tester/bases/*/history/<SIMBOLO>`.
- **Fator de cotação do COTAHIST**: até 2004 várias ações eram cotadas por lote
  de mil (campo 211-217 = 1000) e a mudança veio junto com grupamento. Conferir
  esse campo antes de usar um ativo; se não for 1 em toda a série, escolher
  outro (ver `dados/FONTES.md`, item 9).
- **`rodar.sh` descartava input que não existisse no arquivo base.** O laço só
  fazia `sed` de substituição: chave nova (ex.: `Arquivo_Traco=`) não casava com
  nada, o `.ini` saía sem ela e o EA usava o padrão — **sem erro nenhum**. É a
  mesma família do `Volume_Fixo_Input=` vazio de 28/09. Corrigido em 30/09: agora
  substitui se existe e **acrescenta** se não existe. Ao ver um input novo não
  fazer efeito, conferir primeiro se ele chegou ao `[TesterInputs]`.
- **O scratchpad da sessão é apagado na virada do dia.** Scripts de experimento
  ficam em `ferramentas/scripts/` (versionados); só os `.ini` e logs ficam em
  `/tmp/algolab-trabalho`.

## Rodada 4 (24/09/2026) — robustez em 4 ativos e venda a descoberto — histórico (EA antigo)

Resultados em `dados/resultados/rodada4_multiativos/`. Mesmo protocolo da
rodada 3, com quatro ativos (PETR4, VALE3, USIM5, POMO4) e a venda a descoberto
como dimensão da grade: 688 configurações por janela, 24 janelas, 16.512
passagens.

**1. O GARCH protege, e isso se repete nos quatro ativos** — desde que a
variante REDUZA a posição (targeting ou zerar no veto):

| | 2007–2011 | 2013–2016 | 2025–2026 |
|---|---|---|---|
| reduziu a queda máxima em | 85–93% dos pares | 93–98% | 51–96% |
| mediana da redução | −17 a −31 p.p. | −19 a −40 p.p. | 0 a −22 p.p. |
| efeito no retorno (mediana) | +7 a +38 p.p. | +33 a +41 p.p. | +1 a +16 p.p. |
| efeito no Sharpe (mediana) | ≈ 0 | ≈ 0 | ≈ 0 |

As variantes que só congelam a posição não protegem (mudam a queda máxima em
~50% dos casos, para os dois lados).

**2. Venda a descoberto não ajuda.** Mediana pior em 11 dos 12 casos
(ativo × período), melhora em 2% a 46% dos pares, aumenta a queda máxima e
levou 0,4%–0,8% das configurações à ruína nas crises. Única exceção: POMO4 em
2013–2016. Isso responde à pergunta "o modelo não deveria lucrar na baixa
vendido?": com o ARIMA acertando direção quase no nível do acaso, operar
vendido dobra a exposição ao erro.

**3. Auditoria (24/09).** Conferido e passou: histórico dentro do MetaTrader
idêntico aos CSVs nos 4 ativos; passagem da grade = backtest individual =
recálculo externo em 4 configurações sorteadas; Selic íntegra; séries
reconstruíveis a partir das linhas originais da B3. Dois erros achados e
corrigidos estão em `notas/INCERTEZAS.md` (itens 21 e 22).

## Rodada 5 (30/09/2026) — períodos longos e a primeira significância — histórico (EA antigo; a significância não sobreviveu à refação)

Relatório: `dados/resultados/rodada5_periodos_longos/LEIAME.md`. Preencheu dois
buracos: **2017–2024 nunca havia sido testado** com dados oficiais, e nunca houve
teste de período único longo. Configuração fixa declarada antes, não reotimizada
dentro do período.

| | anos | retorno | Selic | B&H | Sharpe (p) | queda máx. |
|---|---|---|---|---|---|---|
| 2005–2026 ARIMA puro | 21,3 | +6,0% | +795,8% | +298,8% | −0,19 (0,81) | 82,4% |
| 2005–2026 **GARCH filtro** | 21,3 | **+3.780,7%** | | | **0,38 (0,041)** | 56,4% |
| 2005–2026 GARCH filtro+targeting | 21,3 | +543,0% | | | −0,11 (0,70) | **27,8%** |
| 2005–2026 MM | 21,3 | +985,2% | | | 0,18 (0,20) | 67,5% |
| 2017–2024 ARIMA puro | 7,9 | −43,8% | +86,1% | +143,6% | −0,31 (0,81) | 76,5% |
| 2017–2024 GARCH filtro | 7,9 | +154,6% | | | 0,29 (0,21) | 57,6% |
| 2017–2024 GARCH filtro+targeting | 7,9 | +118,0% | | | 0,26 (0,23) | **14,1%** |
| 2017–2024 MM | 7,9 | +90,4% | | | 0,17 (0,32) | 36,7% |

**Como escrever isso sem exagerar:**
1. **É o primeiro p < 0,05 contra a Selic do projeto**, mas a significância vem
   do **tamanho da amostra**: Sharpe 0,38, t = 1,74, ~5.300 dias. Em T2 (4 anos)
   o Sharpe foi 0,80 com p = 0,056. Sempre reportar Sharpe e p juntos.
2. **Contra o buy-and-hold continua sem significância**: z = 1,46, p = 0,14.
3. **79,5% do retorno de 21 anos vem de 5 anos** (2018, 2016, 2006, 2005, 2026);
   2018 sozinho vale 24,6%. Não é vantagem distribuída.
4. **Retorno e proteção são variantes diferentes e opostas.** O filtro puro rende
   e não protege (56,4% de queda); o filtro+targeting protege e não rende
   (27,8%, abaixo da Selic em 21 anos). Em 2017–2024: 14,1% contra 57,6%.
5. **O achado mais forte não é sobre a Selic**: o mesmo ARIMA deu +6,0% em 21
   anos e −43,8% em 8 anos; com o GARCH ligado, +3.780,7% e +154,6%. Uma chave.
6. A configuração foi escolhida em 2010–2012, **dentro** de L1 (3 de 21 anos).
   L2 (2017–2024) é posterior à calibração e é o teste mais limpo dos dois.

## O trabalho de Almeida (2016) lido e replicado (28/09/2026)

O PDF original foi obtido pelo autor e está arquivado em
`bibliografia/pdfs/Almeida-2016.pdf`. Dados bibliográficos, configuração dos testes dele,
algoritmo do anexo e todos os números que ele relata estão em `dados/FONTES.md`,
item 7. Três coisas mudaram com a leitura:

1. **O título está errado no `.bib`.** O trabalho se chama **"Técnicas de
   previsão da bolsa com MetaTrader 5"** (FATEC Indaiatuba, Tecnologia em Banco
   de Dados, junho/2016). Corrigir `tg/referencias.bib`.
2. **Almeida não usou ARIMA.** ARCH/GARCH aparecem só na lista de siglas e na
   sugestão de trabalhos futuros — que é a origem deste TG. A tabela do
   `cap1-fundamentacao.tex` que atribui ARIMA a ele precisa ser corrigida.
3. **O período fora de crise é 22/05/2013 a 24/05/2016**, não o ano cheio.

**Réplica com as datas e parâmetros dele** (`dados/resultados/replica_almeida_2026-09-28/`,
MM simples 10/20 no fechamento, sem SL/TP, sem custo, R$ 50 mil, long-short):

| | Almeida | Réplica | Bate? |
|---|---|---|---|
| 2013–2016, 1.000 ações | 38 op. · +R$ 10.430 | 37 op. · +R$ 10.050 | **sim, nos dois** |
| 2008–2010, 100 ações | 37 op. · bruto +2.855 · líq. −1.595 | 38 op. · bruto +4.610 · líq. −575 | só a contagem |
| 2007–2011, 100 ações | 52 op. · bruto +3.363 · líq. −2.542 | 63 op. · bruto +6.609 · líq. −1.274 | só o sinal |

**Cuidado com o que se afirma aqui.** Em 29/09 os lucros BRUTOS foram extraídos
dos relatórios do MT5 e a conclusão anterior ("dois dos três testes fecham")
**caiu**: ela valia para a contagem de operações, não para o dinheiro. Só
2013–2016 fecha nas duas coisas. O detalhamento e as hipóteses estão em
`notas/INCERTEZAS.md`, item 7. **No TG, a réplica é evidência de que a
reimplementação reproduz o comportamento do algoritmo dele, não de que reproduz
os resultados financeiros.**

**O desdobramento importa muito aqui.** No preço bruto, sem corrigir o
desdobramento de 2008, o mesmo teste de 2007–2011 dá −R$ 7.041 (100 ações) e
−R$ 32.260 (1.000 ações, com a margem estourando depois de 18 operações). Como o
número dele é −R$ 2.542, **a série que ele usou já vinha ajustada**. Serve de
argumento para usar `PETR4_OFICIAL` e não o bruto.

## Scripts de validação

`ferramentas/ValidacaoAlgoLab.mq5` é versionado desde 05/10/2026 e roda por
`ferramentas/scripts/validar.sh` sobre `PETR4_OFICIAL`. Os de baixo continuam
fora do repositório, em `MQL5/Scripts/`:

- `ValidacaoAlgoLab.mq5` — recuperação de parâmetros em dados sintéticos com
  verdade conhecida + pipeline completo em PETR4.
- `WalkForwardAlgoLab.mq5` — seleção de ordens + walk-forward comparando
  ARIMA puro contra ARIMA-GARCH.

São eles que geram a sequência do ADF e a grade de AIC para as tabelas do TG.
Se forem úteis a longo prazo, mover para dentro do repositório.

## Pendências

- O `config-backtest.ini` da raiz do MT5 (prefixo novo) não tem `[Common]` e
  aponta para `PETR4_B3` com Janela_Selecao implícita de 500 (via `.set`
  salvo). Está superado pelo experimento de 21/09; atualizar ou apagar.
- **Levar a conclusão do backtest ao texto** (`cap2`, "Limitações e Trabalhos
  Futuros", hoje diz "ainda estão sendo consolidados"; e `cap3`). O texto do
  autor está com a orientadora. Não editar o `.tex` sem pedido.
- Benchmark: resolvido. O EA reporta Selic **e** buy-and-hold, e a comparação
  ARIMA puro × ARIMA-GARCH é feita com o gêmeo sem GARCH.
- Robustez em outros ativos: resolvido na rodada 4 (VALE3, USIM5, POMO4). O
  teste formal contra o buy-and-hold também está feito (`z_sharpe_bh` de
  Jobson-Korkie-Memmel e `alfa`), e o `Desempenho.mqh` exporta a curva diária.
- **Correções de texto FEITAS em 28/09/2026, a pedido do autor** (leitura do
  trabalho de Almeida). O `tg/` compila limpo depois delas (48 páginas):
  1. `referencias.bib`, `almeida2016`: título corrigido para **"Técnicas de
     previsão da bolsa com MetaTrader 5"** (folha de rosto), autor completo,
     `type` e `school` conforme o documento, mais um `note` avisando que o RIC
     catalogou o trabalho sob o outro título. **Os dois títulos existem**: o do
     PDF e o do registro no RIC — ver `dados/FONTES.md`, item 7.
  2. `cap1-fundamentacao.tex`, `tab:comparativa-det`: a coluna de modelo
     estatístico de Almeida virou `--` (ele não usou ARIMA) e o indicador virou
     `MMS (10, 20)`. Em `tab:comparativa`, o `X` dele em "Modelo estatístico"
     saiu.
  3. `cap1-fundamentacao.tex`, seção de médias móveis: agora diz que ele previu
     StopLoss e TakeProfit no algoritmo **mas testou com ambos nulos**.
  4. `cap2-metodologia.tex`, resultados do PTG: a justificativa "não especificou
     os valores exatos" de SL/TP foi substituída pelo fato (o anexo dele traz
     zero nos dois).
- **Introdução: três versões em 29/09/2026.** As anteriores estão em
  `notas/rascunhos/`. A v2 foi feita editando a v1 parágrafo a parágrafo e o autor
  a rejeitou: **colcha de retalhos**. **Lição: quando a mudança é de foco,
  reescrever inteiro.** A v3 tem encadeamento explícito, um parágrafo por elo.
- **TEXTO REESTRUTURADO EM 30/09/2026.** O TG foi de 47 para **56 páginas** e
  compila limpo, sem referência quebrada. Backups em `notas/rascunhos/`.
  - **Capítulo II reescrito** na numeração obrigatória da FATEC (2.1
    Caracterização · 2.1.1 objetivos · 2.1.2 delineamento · 2.2 lugar e amostra ·
    2.3 procedimentos · 2.3.1 técnicas · 2.3.2 natureza da análise), mais seções
    de implementação, arquitetura, validação, protocolo e obstáculos.
    **Corrigido um erro de fato grave**: o texto dizia que os dados vinham da
    corretora pelo MetaTrader. A fonte é o COTAHIST da B3 — a corretora só
    entrega a partir de 09/2021.
  - **Capítulo III criado** (Análise e Discussão dos Dados), que a norma exige e
    não existia: verificação das implementações, réplica de Almeida, resultado
    principal fora da amostra, robustez entre períodos e entre ativos, horizonte
    longo, comparação nas condições originais, o mecanismo e as limitações.
    8 tabelas e 2 figuras, **todos os números vindos de `dados/resultados/`**.
  - **Considerações Finais reescritas** como Capítulo IV, na ordem que o Manual
    exige: responde à pergunta-problema, revisita cada hipótese confirmando ou
    refutando, declara o cumprimento dos objetivos, limitações e trabalhos
    futuros. O texto anterior era placeholder do PTG (afirmava desempenho sem
    número e falava só de LSTM); está em `notas/rascunhos/cap3conclusao_removido.tex`.
  - **Resumo e abstract reescritos** com resultados, como pede a NBR 6028.
  - **Reparos de norma**: as duas tabelas comparativas do `cap1` viraram
    **Quadro** (dado qualitativo; ambiente declarado no `main.tex` via
    `newfloat`); as linhas de (PEREIRA, 2025) deixaram de marcar LSTM, que saiu
    do escopo, e a fonte de dados virou B3 (COTAHIST); e o `parskip` foi zerado
    no corpo do texto (Manual, item 1.4 — estava invertido).
  - **REVISÃO DE 30/09 (2ª passada), a pedido do autor.** Oito correções:
    1. **Sem ponto e vírgula e sem travessão longo em todo o texto.** Preferência
       explícita do autor. Zerados nos cinco capítulos (eram 35 e 27). Em tabela,
       o travessão de "não se aplica" virou meia-risca.
    2. **"sem dependência de bibliotecas externas" saiu.** Era forte demais: a
       ALGLIB é uma biblioteca, ainda que acompanhe a plataforma. Trocado por
       "na própria linguagem da plataforma".
    3. **"não existem implementações prontas de ARIMA/GARCH em MQL5" saiu.**
       Afirmação não verificável e divergente do PTG. Trocada pelo fato
       verificável: a biblioteca padrão oferece indicadores, não modelos de
       séries temporais.
    4. **"a Selic desestimula investimentos em produção real, como comprovam os
       estudos" saiu** (`cap1`). Não havia número nem estudo que sustentasse.
    5. **Referência de figura por posição corrigida**: "como se observa na imagem
       acima" virou `\ref{}` numerado, em três pontos do `cap1`. Float se move,
       então referência por posição quebra.
    6. **Itálico padronizado** nos estrangeirismos não dicionarizados
       (`backtesting`, `drawdown`, `Expert Advisor`, `Strategy Tester`). Ficam em
       redondo os já incorporados ao português, como software e script. No
       abstract, que é inglês e já sai em itálico, nada é marcado.
    7. **Conferido e mantido**: a hipótese com as duas dimensões (acerto
       direcional e adequação ao risco) é fiel ao PTG, cuja Hipótese Central diz
       "aferida em termos de potencial de acerto e adequação ao risco".
    8. **Conferido e mantido**: o `parskip` zerado. O Manual, item 1.4, diz
       textualmente "OBSERVAÇÃO: Não há afastamento entre parágrafos". O recuo
       de 1,25 cm é o que marca o parágrafo.
  - **Ainda falta**: inserir as citações marcadas com `% REFERÊNCIA:` nos
    `.tex`, depois que o autor ler cada obra. Nenhuma foi inserida sem leitura,
    conforme a regra nº 3.
- Os símbolos `_B3` precisam ser reimportados (defeito de `CHART_MODE_LAST`).
- O EA não calcula p-valor do ADF (o aproximado saiu na limpeza de 18/10/2026):
  a decisão usa o valor crítico a 5% de MacKinnon. Não reportar p-valor do ADF no TG.
- `legado/` guarda a implementação antiga (`ARIMA_EA.mq5`, `GARCH.mq5`), que
  não compila mais junto com o resto e serve só de consulta para os bugs
  documentados acima. O Apêndice A do TG é o EA atual sem comentários, não
  estes.

## Revisão do texto de 05/10/2026 — regras de escrita que valem daqui em diante

Pedido do autor: o texto estava "com muita coisa de IA", não fluido, e ainda
falava de LSTM e de indicadores. Tudo reescrito; backup em
`notas/rascunhos/antes_revisao_2026-10-05/`. O TG ficou com **48 páginas** (com o apêndice reduzido),
compila sem aviso de referência e sem estouro de margem.

**Regras de escrita (além das do Manual):**
- **Sem negrito no meio do texto** e **sem listas com marcadores** no corpo.
  Enumeração vira parágrafo ("O primeiro foi... O segundo...").
- **Sem ponto e vírgula e sem travessão longo** na prosa. Só onde a norma exige:
  palavras-chave e separação de citações no mesmo parêntese.
- **Escopo do texto: ARIMA, ARIMA-GARCH e as médias móveis de Almeida.** Nada de
  LSTM, redes neurais como proposta, IFR, MME, Bollinger ou MACD. Redes neurais
  só aparecem quando são o fato de um trabalho relacionado (Xing, Araya).
- Evitar fórmulas retóricas ("Três leituras decorrem", "Primeira, e a mais
  importante", "não X, mas Y" em série). Frase direta, tom do PTG.
- **Todo número conferido contra o arquivo de origem na hora de escrever.** A
  auditoria de 05/10 achou três números do Cap. III sem origem ou mal
  arredondados (INCERTEZAS, item 32). A procedência de cada tabela está no
  cabeçalho de comentário de `cap3-resultados.tex`.

**O que mudou na estrutura:** Cap. I sem indicadores e com as equações do ARIMA e
do GARCH(1,1) e a ponte média móvel → AR; Cap. II com o Quadro 2 (grade de
344 configurações) e prosa no lugar das listas; Cap. III com a seção
"Significância das diferenças" (Tabela 8 desde a refação de 06/10: GARCH × gêmea, 1 de 11 com p < 0,05,
nenhuma pior; × MM, 0 de 12, p de 0,11 a 0,95, incluído 2017–2024); Considerações finais sem número e em texto corrido;
Apêndice A com o EA. Detalhes de norma em `notas/NORMAS-FATEC.md`, seção 7.

**Atenção ao reler:** o Cap. I ganhou duas equações (ARIMA e GARCH(1,1)) e o
parágrafo da ponte média móvel → AR. É conteúdo que o autor precisa dominar para
a banca (regra nº 3).
