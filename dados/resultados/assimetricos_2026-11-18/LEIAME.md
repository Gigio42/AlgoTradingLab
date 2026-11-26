# GARCH 500 com GJR, EGARCH, t de Student, janela expansiva e BIC (18/11/2026)

**Fora do TG.** Estudo pedido pelo autor em 17/11/2026; o relatório é
`ia/relatorios/assimetricos/relatorio.html`. O protocolo (variantes, períodos,
critério) foi escrito antes das simulações: `PROTOCOLO.md`.

## Conteúdo

| Pasta/arquivo | O que é |
|---|---|
| `PROTOCOLO.md` | o que se roda e o que se mede, escrito antes |
| `validacao/` | saída do `ferramentas/ValidacaoAssimetrico.mq5` (resumo + CSVs) |
| `calibracao/<variante>/PETR4_<cal>.csv` | grade de 156 configurações só compra por variante e calibração (uma linha de métricas por passagem) |
| `grades/base_C4_*.txt` | as sub-grades exatamente como foram ao testador (amostra da base na C4) |
| `escolhas/<variante>_<cal>.txt` | GS, GC e a gêmea do GS (`escolher.sh ... so_compra`) |
| `testes/metricas_AS_*.csv`, `testes/curva_AS_*.csv` | testes fora da amostra, rótulo `AS_<variante>_<teste>_<GS/GC/GSgemeo>`, e as médias móveis `AS_MM_<teste>` |
| `cru/testes.csv` | um teste por linha, etapas bruto → + custos → + proventos → + Selic, queda e volatilidade de cada etapa (`assimetricos_resumo.sh`) |
| `cru/pares.csv` | grade inteira: cada variante contra a base, passagem a passagem |
| `cru/conferencias.txt` | as conferências da seção 6 do protocolo |
| `execucao.log` | log da bateria |

## Validação das partes novas (antes das simulações)

`bash ferramentas/scripts/validar_assimetrico.sh` (cerca de 1 min, prefixo
`~/.wine-mt5`). Resultado em `validacao/valid_assim_resumo.txt`: **27 critérios,
0 falhas**. Os principais, copiados do arquivo:

- **Recuperação** (n = 3000): GJR α 0,028, γ 0,123, β 0,883 (verdade 0,03 / 0,12 /
  0,88); EGARCH α 0,145, γ −0,080, β 0,957 (verdade 0,15 / −0,08 / 0,96); com t,
  ν 5,85 e 5,93 (verdade 6).
- **Sem assimetria no dado**, γ mediano 0,0012 (GJR) e −0,0019 (EGARCH).
- **Consistência**: GJR com γ = 0 dá a mesma log-verossimilhança do GARCH
  (2582,84236679); previsão de um passo igual à fórmula nos três modelos; E|z| da
  t padronizada conferida por Monte Carlo (0,74847 × 0,75000 para ν = 6).
- **Curva de impacto**: queda de 2 desvios leva a volatilidade do dia seguinte a
  2,46% (GJR) e 2,37% (EGARCH), alta de 2 desvios a 2,03% e 2,02%.
- **PETR4_OFICIAL**, 86 janelas de 500 log-retornos: γ com o sinal do efeito
  alavanca em 84% (GJR) e 87% (EGARCH); AIC menor que o do GARCH em 65% e 74%;
  t melhor que a normal em 91%; razão de verossimilhança GJR × GARCH
  significativa a 5% em 50% das janelas.
- **AIC × BIC** (200 séries de 240 retornos, seleção do EA com constante): ruído
  branco, ordem certa 139 (AIC) × 185 (BIC); AR(1) φ 0,3, 108 × 135.
- **Janela expansiva**: sem mudança no processo, o desvio da estimativa cai para
  0,330 do da janela móvel (teoria ≈ 0,35); com uma quebra nos últimos 500 dias,
  erro 0,003 (móvel) × 0,298 (expansiva).

Teste no testador (17/11): a janela expansiva cresceu uma barra por pregão
(4209 a 4454 em 2017), a móvel ficou em 240. `regressao_codigo.sh`: idêntica
byte a byte (métricas, curvas e traços dos 13 casos). Apêndices A e B: listagens
idênticas às de antes (`cmp`).

## Conferências da bateria

Em `cru/conferencias.txt` (refeito pelo `assimetricos_resumo.sh`):

- 156 passagens em cada grade;
- `base` igual, passagem a passagem, ao `janelas_garch_2026-11-13/calibracao/500/`
  nas calibrações em comum (C4: 156 pares, 0 diferentes);
- retorno com custos e Selic recalculado da curva × gravado pelo EA: maior
  diferença 0,0010 p.p.; etapa final × `ret_completo`: 0,0000 p.p.;
- janela média do ARIMA 240 nas variantes móveis e maior nas expansivas; γ médio
  positivo no GJR e negativo no EGARCH.

<!-- RESULTADOS: preenchido no fim da bateria -->

## Para refazer

```bash
bash ferramentas/scripts/validar_assimetrico.sh
bash ferramentas/scripts/assimetricos.sh dados/resultados/assimetricos_2026-11-18   # ~15 h (estimativa)
bash ferramentas/scripts/assimetricos_relatorio.sh                                   # resumo + HTML
```

As grades e testes já gravados são pulados; `VARS`, `CALS` e `PULAR` restringem.
Os EAs têm de estar compilados no prefixo `~/.wine-mt5-novo` com as partes novas.
