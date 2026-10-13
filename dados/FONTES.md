# Procedência dos dados

Todo dado externo usado nos backtests está listado aqui: de onde veio, quando
foi obtido, o que foi feito com ele e como foi conferido. Nenhum valor foi
digitado à mão. Os arquivos brutos ficam em `fontes/`; as séries prontas que o
MetaTrader lê ficam em `series/` (cópias idênticas das que estão em
`MQL5/Files/` do terminal).

Horários em BRT (UTC−3). Obtidos pelo Claude (assistente de IA) em sessão com o
autor, em 21/09/2026.

---

## 1. Preços da PETR4 — B3, Cotações Históricas (COTAHIST) — **fonte principal**

| | |
|---|---|
| Fonte | B3 S.A. — Brasil, Bolsa, Balcão. Série Histórica de Cotações, arquivos anuais |
| URL | `https://bvmf.bmfbovespa.com.br/InstDados/SerHist/COTAHIST_A<ano>.ZIP` |
| Anos | 2003 a 2026 (o de 2026 vai até 21/09/2026, data do trailer do arquivo) |
| Obtido em | 21/09/2026, 21:44 a 21:47 |
| Integridade | SHA-256 de cada ZIP em `fontes/b3/COTAHIST_sha256.txt` |
| Arquivo guardado | `fontes/b3/PETR4_linhas_COTAHIST_2003_2026.txt`: as linhas originais da PETR4, sem alteração (os ZIPs completos têm ~800 MB e não foram versionados) |

**Filtro aplicado** (layout oficial do arquivo COTAHIST, posições 1-indexadas):
tipo de registro `01`; código BDI `02` (lote padrão); código de negociação
`PETR4`; tipo de mercado `010` (à vista). Campos lidos: data (3–10),
abertura (57–69), máxima (70–82), mínima (83–95), último/fechamento (109–121),
quantidade de ações (153–170), fator de cotação (211–217). Preços com 2 casas
implícitas, divididos pelo fator de cotação (= 1 em todo o período).

**Resultado:** 5.881 pregões de 02/01/2003 a 21/09/2026, sem datas duplicadas e
sem barra inconsistente (abertura ou fechamento fora da faixa mínima–máxima).

**Séries derivadas:**
- `series/PETR4_OFBRUTO.csv` → símbolo `PETR4_OFBRUTO`. Preço de tela, **sem
  nenhum ajuste**. Usado só para testar as condições de Almeida (2016).
- `series/PETR4_OFICIAL.csv` → símbolo `PETR4_OFICIAL`. **Só corrigido pelos
  desdobramentos** (item 2), sem dividendos. É a série que os modelos veem.
  Correção: preços anteriores a 28/04/2008 ÷ 2; anteriores a 01/09/2005 ÷ 4
  adicional (÷ 8 no total); volume multiplicado pelo mesmo fator. Arredondado a
  2 casas (erro máximo ~0,09%, no preço mais baixo, R$ 5,8 em 2003).

Formato das séries (exigido pelo importador): `AAAA.MM.DD,00:00,abertura,máxima,mínima,fechamento,volume`.

## 2. Desdobramentos da PETR4

| Data-ex | Evento | Confirmação |
|---|---|---|
| 01/09/2005 | 1 ação → 4 | Yahoo (`fontes/yahoo/yahoo_desdobramentos_PETR4.csv`); queda de −75,2% no COTAHIST nessa data |
| 28/04/2008 | 1 ação → 2 | API da B3 (`fontes/b3/proventos_PETR_api_b3.json`, "DESDOBRAMENTO", fator 100%); Yahoo; queda de −49,5% no COTAHIST |

A lista da API da B3 não traz o de 2005. Os dois aparecem no Yahoo e nos saltos
de preço da própria B3. Depois da correção, as maiores variações diárias da
série são eventos reais (09/03/2020, −29,7%, COVID-19; 22/02/2021, −21,5%).

## 3. Proventos (dividendos e JCP) — **não oficial, usado só como adendo**

| | |
|---|---|
| Fonte | Yahoo Finance, pela biblioteca `yfinance` (`Ticker("PETR4.SA").dividends`) |
| Obtido em | 21/09/2026, 21:46 |
| Arquivo bruto | `fontes/yahoo/yahoo_dividendos_PETR4.csv` |
| Série derivada | `series/proventos_PETR4.csv`: data-ex, R$ por ação (valores já corrigidos por desdobramento pelo Yahoo); eventos da mesma data somados |
| Cobertura | 62 eventos, de 01/07/2005 a 24/08/2026 |

**Conferência:** a API da B3
(`https://sistemaswebb3-listados.b3.com.br/listedCompaniesProxy/CompanyCall/GetListedSupplementCompany/<base64 de {"issuingCompany":"PETR","language":"pt-br"}>`,
guardada em `fontes/b3/proventos_PETR_api_b3.json`) só traz os proventos dos
últimos ~2 anos. Nos 4 eventos da PN em comum, 3 valores são idênticos e 1
difere em 0,9% (data-com 22/12/2025: B3 R$ 0,9432; Yahoo R$ 0,9521). Limitações
em `notas/INCERTEZAS.md`.

Uso: só na camada 4 da avaliação (`Desempenho.mqh`). **Os modelos não veem
proventos**, e a escolha de parâmetros não os usa.

## 4. Taxa Selic diária — Banco Central do Brasil

| | |
|---|---|
| Fonte | BCB, Sistema Gerenciador de Séries Temporais (SGS), **série 11**: "Taxa de juros — Selic", % ao dia |
| URL | `https://api.bcb.gov.br/dados/serie/bcdata.sgs.11/dados?formato=csv&dataInicial=DD/MM/AAAA&dataFinal=DD/MM/AAAA` |
| Obtido em | 21/09/2026, 21:43, em 3 consultas (01/01/2000–31/12/2008, 01/01/2009–31/12/2017, 01/01/2018–21/09/2026; a API limita cada consulta a 10 anos) |
| Arquivos | `fontes/bcb/selic_sgs11_2000_2026.csv` (bruto) = `series/selic_diaria.csv` (usado) |
| Transformação | só formato: data `DD/MM/AAAA` → `AAAA.MM.DD`, vírgula decimal → ponto |
| Cobertura | 03/01/2000 a 21/09/2026, 6.711 dias úteis |

**Conferência:** uma segunda cópia, baixada horas antes com outro intervalo de
datas (`fontes/bcb/superado_selic_2005_2026.csv`), tem valores idênticos em
todas as datas comuns. Para conferir à mão: Calculadora do Cidadão do BCB,
"correção pela Selic" (ex.: 02/01/2025 a 24/04/2026 ≈ +19,1%).

## 5. Histórico da corretora (Clear) — **só conferência**

| | |
|---|---|
| Fonte | Servidor `ClearInvestimentos-DEMO`, símbolo `PETR4`, D1 |
| Obtido em | 21/09/2026, 19:45 (hora do servidor), pelo script `ferramentas/ExportarHistoricoCorretora.mq5` |
| Arquivo | `fontes/clear/PETR4_D1_ClearInvestimentos-DEMO.csv` |
| Cobertura | 1.248 pregões, **só de 21/09/2021 em diante** (o servidor informa essa data como a primeira disponível) |

A Clear entrega o preço **já ajustado por proventos**, por método próprio não
documentado. Como não cobre 2003–2021 e seu ajuste não é reproduzível, não é a
base dos testes. É usada para conferir a B3 (`verificacao/clear_x_b3_2021_2026.csv`):
- os 1.248 pregões são os mesmos nas duas fontes;
- fora das datas-ex, os retornos diários coincidem, com diferença mediana de
  0,013 p.p. (arredondamento da Clear, que grava o preço ajustado com 2 casas);
- nas 22 datas-ex, a diferença reflete o provento (item 3).

## 6. Yahoo Finance (preços) — **usado nas rodadas 1 e 2, hoje superado**

| | |
|---|---|
| Fonte | Yahoo Finance via `yfinance` (`download("PETR4.SA", auto_adjust=False)`) |
| Obtido em | 21/09/2026, várias vezes; a última às 21:43 (6.560 barras, 2000–2026) |
| Arquivos | `fontes/yahoo/PETR4_yahoo_close_2000_2026.csv` (Close); `fontes/yahoo/PETR4_yahoo_adjclose_escalado_2000_2026.csv` (Adj Close × 5,5739, para o 1º dia ter o preço real); versões anteriores em `fontes/yahoo/superados/` |

Substituído pela B3 porque (verificação em `verificacao/b3_x_yahoo_2003_2026.csv`):
- faltam 51 pregões que a B3 tem, entre eles ~13 na queda de 28/07 a
  17/08/2011;
- 238 dias têm fechamento diferente do da B3 em mais de 0,5% (69 em 2006,
  49 em 2007, 36 em 2015);
- o ano 2000 tem abertura = máxima = mínima = fechamento em 212 barras.

Os resultados das rodadas 1 e 2 (`resultados/rodada1_yahoo_*`,
`resultados/rodada2_yahoo_*`) foram feitos com esses dados e **não devem ser
citados no TG**.

## 7. Almeida (2016) — trabalho original, consultado em 28/09/2026

O autor obteve o trabalho original e ele **foi lido**. Arquivo em
`bibliografia/pdfs/Almeida-2016.pdf`
(sha256 começa em `1b435dfebe577797`).

**Dados bibliográficos corretos**, tirados da folha de rosto:

| | |
|---|---|
| Autor | Flávio Leite Ribeiro de Almeida |
| Título | **Técnicas de previsão da bolsa com MetaTrader 5** |
| Instituição | FATEC Indaiatuba (Centro Paula Souza) |
| Curso | Curso Superior de Tecnologia em Banco de Dados |
| Data | Junho de 2016 |

**Dois títulos, e os dois são reais.** A folha de rosto do PDF diz "Técnicas de
previsão da bolsa com MetaTrader 5"; o registro no Repositório Institucional do
Centro Paula Souza (`DC.title` da página `handle/123456789/24287`, conferido em
28/09/2026) diz "Análise da ação PETR4 na Bolsa de Valores de São Paulo com
MetaTrader 5". O `.bib` usava o segundo. Em 28/09 passou a usar o da folha de
rosto, com um `note` registrando o outro — assim quem seguir a URL encontra o
trabalho. O mesmo registro do RIC informa o curso como "Análise e
Desenvolvimento de Sistemas", **divergindo do PDF**, que diz "Banco de Dados" na
folha de rosto e no texto; vale o PDF. Orientador: Prof. MsC. Michel Moron
Munhoz; avaliadores: Carlos Henrique Dias e José Estanislau Sigrist.

**Configuração dos testes dele** (seção 3 e anexo com o código):

| | 2007–2011 (crise) | 2013–2016 |
|---|---|---|
| Período | 01/01/2007 a 31/12/2011 | **22/05/2013 a 24/05/2016** |
| Capital | R$ 50.000 | R$ 50.000 |
| Alavancagem | 1:100 | não informada |
| Volume | não informado (ver nota) | 1.000 ações |
| Modelagem | "Every tick" | "Every tick" |
| Entrada | uma vez por dia | uma vez por dia |

**Nota sobre o volume do teste de crise.** Ele não o declara, mas escreve: "o
número mínimo desse volume é 100 para compras ou vendas, porém durante o período
analisado [2013–2016] foi testado com um volume de 1000 para atingir uma
lucratividade ainda maior". A leitura natural é que 100 era o valor usado antes e
que 1.000 foi uma mudança feita só para 2013–2016. É a justificativa para a
réplica de 2007–2011 usar 100 ações.

**Algoritmo** (anexo, `EA_TG_2016.mq5`): cruzamento de duas médias móveis
**simples** (método 0), períodos **10 e 20**, sobre o **preço de fechamento**;
StopLoss e TakeProfit iguais a **zero** por padrão; gestão de dinheiro por
porcentagem de risco (2%) disponível; sem trailing stop. Baseado no livro
*Expert Advisor Programming for MetaTrader 5*.

No anexo, `Gerencia_Dinheiro = true` e `Porcentagem_Risco = 2`, mas a função
`MoneyManagement()` está em `GerenciaDinheiro.mqh`, que **não** foi incluído no
anexo (é do livro *Expert Advisor Programming for MetaTrader 5*, citado por ele).
Com `StopLoss = 0`, não é possível saber pelo material disponível se o volume das
operações dele era o fixo ou um calculado. É o principal candidato a explicar a
diferença na contagem de operações da réplica de 2007–2011.

**Custos:** ele afirma explicitamente que "o método não inclui de nenhuma forma
taxas de corretagem"; o MetaTrader simula ambiente sem taxação.

**Resultados relatados:**

| | Operações | Resultado |
|---|---|---|
| 2007–2011, PETR4 | 52 | lucro bruto R$ 3.363, perdas R$ 5.905, **líquido −R$ 2.542** |
| 2008–2010, PETR4 | 37 | lucro bruto R$ 2.855, **líquido −R$ 1.595** |
| 2013–2016, PETR4 | 38 | **líquido +R$ 10.430** (mais de 20% do capital) |
| 2012–2016, CIEL3 | 51 (21 com lucro) | líquido +R$ 13.650 |
| 2012–2016, VLID3 | 49 (25 com lucro) | líquido +R$ 25.510 |

**Objetivo dele:** "trazer um retorno de investimento na bolsa de valores igual
ou superior à atual taxa da SELIC", que em 2016 estava em 14,25%. Conclusão
dele: conseguiu em ativos de proteção e em alguns períodos fora de crise com
PETR4, mas **não é possível superar a Selic durante 100% do tempo**.

**Ele NÃO usou ARIMA.** As palavras ARIMA não aparecem no trabalho; ARCH e GARCH
aparecem só na lista de siglas e na **sugestão de trabalhos futuros** — que é a
origem deste TG. A tabela do `cap1-fundamentacao.tex` que atribui ARIMA a ele
precisa ser corrigida.

## 8. Parâmetros adotados sem fonte primária

| Parâmetro | Valor | Situação |
|---|---|---|
| Custo por execução (`Custo_Por_Lado`) | 0,03% do valor negociado | Aproximação de emolumentos + liquidação da B3 com corretagem zero. **A tabela de tarifas da B3 não foi consultada.** Conferir antes de citar. |
| Capital inicial | R$ 100.000 (cenário justo); R$ 50.000 (réplica de Almeida) | Escolha de projeto |
| Fração investida | 95% do patrimônio | Escolha de projeto |

## 9. Outros ativos para o teste de robustez (23/09/2026)

Mesma fonte e mesmo tratamento do PETR4 (item 1): B3 COTAHIST 2003–2026,
rebaixado em 23/09/2026 (os arquivos vão até 23/09/2026). Linhas originais em
`fontes/b3/<TICKER>_linhas_COTAHIST_2003_2026.txt`; séries em
`series/<TICKER>_OFICIAL.csv`.

**Critério de escolha dos ativos** (declarado antes de ver resultado):
1. cobertura completa de 02/01/2003 a 23/09/2026 no COTAHIST;
2. **fator de cotação sempre igual a 1** em toda a série;
3. preço mínimo, depois do ajuste, acima de R$ 3, para o arredondamento de 1
   centavo não distorcer os retornos;
4. setores diferentes entre si.

O critério 2 elimina os bancos (BBAS3, BBDC4) e várias outras ações: até 2004
elas eram cotadas por lote de mil ações (fator 1000) e a transição para cotação
unitária veio acompanhada de grupamento, cuja razão exata não está em fonte
oficial acessível. Reconstruir isso seria suposição. ITUB4 foi descartado por
existir só desde 2009 (fusão Itaú Unibanco).

| Ativo | Setor | Pregões | Desdobramentos | Faixa de preço | Erro máx. de arredondamento |
|---|---|---|---|---|---|
| VALE3 | mineração | 5.883 | 3 | R$ 80,90 – 1.424,64 | 0,01% |
| USIM5 | siderurgia | 5.883 | 3 | R$ 3,82 – 212,85 | 0,14% |
| POMO4 | bens de capital | 5.883 | 5 | R$ 3,36 – 94,85 | 0,15% |

**Direção do ajuste de desdobramento.** A escala de uma série ajustada é
arbitrária. Para estes três o ajuste é **para frente** (o primeiro dia mantém o
preço real de 2003 e os posteriores são multiplicados), porque o ajuste
retroativo deixaria os preços antigos abaixo de R$ 1. O PETR4 continua com
ajuste **retroativo**, como na rodada 3, para não invalidar os resultados já
produzidos. Os retornos são idênticos nas duas direções.

**Desdobramentos** vindos do Yahoo (`fontes/yahoo/yahoo_desdobramentos_*.csv`),
conferidos contra os saltos de preço da própria B3: depois do ajuste não resta
nenhuma variação diária acima de 30% (exceto uma em USIM5, real).

**Proventos** (`series/proventos_<TICKER>.csv`): Yahoo, baixados em 23/09/2026,
usados só na camada 4. VALE3 39 eventos desde 2008, USIM5 24, POMO4 48. Valem
as mesmas limitações do item 3.

**Divergência contra o Yahoo** (retorno diário, dias com diferença > 0,5 p.p.):
VALE3 115, USIM5 206, POMO4 482 de ~5.880. A B3 é a fonte; o Yahoo serve de
conferência.

## 10. Referências bibliográficas (28/09/2026)

A busca de literatura, suas fontes (OpenAlex, BDTD/IBICT, Crossref, Unpaywall),
as consultas usadas e o critério de seleção estão em `../bibliografia/BUSCA.md`.
O arquivo `../bibliografia/candidatos.bib` traz as 43 referências conferidas.

## 10. Normas e documentos oficiais da FATEC-ID

**Atualizado em 01/10/2026**, com os arquivos baixados do site da faculdade.
Todos em `fontes/normas-fatec/`.

| Arquivo | O que é | Origem |
|---|---|---|
| `Manual-de-Normas-2026-2028.pdf` | **Manual vigente**, 45 páginas, biênio **2026-2027** | `fatecid.com.br/site/wp-content/uploads/2026/07/Revisao-manual-normas-Revisao-2026-2028.pdf`, baixado 01/10/2026 |
| `Manual-de-Normas-2021.pdf` | manual anterior, 47 páginas, biênio 2021-2022. **Superado** | já estava no repositório |
| `TG-Cronograma-2o-2026.pdf` | prazos do TG deste semestre | `.../uploads/2026/08/TG-Cronograma-de-Compromissos-2o-2026.pdf` |
| `Modelo-Apresentacao-FATEC.pptx` | modelo oficial de slides, 6 slides | Google Slides da página "Modelos e documentos", exportado em pptx |
| `Termo-Ciencia-Compromisso-2023.pdf` | termo obrigatório na entrega | `.../uploads/2023/07/TERMO-DE-CIENCIA-E-COMPROMISSO...pdf` |
| `Delineamento-Capitulo-II-2019.pdf` | estrutura obrigatória do Capítulo II | `.../downloads/tg/CAPITULO II_2019.pdf` |
| `Delineamento-Pesquisa-2019.pdf` | caderno dos delineamentos, 11 páginas | `.../downloads/tg/DELINEAMENTO DE PESQUISA PAISAGEM_2019.pdf` |
| `01_`, `02_`, `03_*.txt` | textos do site repassados pelo autor em 28/09 | cópia manual |

Páginas de origem: `fatecid.com.br/site/index.php/trabalho-de-graduacao/` (manual e
cronogramas) e `.../modelos-e-documentos/` (termos e modelo de apresentação).

**O que mudou do manual de 2021 para o de 2026**, conferido parágrafo a parágrafo:

- **Formatação gráfica: nada mudou.** Papel, margens, fonte, entrelinhas e
  numeração são idênticos, inclusive a observação "Não há afastamento entre
  parágrafos".
- **Ilustrações: idênticas**, com um acréscimo. O manual novo especifica que
  legenda e fonte usam **fonte tamanho 10, centralizado**.
- **Estrutura do texto: idêntica.** Introdução, Fundamentação, Procedimentos
  Metodológicos, Análise e Discussão dos Dados, Considerações Finais.
- **Introdução: "percurso metodológico" e "organização dos capítulos" deixaram
  de ser opcionais** e agora constam na lista de itens obrigatórios.
- **Citações: mudança de verdade.** O item 2.3.1 do manual novo determina, citando
  a NBR 6023:2025, que o sobrenome do autor vai em **caixa mista inclusive dentro
  dos parênteses**. Ou seja, `(Almeida, 2016)` no lugar de `(ALMEIDA, 2016)`.
  A OBSERVAÇÃO 1 estende a regra a pessoas jurídicas. A **lista de referências**
  continua com o sobrenome em caixa alta.
- **Citação direta curta: o ponto final vai depois do parêntese da autoria**, e
  não antes nem dentro das aspas (item 2.3.1, OBSERVAÇÃO 2).
- O manual novo detalha muito mais os casos de citação (um, dois, três e mais de
  três autores, mesmo sobrenome, várias obras, órgão governamental) e acrescenta
  seções de referência para artigo de periódico e produção fílmica.


## 11. Notícias e páginas usadas na introdução (05/10/2026)

> **Situação final em 05/10/2026:** a introdução foi refeita para abrir pela
> continuação de Almeida (2016) e pela crise. Ficaram no texto **só**
> `maximo2020` (Ibovespa −29,9% em março de 2020) e `b3Cotahist` (PETR4 −48,6%
> entre 30/12/2019 e 02/04/2020). As demais da tabela (`maximo2026`, `boehm2019`,
> `b3Investidores2026`, `cvm2018`, `diniz2025`) saíram do texto; as cópias foram
> mantidas em `bibliografia/` caso voltem a ser úteis, e as entradas continuam
> no `.bib` (entrada não citada não aparece na lista de referências).

Pedido do autor: a abertura da introdução estava sem referência. Autorizou usar
site, notícia e material institucional (não artigo) para contextualizar, com
fontes fortes (B3, BCB, CVM etc.). Como são **obras citadas no `.bib`**, as
cópias moram em `bibliografia/` (regra de procedência): páginas em
`bibliografia/paginas/`, PDF em `bibliografia/pdfs/`. Baixadas em 05/10/2026
(11:37, 12:32 e 12:36) com `curl`. Cada número foi conferido por busca de texto na cópia.

| Chave `.bib` | Fonte | Data | O que se usou (literal) | Cópia (sha256, início) |
|---|---|---|---|---|
| `maximo2026` | Wellton Máximo, Agência Brasil, "Bolsa tem pior mês desde 2023, e dólar sobe 1,82% em maio" | 29/05/2026 | "A bolsa de valores B3 fechou maio com queda acumulada de 7,22%, no pior desempenho mensal desde fevereiro de 2023"; "sétima semana consecutiva de perdas, em uma sequência iniciada após o Ibovespa renovar recordes históricos em abril. Desde então, o índice caiu da faixa de 187 mil pontos para a casa dos 173 mil pontos" | `paginas/AgenciaBrasil-2026-bolsa-pior-mes-maio.html` (`1d99022f`) |
| `boehm2019` | Camila Boehm, Agência Brasil, "Bolsa de Valores atinge 1 milhão de investidores pessoa física" | 18/05/2019 | "No mês de abril, a [...] B3 alcançou mais de 1 milhão de investidores pessoa física no mercado de renda variável. Foram 1.046.244 investidores [...] Em abril no ano passado, eram 663.270 investidores pessoa física" | `paginas/AgenciaBrasil-2019-1-milhao-investidores.html` |
| `b3Investidores2026` | B3, "Avanço dos ETFs destaca evolução do investidor pessoa física na B3" | 06/07/2026 | "no primeiro trimestre, a B3 contabilizou 5,6 milhões de investidores pessoa física em renda variável"; "As ações à vista bateram 4 milhões de investidores" | `paginas/B3-2026-avanco-etfs-investidor-pf.html` (`bd1886f4`) |
| `cvm2018` | CVM, Programa Bem-Estar Financeiro, módulo 6, "Introdução aos investimentos" (apostila, 26 p.) | 2018 | p. 8: renda fixa, "a remuneração, ou sua forma de cálculo, é previamente definida no momento da aplicação"; "As taxas de referências mais utilizadas nos títulos de renda fixa pós-fixados são a SELIC e a DI"; p. 9: renda variável, "o investidor não sabe, de antemão, qual será a rentabilidade"; "o exemplo mais conhecido [...] são as ações"; p. 10: risco é "a chance de o retorno obtido em um investimento ser diferente do esperado" | `pdfs/CVM-2018.pdf` (`74e4b7ef`) |
| `maximo2020` | Wellton Máximo, Agência Brasil, "Bolsa cai 30%, e dólar sobe 16% em março com pandemia de coronavírus" | 31/03/2020 | "A bolsa de valores caiu 29,9% e teve o pior trimestre da história" | `paginas/AgenciaBrasil-2020-bolsa-cai-30-marco.html` (`e8bc1f9f`) |
| `diniz2025` | Augusto Diniz, InfoMoney, "60% das negociações na B3 já utilizam algum modelo de algoritmo, diz superintendente" | 28/01/2025 | Fabio Perdiz, superintendente de monitoramento da negociação da B3: "entre 50% e 60% da negociação hoje é feita por algoritmo. Antes da pandemia, esse número ficava entre 20% e 40%" | `paginas/Diniz-2025-infomoney-algoritmos-b3.html` (`fdee7c1f`) |
| `b3Cotahist` | B3, Séries históricas de cotações (item 1 deste arquivo) | obtido em 21/09/2026 | variações da PETR4 na introdução, **de fechamento a fechamento** em `series/PETR4_OFICIAL.csv`: pandemia 30,18 (30/12/2019) → 15,51 (02/04/2020) = −48,6%; 2025: 36,19 (30/12/2024) → 30,82 (30/12/2025) = −14,8%; 2026: 30,82 → 48,00 (21/09/2026, último pregão da série) = +55,7%. Conta refeita com `awk` sobre o CSV. (A tabela "Ano a ano" do RELATORIO da rodada 3 dá −15,4% para 2025 porque mede a compra na abertura do 1º dia do teste, não o fechamento anterior.) | — |

Observações:
- O 50% a 60% é **declaração de um executivo da B3** relatada por jornal, não
  estatística publicada pela bolsa. O texto do TG atribui assim.
- A notícia do circuit breaker de 09/03/2020 (Agência Brasil) chegou a ser usada
  e saiu no mesmo dia, a pedido do autor (termo difícil para a abertura).
- Saíram no mesmo dia, por pedido do autor: ANBIMA (Raio X do Investidor) e a
  notícia da crise de 2008 (Agência Brasil, 30/12/2008). Ele quer o cenário
  **recente** (pandemia, 2025–2026), baseado em Almeida (2016) sem copiar a
  abertura dele, que é pela crise de 2008. Fontes só oficiais ou a agência
  pública de notícias.
- O `cvm2018` é material didático oficial; a primeira versão é de 2018 e a URL
  é a do portal atual (gov.br/investidor).

## 12. Definições de Sharpe, Calmar e queda máxima (05/10/2026)

Pedido do autor: explicar os índices com a documentação do MetaTrader 5 e com
os próprios autores. Texto no Cap. II (2.3.2). As fórmulas seguem o código
(`Include/Desempenho.mqh`: Sharpe = média do excesso diário sobre a Selic /
desvio-padrão × √252; Calmar = retorno anualizado da camada 3 / queda máxima).

| Chave `.bib` | Fonte | Usado para | Cópia (sha256, início) |
|---|---|---|---|
| `metaquotesRelatorio` | MetaQuotes, "Relatório de teste", Ajuda do MetaTrader 5 (pt), sem data | Sharpe: "(Rendimento - Rendimento Livre de Risco)/Desvio Padrão do Rendimento. No testador de estratégia, assume-se que o rendimento livre de risco é zero"; rebaixamento relativo: "maior queda do saldo entre o máximo local e o próximo mínimo local, em porcentagem"; fator de recuperação: "relação entre lucro recebido e drawdown máximo" | `bibliografia/paginas/MetaQuotes-relatorio-de-teste-MT5.html` (`c96ea99c`) |
| `sharpe1994` | W. F. Sharpe, "The Sharpe Ratio", *The Journal of Portfolio Management*, 21(1):49–58, 1994; reimpressão no site do autor em Stanford | retorno diferencial d = fundo − referência; S = média(d)/desvio(d); "It is common practice to 'annualize'"; "The t-statistic will equal the Sharpe Ratio times the square root of T" | `bibliografia/paginas/Sharpe-1994-the-sharpe-ratio.html` (`51c9cc84`) |

O Calmar não tem citação de autor: o texto original (Young, 1991, revista
*Futures*) não está disponível. Ele é apresentado pela analogia com o fator de
recuperação do relatório do MT5, que é a mesma razão com o lucro no lugar do
retorno anualizado.

Descartados no mesmo dia: o glossário do portal Bora Investir (B3) e o artigo
de Magdon-Ismail e Atiya (2004), por preferência do autor; o Corporate Finance
Institute bloqueia download (HTTP 403).
