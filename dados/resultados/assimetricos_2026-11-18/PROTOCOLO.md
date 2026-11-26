# Protocolo: GARCH 500 com assimetria, t de Student, janela expansiva e BIC (18/11/2026)

Escrito **antes** de rodar as simulações. Pedido do autor (17/11/2026): "testes
considerando GARCH com janela de 500, separadamente e depois de forma unida:
modelos assimétricos, t de Student, janela expansiva, AIC e BIC, no período de
todos os testes e de 2005 a 2010", com testes de que as partes novas funcionam
conforme a teoria **antes** das simulações, sem alterar o texto do TG, num
relatório HTML separado que compare também custo, provento e Selic.

**Fora do TG.** Nada daqui entra em `tg/` sem pedido.

## 1. Partes novas do modelo (experimentais, todas `//@omitir`)

| Input | Valores | Onde |
|---|---|---|
| `ModeloGARCH` | 0 simétrico (o do TG), 1 GJR-GARCH(1,1) (Glosten, Jagannathan e Runkle, 1993), 2 EGARCH(1,1) (Nelson, 1991) | `robos/Include/GarchAssimetrico.mqh` |
| `DistribuicaoGARCH` | 0 normal, 1 t de Student (já existia, 13/10) | `GarchDistribuicao.mqh` |
| `Inicio_Janela_Expansiva` | 0 = janela móvel de 240; data = o ARIMA (estimação e seleção) usa todas as barras fechadas desde essa data | `JanelaARIMA()` no EA |
| `SelecaoPorBIC` | false AIC (o do TG), true BIC (já existia) | `SelecaoModelo.mqh` |

O GARCH continua sobre os 500 últimos resíduos (`Janela_GARCH=500`) em todas as
variantes, inclusive na expansiva: só o ARIMA expande.

Validação teórica antes das simulações: `validacao/` (script
`ferramentas/ValidacaoAssimetrico.mq5`, rodado por
`ferramentas/scripts/validar_assimetrico.sh`), 27 critérios, todos passaram em
18/11 (ver `LEIAME.md`). Teste no testador: a janela expansiva cresceu uma barra
por pregão (4209 a 4454 em 2017), GJR e EGARCH rodaram o ano inteiro.
Regressão `regressao_codigo.sh`: idêntica byte a byte antes e depois.
Apêndices A e B: listagens idênticas.

## 2. Variantes

| Rótulo | ModeloGARCH | Distribuição | Janela do ARIMA | Critério |
|---|---|---|---|---|
| `base` | simétrico | normal | móvel 240 | AIC |
| `gjr` | GJR | normal | móvel 240 | AIC |
| `egarch` | EGARCH | normal | móvel 240 | AIC |
| `t` | simétrico | t | móvel 240 | AIC |
| `exp` | simétrico | normal | expansiva desde 03/01/2000 | AIC |
| `bic` | simétrico | normal | móvel 240 | BIC |
| `gjr_tudo` | GJR | t | expansiva | BIC |
| `egarch_tudo` | EGARCH | t | expansiva | BIC |

Separadamente = uma mudança por vez sobre a `base`. Unidas = as quatro de uma
vez, uma vez com cada modelo assimétrico.

## 3. Períodos (calibração → teste)

| Teste | Operação | Calibração (escolhe GS e GC) |
|---|---|---|
| P0510 | 03/01/2005 a 30/12/2010 (pedido do autor) | C0: 02/01/2002 a 30/12/2004 |
| T1 | 02/01/2007 a 30/12/2011 | C1: 02/01/2004 a 29/12/2006 |
| T2 | 02/01/2013 a 30/12/2016 | C2: 04/01/2010 a 28/12/2012 |
| R6 | 02/01/2017 a 30/12/2024 | C4: 02/01/2014 a 30/12/2016 |
| T3 | 02/01/2025 a 19/09/2026 | C3: 03/01/2022 a 31/12/2024 |
| L1 | 03/01/2005 a 18/09/2026 | as escolhas de C2, como na refação de 05/10 (a calibração fica dentro do período: L1 não é fora da amostra) |

Mesmos pares calibração → teste do TG (`refeito_2026-10-05`), mais o P0510. A
calibração de três anos imediatamente antes do teste segue o protocolo da
rodada 3.

**Dados**: `PETR4_DESDE1999` (B3 COTAHIST, igual ao `PETR4_OFICIAL` nas 5881
datas em comum, conferido em 18/11) em **todos** os testes do ARIMA, com o
testador começando em 03/01/2000 e `Inicio_Operacao` no início de cada período.
Assim as oito variantes veem o mesmo dado, e a expansiva tem o histórico desde
2000. Antes de `Inicio_Operacao` o EA só acumula histórico.

**Grade**: as 156 configurações só compra das sub-grades da rodada 3 (`arima`,
`filtro_abs`, `filtro_pct`, `targ`, `ft_abs`, `ft_pct`), ARIMA com
`Janela_Estimacao=240`, como no estudo das janelas do GARCH (13/11). Cada linha
com a faixa explícita e `N` (`explicitar`), `.set` e cache apagados antes de
cada otimização. **Conferir 156 passagens em cada grade.**

## 4. Escolha e testes

- `escolher.sh <calibração> so_compra`: **GS** (maior Sharpe) e **GC** (maior
  Calmar) entre as passagens com GARCH, e a **gêmea** do GS (o mesmo ARIMA sem
  GARCH). Critério declarado antes, o mesmo do TG.
- Cada escolha roda no teste com a variante dela (os inputs da variante são
  fixos, não escolhidos). Médias móveis (MM 10/20, só compra, 95% do capital,
  custo 0,03% por lado) uma vez por período, iguais para todas as variantes.
- Proventos da B3 (`proventos_PETR4.csv`, o do Cap. III desde 27/10), Selic
  diária do BCB, custo B3 de 0,03% por lado.

## 5. O que se mede

Da curva diária de cada teste (`Desempenho.mqh`), na ordem do Cap. III:
**bruto → + custos → + proventos → + Selic** (`camadas_ordem_proventos.sh`), com a
queda máxima e a volatilidade anualizada de cada etapa. Referências: PETR4 pela
variação do preço e com proventos, e todo o capital na Selic.

Pergunta principal (escopo do TG: risco): cada mudança, sozinha ou junta,
**reduz a volatilidade e a queda máxima** do ARIMA-GARCH em relação à `base`?
Pergunta secundária: e o retorno em cada etapa? Diferenças pequenas são tratadas
como empate; nenhuma afirmação de significância sem teste.

## 6. Conferências previstas

1. `base` nas calibrações C1, C2, C4 e C3 igual, passagem a passagem, ao
   `janelas_garch_2026-11-13/calibracao/500/` (mesma configuração, outro início
   do testador e outro símbolo com o mesmo dado).
2. MM igual às curvas de `refeito_2026-10-05/proventos_b3/` nos períodos em
   comum.
3. Na variante `exp`, `janela_arima_media` das métricas maior que 240 e
   crescente com a data do teste; nas outras, 240.
4. Nas variantes `gjr`/`egarch`, `gama_medio` com o sinal do efeito alavanca
   (GJR > 0, EGARCH < 0).

## 7. Limitações declaradas antes

- **Proventos de 2002**: o `proventos_PETR4.csv` começa em 28/03/2003. Só a
  camada 4 da calibração C0 fica sem os proventos de 2002; a escolha usa o
  Sharpe da camada 3 e não muda. O teste P0510 começa em 2005 e não é afetado.
- A janela expansiva começa em 03/01/2000 porque é a primeira data que o
  testador entrega (histórico desde 1º de janeiro do ano anterior ao início do
  teste; a série começa em 04/01/1999).
- Um ativo, uma grade, um critério: o mesmo alcance das rodadas anteriores.
