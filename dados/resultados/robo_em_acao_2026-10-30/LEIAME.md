# Dados das figuras do robô funcionando (30/10/2026)

Pedido do autor: gráficos com dados reais que mostrem o ARIMA-GARCH operando.
As figuras são a parte 2 de `apresentacao/graficos_metodos/` (08 a 14). **Não
estão no TG.**

## Procedência

- **Fonte:** o traço por barra gravado pelo próprio robô na refação de
  05/10/2026, `dados/resultados/refeito_2026-10-05/traco_demo/`
  (`traco_demo_GARCH.csv` e a gêmea sem GARCH, `traco_demo_ARIMA.csv`). Os
  sha256 conferem com os do LEIAME daquela pasta. Nada foi rodado de novo.
- **Configuração:** ARIMA-GARCH Sharpe (GS) da calibração C4 (2014–2016):
  filtro, percentil 70, zera no veto, janela 240, com constante, só compra.
  PETR4_OFICIAL, 01/07/2019 a 29/06/2021. É uma execução própria, começando em
  07/2019, e não um recorte do teste de 2017–2024: a posição de cada dia pode
  diferir da daquele teste.
- **Figura 14:** usa também os parâmetros do GARCH e o maior resíduo da janela
  da validação, lidos de `../metodos_ilustrados_2026-10-30/resumo.txt`.
- **Programa:** `ferramentas/scripts/robo_em_acao.sh` (awk, só lê os arquivos).
  Antes de tudo confere que as duas execuções têm as mesmas datas e a mesma
  previsão do ARIMA em todas as linhas.

## Como as colunas do traço foram lidas

- `data` é o pregão em que a decisão é tomada (na abertura), e `preco` é o
  fechamento do pregão **anterior**. Por isso o retorno realizado do pregão da
  linha i é ln(preco[i+1] / preco[i]); a última linha não tem.
- `prev_dif` é o retorno previsto para o pregão, com d = 1 ou d = 0
  (`PrevisaoDoRetorno` no EA).
- `ordem_enviada` só vale 1 quando houve **compra ou venda nova**; fechar a
  posição não conta (`CNegociacao::Fechar` não incrementa o contador). As saídas
  foram contadas pela passagem de `posicao` de 1 para 0.

## Conferências

- A regra do filtro refeita a partir das colunas ("veta se `vol_prevista` >
  `limiar`") coincide com o `vetou` registrado em todos os 496 pregões.
- Com GARCH, o robô nunca está comprado num pregão em que a gêmea está fora
  (0 pregões), como deve ser: os sinais são os mesmos e o GARCH só retira.

## Arquivos

| Arquivo | Conteúdo | Figura |
|---|---|---|
| `valores.tex` | números citados nas figuras (`\vR...` com vírgula, `\pR...` com ponto) | todas |
| `dia_a_dia.csv` | uma linha por pregão: preço, retorno realizado, previsão, σ, limiar, ordens, coeficientes, α, β, decisões e posições das duas versões | 9 a 13 |
| `prev_acerto.csv`, `prev_erro.csv` | previsão × realizado, separados por acerto da direção | 9 |
| `decisao_compra.csv`, `decisao_venda.csv`, `decisao_vetada.csv` | previsão × (σ prevista ÷ limiar), por decisão registrada | 12 |
| `memoria_impacto_*.csv`, `memoria_decaimento_*.csv` | curva de impacto e decaimento do choque (`Val` = janela da validação, `Rob` = 19/02/2021) | 14 |
| `faixas_*.csv`, `dias_vetados.csv`, `entradas_*.csv` | trechos com d = 0, períodos comprados, vetos e entradas, em forma de lista (para consulta; as figuras leem o `dia_a_dia.csv`) | — |

Observações que surgiram ao montar os gráficos: `ia/INCERTEZAS.md`, item 83.
