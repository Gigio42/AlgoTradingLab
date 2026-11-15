# Auditoria do TG — 13/11/2026

Pedido do autor: auditoria completa do documento, **sem alterar o texto**. Objeto:
`tg/main.pdf` de 13/11/2026 (89 páginas) e os `.tex` que o geram. Nada em `tg/`
foi modificado. As páginas citadas são as **impressas** no rodapé do PDF, e as
linhas são as dos `.tex` em `tg/conteudo/`.

O que foi feito:

1. leitura do PDF inteiro, da capa às referências;
2. conferência contra o Manual de Normas 2026-2028 (seção 4) e
   `ia/NORMAS-FATEC.md`;
3. busca automática das regras de escrita nos `.tex` (ponto e vírgula,
   travessão, negrito, listas, primeira pessoa, itálico);
4. cruzamento das chaves `\cite` com o `.bib` e de cada `\label` de ilustração
   com as suas chamadas no texto;
5. contagem das palavras do resumo e do abstract;
6. recálculo, a partir das próprias tabelas, de toda afirmação numérica dos
   Capítulos III e IV que dependa delas (somas, "x de y casos", diferenças);
7. inspeção visual dos quadros e gráficos.

---

## Resumo em uma tela

| Área | Situação |
|---|---|
| Regras de escrita (sem `;`, sem travessão, sem negrito, sem listas, impessoal) | **Tudo certo.** Só há `;` nas palavras-chave, onde a norma manda. |
| Estrutura obrigatória (Cap. II numerado, Cap. III, Considerações) | **Tudo certo.** |
| Sumário, lista de ilustrações, lista de tabelas | **Atualizados.** Batem com os títulos e as páginas, e toda ilustração é chamada no texto. |
| Lista de siglas | Em ordem alfabética, e toda sigla listada é usada. **Faltam** os códigos das outras ações (item 13). |
| Referências | **30 citadas = 30 no `.bib`**, sem sobra e sem falta. Há inconsistências de formato (itens 15 e 16). |
| Resumo e abstract | 285 e 290 palavras (limite: 150 a 500), parágrafo único, 3 palavras-chave. **Um erro de conteúdo** (item 2) e uma omissão (item 3). |
| Números do Cap. III e IV | Todas as contas conferidas batem com as tabelas. **Uma frase mistura colunas** (item 9). |
| Coerência entre partes | **Cinco problemas reais** (itens 1 a 5) e algumas repetições que surgiram com a seção 1.4 nova. |

Prioridade sugerida: itens 1 a 5 antes da banca, 6 a 12 se houver tempo, e o
resto como polimento.

> **Prazo:** pela tabela de `ia/PENDENCIAS.md`, a entrega à coordenação era de
> 09 a 13/11, ou seja, termina hoje. Se o PDF já foi entregue, os itens abaixo
> servem para a versão corrigida (até 14/12) e para preparar a defesa.

---

## A. Problemas que a banca pode apontar (prioridade alta)

### 1. As Considerações Finais trazem um resultado que não aparece antes

**Onde:** Considerações Finais, p. 61, `cap4-consideracoes.tex` l. 119–124.

> "Essa janela é relativamente curta para estimar o GARCH, e os seus parâmetros
> variaram bastante de um dia para o outro. Um teste à parte, com uma janela de 500
> pregões apenas para o GARCH, manteve a redução do risco [...], mas mudou as
> configurações escolhidas e os seus retornos"

Nem o teste com janela de 500 nem a variação diária dos parâmetros do GARCH
aparecem no Cap. II (método) ou no Cap. III (resultado). Pelo Manual, as
Considerações retomam o que foi mostrado e não apresentam dado novo. Um avaliador
atento pode perguntar onde está esse teste.

A decisão de manter a janela de 500 "só como limitação" foi do autor
(`ia/INCERTEZAS.md`, por volta da l. 1430), e ela pode continuar valendo. O que
falta é ancorar a frase em algum lugar. Opções, da menor para a maior mudança:

- **(a)** tirar o resultado e deixar só a limitação: "Essa janela é relativamente
  curta para estimar o GARCH, e janelas maiores ficam como trabalho futuro" (a
  frase de trabalho futuro já existe no parágrafo seguinte);
- **(b)** manter a frase e acrescentar uma linha em 2.4.4, "Janela de estimação",
  dizendo que se fez um teste à parte com 500 pregões só para o GARCH;
- **(c)** mostrar o teste no Cap. III, o que não parece valer a pena agora.

### 2. Resumo e abstract chamam de "mercado estável" o período de 2013 a 2016

**Onde:** resumo, l. 11–12, e abstract, l. 8 ("performed well in stable market
periods").

O resumo diz que o robô de Almeida "obteve bons resultados em períodos de mercado
estável". O único período com lucro dele é 2013 a 2016, e o próprio TG o chama
de "Queda prolongada e recuperação" (seção 3.5), com a PETR4 chegando a **83,1%
de queda máxima** (Tabela 5), a maior de todas as tabelas. Quem lê o resumo e
depois a Tabela 5 vê a contradição.

Sugestão: usar a expressão do próprio Almeida, "fora de crise" ("obteve lucro no
período fora de crise", "outside the crisis period"). Na mesma linha, "em
períodos de crise e de calma" (resumo l. 20 e Considerações, p. 61) pede o mesmo
cuidado, porque nenhum período do TG é chamado de calmo, a não ser 2025–2026, de
passagem (seção 3.8, "um período mais calmo"). Uma opção é "em diferentes
períodos, incluindo duas crises".

### 3. A venda a descoberto não chega às Considerações nem ao resumo

**Onde:** seção 3.11 (p. 58), Considerações Finais, resumo e abstract.

A venda a descoberto tem método próprio (2.5.8), seção própria (3.11) e tabela
própria (Tabela 15). Mesmo assim, a palavra "descoberto" não aparece nas
Considerações, no resumo, no abstract nem na introdução. A seção 3.11 fica sem
fechamento, e o resultado dela é forte e fácil de defender: a queda máxima
aumentou nos 16 casos, o retorno caiu em 11, e 28 simulações quebraram, todas com
venda a descoberto.

As outras ações aparecem nas Considerações ("O efeito se repetiu nas outras três
ações"), mas não no resumo, que fala só em "histórico oficial da bolsa
brasileira".

Sugestão: uma frase nas Considerações, no parágrafo do risco ou no das
limitações (algo como "vender a descoberto aumentou a queda máxima em todos os
casos testados"), e meia frase no resumo e no abstract sobre as quatro ações e a
venda a descoberto. O resumo tem folga: 285 de 500 palavras.

### 4. "Teste principal" tem dois sentidos, e os períodos têm nomes diferentes em cada lugar

**Onde:** 2.5.1 (l. 466, "cenário principal"), 2.5.9 (l. 744, "como no teste
principal"), 3.6 (l. 540, título "Teste principal, 2017 a 2024"), 3.12 (l. 1116,
"o mesmo procedimento do teste principal"), Figuras 7 e 8.

- Em 3.6, "teste principal" é **o período de 2017 a 2024**, "por ser o mais longo
  com escolha própria". O Cap. II nunca diz isso: lá, 2017 a 2024 é só "o
  intervalo [...] que inclui a crise da pandemia" (2.2).
- Em 2.5.9 e 3.12, "teste principal" é **o cenário da PETR4 só na compra**, em
  todos os períodos.
- A mesma fase de 2017 a 2024 chama-se "Inclui a pandemia" na Figura 7 e "Teste
  principal" na Figura 8.
- O primeiro período chama-se "Crise financeira" na Figura 7 e na seção 3.4, e
  "Crise de 2008" na Figura 8.

Sugestão: escolher um nome por período e usá-lo nas duas figuras, nos títulos do
Cap. III e no texto. Se 2017 a 2024 é o teste principal, dizer isso uma vez no
Cap. II (2.2 ou 2.5.6) e trocar o "teste principal" de 2.5.9 e 3.12 por "cenário
principal" ou "como na PETR4".

### 5. A Figura 6 diz que o veto termina o pregão "sem ordem", mas na maioria dos robôs ele envia uma ordem

**Onde:** Figura 6 (p. 23, `tg/figuras/fig08-integracao-arima-garch.tex`
l. 38–39) e o parágrafo que a chama (`cap1-fundamentacao.tex` l. 498: "a
operação é vetada e o pregão termina sem ordem").

Em 2.4.6 (l. 433–436), o veto pode também encerrar a posição aberta, e o
Quadro 4 mostra que **6 dos 7 robôs com GARCH escolhidos na PETR4 usam essa
opção**. Nesses robôs, um veto com a posição comprada gera uma ordem de venda
para zerar. A figura e a frase estão certas para o caso padrão e para quem está
fora do mercado, mas um membro da banca que conheça o Quadro 4 pode notar a
diferença.

Sugestão de texto para a caixa, sem perder a ideia pedida de "o ciclo termina se
o GARCH vetar": "Operação vetada: nenhuma compra no pregão". No parágrafo: "o
pregão termina sem nova compra (e, se a opção estiver ligada, a posição aberta é
encerrada)".

---

## B. Coerência e coesão (prioridade média)

### 6. A seção 1.4 nova criou repetições com o que já existia

- **Pesos fixos × estimados** aparecem três vezes, quase com as mesmas palavras:
  na introdução (p. 9, "com pesos ajustados aos dados"), em 1.4 (l. 222, "com
  pesos fixados por convenção, enquanto o modelo estatístico ajusta os seus
  parâmetros") e em 1.4.1 (l. 299–306, "Há uma relação direta [...] em vez de
  fixados por convenção [...] ajusta os coeficientes ao ativo e ao período").
  Sugestão: em 1.4, ficar com a ideia geral (o modelo estima a partir dos dados),
  e deixar o "pesos fixados por convenção" só em 1.4.1, onde vem com o exemplo de
  um décimo.
- **Passeio aleatório e estacionariedade** são explicados três vezes: 1.4 (l. 240,
  "O preço anda sem rumo definido, como um passeio aleatório"), 1.4.1 (l. 274, "De
  forma simplificada, uma série é estacionária quando...") e de novo antes do ADF
  (l. 320–325, "Uma série estacionária oscila em torno de uma média
  estável [...] passeio aleatório"). Sugestão: definir uma vez (a definição de
  l. 274 ou a de l. 320) e, nos outros pontos, só retomar.

### 7. A seção 1.3 põe o ARIMA e o GARCH dentro da análise técnica, e a 1.4 os separa

**Onde:** 1.3, l. 172 ("É na segunda vertente que este trabalho se insere. Tanto
a estratégia de médias móveis [...] quanto os modelos ARIMA e GARCH são regras
matemáticas"), e 1.4, seção irmã, que abre contrastando "modelo estatístico" com
"média móvel".

Não é contradição, mas abre a pergunta "o ARIMA é análise técnica?". Sugestão:
uma frase-ponte no início de 1.4, algo como "Dentro da vertente estatística, há
uma família de métodos que vai além dos indicadores: os modelos de séries
temporais", ou o ajuste inverso em 1.3.

### 8. Resultado das outras ações aparece em dois lugares

**Onde:** seção 3.8, l. 848–857 (comparação na grade inteira, "84% a 92% das
comparações" etc.), e seção 3.12, "Outras ações".

Depois da separação de 13/11, a 3.12 ficou com os robôs escolhidos, e a análise
da grade inteira nas quatro ações ficou na 3.8. Quem procura "outras ações" no
sumário encontra só metade. A frase também começa com "nas outras três ações" e
segue com "considerando as quatro ações". Sugestão: levar esse parágrafo para o
início da 3.12, ou deixar uma remissão ("como se detalha na Seção 3.12"), e
acertar o "três"/"quatro".

### 9. Uma frase da seção 3.10 compara números de colunas diferentes

**Onde:** 3.10, l. 932–937.

- "Em 2007 a 2011, ele [o ARIMA-GARCH] passou de uma perda de 15,2% para um ganho
  de 28,7%". Os 15,2% são a coluna **"+ custos"**. O resultado bruto, citado em
  todo o resto do capítulo, é −8,4%.
- "levaram a PETR4 de 143,6% para 777,9% [...] e as médias móveis de 90,4% para
  396,0%". Na mesma frase, o 143,6% da PETR4 é **bruto**, e o 90,4% das médias
  móveis é **"+ Selic"** (o bruto é 47,8%).

As contas estão certas, porque cada coluna soma um fator à anterior. Mas o leitor
que lembra do −8,4% ou do +47,8% vai achar que o número está errado. Sugestão:
dizer a etapa ("depois dos custos, passou de...") ou comparar sempre o bruto com
o final.

### 10. Os gráficos do MetaTrader 5 não dizem qual ARIMA mostram

**Onde:** notas dos Gráficos 4, 9, 12 e 16 (l. 375, 533, 622, 763).

Há dois "ARIMA" no capítulo: o escolhido entre os robôs sem GARCH, o das
tabelas, e a mesma configuração do ARIMA-GARCH com o GARCH desligado, o da
Tabela 9. Em 2017–2024 e 2025–2026 eles coincidem (Quadro 4). Em **2007–2011 e
2013–2016, são robôs diferentes**: o ARIMA usa janela de 240 e 120, e o
ARIMA-GARCH usa 120 e 240. Os Gráficos 6 e 14 já dizem qual é o deles; os do
MetaTrader 5, não.

O mesmo vale para as duas exposições médias de 2007 a 2011: 3.9 diz "20,1%
contra 45,6% da mesma configuração sem o GARCH", e 3.10 diz "só 20% [...] contra
43% do ARIMA". São dois robôs diferentes com números próximos, e a banca pode
achar que é o mesmo número arredondado de dois jeitos.

Sugestão: acrescentar à nota de cada gráfico do MT5 "O ARIMA é o robô sem GARCH
da Tabela X" (ou "a mesma configuração com o GARCH desligado"), e, em 3.10,
escrever "do ARIMA da Tabela 3".

### 11. Data final do último período

**Onde:** 2.2 ("de 2 de janeiro de 2003 a 21 de setembro de 2026") e nota da
Tabela 8 ("O período termina em 18 de setembro de 2026").

A diferença de três dias não é explicada em lugar nenhum. Basta meia frase em um
dos dois lugares, se houver motivo (o último pregão com abertura, o fim do
teste), ou alinhar as datas.

### 12. Outras inconsistências pequenas de redação

- **"2025 e 2026" × "2025 a 2026"**: cinco ocorrências da primeira forma no
  Cap. III, contra 14 da segunda. Padronizar em "2025 a 2026".
- **"variante" × "versão"**: as Considerações (l. 85–86) usam "variantes com
  GARCH"; o Cap. III usa "versões". Padronizar.
- **Abertura do Cap. III** (l. 58–64): a última frase encadeia quatro
  coordenadas ("mostra [...] e como [...] e o que muda [...] e fecha"). Dividir
  em duas frases.
- **Seção 3.3** repete definições da 2.5.7 (o que é "ARIMA" e "PETR4" nas
  tabelas), e a 3.11 reabre com o método da 2.5.8. Pela regra de 14/10 ("o
  Cap. III diz só o que deu"), dá para encurtar as duas e remeter ao Cap. II.
  Fica a critério do autor, porque como guia de leitura funciona.
- **2.4.7, l. 452**: "a ordem máxima de zero a quatro do ARIMA" soa estranho.
  Sugestão: "as ordens p e q do ARIMA, de zero a quatro".
- **3.7, l. 714**: o parágrafo "O Gráfico 15 mostra a evolução do patrimônio no
  período" tem uma frase só e não diz o que o gráfico mostra. Os outros gráficos
  de patrimônio têm uma leitura.
- **Tabela 16** (l. 1154): "Ação" é o nome de duas colunas, a primeira (VALE3,
  USIM5, POMO4) e a última (compra e manutenção). A nota explica, mas o cabeçalho
  confunde. Sugestão: "Compra e manutenção" na última.

---

## C. Normas (listas, siglas, referências)

### Conferido e certo

- **Sumário**: todas as divisões com o mesmo texto e a mesma numeração do corpo,
  sem os elementos pré-textuais, e só o título principal de cada apêndice.
- **Cap. II** com a numeração obrigatória (2.1, 2.1.1, 2.1.2, 2.2, 2.3, 2.3.1,
  2.3.2).
- **Lista de ilustrações única** (correta, porque há só 4 quadros, menos de 5) e
  lista de tabelas separada. Figuras 1 a 8, Quadros 1 a 4, Gráficos 1 a 16 e
  Tabelas 1 a 16 na ordem em que aparecem.
- **Todas as 44 ilustrações são chamadas no texto** (conferido por `\label` ×
  `\ref`), com título em cima e fonte embaixo, centralizada.
- **Quadros fechados e tabelas abertas** nas laterais.
- **Resumo**: 285 palavras, um parágrafo, com contexto, objetivo, método e
  resultado. Palavras-chave: 3, separadas por ";" e terminadas em ".". Abstract
  equivalente, com 290 palavras.
- **Citações em caixa mista** dentro dos parênteses (NBR 6023:2025). Não há
  citação direta, então não falta página em nenhuma.
- **Itálico** coerente nos estrangeirismos (*Expert Advisor*, *backtesting*,
  *drawdown*, *forward*, *volatility targeting*, *day trade*, *Balance*).
- **Considerações Finais** respondem à questão, retomam as duas hipóteses
  (primeira parcialmente confirmada, segunda confirmada quanto ao risco) e
  declaram o cumprimento do objetivo geral e dos quatro específicos.
- **Introdução** com contexto, justificativa (relevância e viabilidade),
  questão, hipóteses, objetivos, percurso metodológico e organização.
- **Folha de aprovação** comentada no `main.tex`; só entra na versão final, como
  manda o Manual.

### 13. Lista de siglas: falta o código das outras ações

A lista explica PETR4 ("Código de negociação das ações preferenciais da
Petrobras"), mas VALE3, USIM5, POMO4 (Cap. II e III) e BBAS3F (1.7 e Quadro 2)
não estão nela. Ou se acrescentam as quatro, ou se tira PETR4 da lista, já que o
texto explica cada código na primeira menção (2.2 e 2.5.9).

Menor: B3 e MQL5 aparecem no texto sem a forma por extenso na primeira menção
(ficam só na lista). EGARCH e TGARCH também, mas, como aparecem só como nomes de
variações, não pesa.

### 14. Páginas nas citações de Thomaz (2019)

Thomaz é citado 18 vezes, 6 delas com página. A norma só exige página em citação
direta, então não há infração. Mas os parágrafos novos da seção 1.4 (l. 220, 237,
240, 251) estão sem página, e a leitura do autor das pp. 16, 24 e 29–30 ainda
está pendente (`ia/PENDENCIAS.md`, 13/11). Pôr a página nessas citações ajuda o
autor a achar o trecho na hora da defesa, e deixa o padrão mais uniforme. O mesmo
vale para os R$ 7.530 de Almeida (3.5): a página já está anotada no comentário
da l. 52 do `cap3-resultados.tex`.

### 15. Referências de periódicos sem padrão de local e editora

| Obra | O que aparece |
|---|---|
| Bollerslev (1986) | "Elsevier, Amsterdam" |
| Engle (1982) | "The Econometric Society, New Jersey, EUA" |
| Araya et al. (2024) | "Londres, Reino Unido" |
| Sharpe (1994) | "Nova Iorque" |
| Hannan e Rissanen (1982) | nada |
| Harvey et al. (2018) | nada |

Pela NBR 6023, no artigo de periódico o **local de publicação** é elemento
essencial, e a editora não entra (**conferir no manual da FATEC**; não está
confirmado aqui). Sugestão: só o local, em todas as seis, e sem a editora.

Também diferem: MetaQuotes (2024) traz "Limassol: MetaQuotes Ltd., 2024", e as
quatro de 2026 trazem só "Limassol, 2026a". E várias datas de acesso são de
fevereiro a abril de 2025 (Almeida, BCB 2025a–c, Batista, MetaQuotes 2024, Xing):
vale abrir os links antes da versão final e atualizar a data.

### 16. Fonte da Figura 1

A Figura 1 (interface do MetaTrader 5) tem como fonte "MetaQuotes Ltd. (2024)".
Se a imagem foi capturada pelos autores na própria plataforma, o padrão do resto
do trabalho seria "Elaboração própria com a interface do MetaTrader 5", como na
Figura 3. Se veio do site da MetaQuotes, está certa. Só o autor sabe.

Do mesmo tipo: o Gráfico 1 diz "com dados de B3 (2026b)", e as Tabelas 3 a 8 e
os Gráficos 2, 3, 5, 7, 8, 10, 11, 13 e 15, que também usam a série da B3, dizem
só "Elaboração própria". Não é erro, mas o padrão poderia ser o mesmo.

---

## D. Aparência

### 17. Eixo de datas dos gráficos de patrimônio

Gráficos 3, 5, 8, 10, 13 e 15: as marcas do eixo horizontal caem em meses
irregulares (01/2007, 05/2008, 09/2009, 02/2011...) e a última passa do fim do
período (06/2012 num teste que termina em 2011, 02/2017 em 2013–2016, 03/2025 em
2017–2024, 02/2021 em 2020). Marcas anuais (jan. de cada ano) ficariam mais
limpas e não sugeririam dados além do período. É ajuste no `graficos_cru.sh` /
pgfplots, sem mudar dado.

### 18. Gráficos do MetaTrader 5 pequenos

Gráficos 4, 9, 12 e 16: as capturas do relatório do testador ficam com os números
dos eixos ilegíveis na página. Se houver espaço (as pp. 45 e 54 têm 25–30% em
branco), dá para aumentar a largura. Como a nota já diz que as escalas são
diferentes, o leitor vai querer conseguir lê-las.

### 19. Espaço em branco

Continuam as duas páginas conhecidas, a p. 45 (~25%) e a p. 54 (~30%). As demais
sobras são fim de capítulo, referências ou código.

### 20. Figuras 7 e 8 quase iguais

A Figura 8 (p. 37) é a Figura 7 (p. 28) com os períodos de otimização, e o texto
diz isso ("A Figura 8 acrescenta à Figura 7..."). Uma só figura, a 8, posta em
2.2, eliminaria a repetição e o problema de nomes do item 4, e devolveria meia
página. A decisão é do autor: com duas figuras, a amostra é apresentada antes do
método de escolha, o que também tem sua lógica.

---

## E. A conferir com o autor (não são erros)

- **LSTM nas Considerações** (l. 163). A regra de escrita de 05/10 dizia "nada de
  LSTM [...] como proposta". Aqui ele aparece como trabalho futuro e como fato do
  projeto original (PTG), o que é defensável. Só confirmar que é intencional.
- **Delineamento quase experimental**: a resposta da orientadora ainda não veio
  (pendência anterior).
- **Seção 1.4 nova**: depende da leitura do autor das pp. 16, 24 e 29–30 de
  Thomaz (pendência de 13/11).

## F. Fora do texto (organização do repositório)

- `tg/figuras/` tem resíduos de compilação da `fig05-fluxo-arima` (`.aux`,
  `.log`, `.fls`, `.fdb_latexmk`, `.synctex.gz`). A regra é que `tg/` só guarde o
  que vai ser entregue.
- `fig08-integracao-arima-garch.*` e `fig09-periodos-teste.*` ainda não estão no
  git (`??`). Se for feito commit sem eles, o `main.tex` não compila em outra
  cópia.
- Os nomes dos arquivos não seguem a numeração do PDF (o `fig08` é a Figura 6, o
  `fig09` é a 7 e o `fig07` é a 8). Só importa para quem mexe nos arquivos.
- `ia/bibliografia/OBRAS-DO-TG.md` ainda diz que o `araya2024` do `.bib` está
  errado, mas o `.bib` já foi corrigido (autores e *Journal of Applied
  Mathematics* certos).

---

## G. O que foi conferido número a número

Para registro, as afirmações abaixo foram recalculadas a partir das tabelas do
próprio PDF, e **todas bateram**:

- **3.1**: diferenças de R$ 113 e R$ 12, duas operações a menos, 3,6% do lucro.
- **3.2**: α + β = 0,9765.
- **3.6.1**: maior retorno e menor queda do Sharpe, menor volatilidade do Calmar,
  e 40,2% contra 40,5%.
- **3.7**: −12,5% e −1,5% compõem −13,7%; −8,5% e +24,8% compõem +14,2%; −15,4%
  e +57,5% compõem +33,2%.
- **3.8**: 3 de 7 com retorno maior, 7 de 7 com risco menor, e os pares que
  dividem a mesma configuração sem GARCH.
- **3.10**: a ordem dos robôs se mantém entre bruto e "+ proventos" em 2007–2011,
  2013–2016 e 2025–2026 e muda em 2017–2024.
- **3.11**: 16 de 16 com queda maior, 11 com retorno menor, 5 com retorno maior
  (3 em 2013–2016), e 4.992 = 312 × 16.
- **3.12**: 10 de 12 (Calmar com a menor queda), 3 casos do Sharpe pior que o
  ARIMA, 9 de 12 do ARIMA à frente do Sharpe no retorno, e 275,5% como maior
  ganho.
- **2.5.5**: 304 + 8 = 312. **2.5.8**: 19.968 = 624 × 16 × 2.
- **Considerações Finais**: exceção da variante que mantém a posição em
  2017–2024 (40,2% contra 37,9% das médias móveis), volatilidade com GARCH sempre
  abaixo das médias móveis.
- **Introdução**: os 64,2% de queda da PETR4 em 2020 batem com a Tabela 7.
