# TG em LaTeX — Previsão e Análise de Tendências no Mercado de Ativos

Reconstrução em LaTeX (abnTeX2) do Projeto de Trabalho de Graduação da FATEC
Indaiatuba (ADS), a partir do PDF original `Pre_ADS`, seguindo o
**Manual de Normas FATEC-ID (2021)** e a ABNT.

## Como compilar

Requisitos: TeX Live com `abntex2`, `abntex2cite` e `bibtex` (já instalados).

```bash
make          # pdflatex + bibtex + 2x pdflatex -> main.pdf
make clean    # remove artefatos auxiliares
```

Ou manualmente: `pdflatex main` → `bibtex main` → `pdflatex main` ×2.
Edição com vimtex: o arquivo mestre é `main.tex`.

## Estrutura

```
tg/
├── main.tex                 # mestre: classe abnTeX2, preâmbulo, \input das partes
├── referencias.bib          # 22 referências (BibTeX, estilo alf autor-data)
├── Makefile
├── figuras/                 # fig01..fig10 (extraídas do PDF) + _raw/ (originais)
└── conteudo/
    ├── capa.tex             # Manual 4.1.2
    ├── folharosto.tex       # Manual 4.1.4
    ├── resumo.tex / abstract.tex
    ├── siglas.tex
    ├── cap0-introducao.tex  # 1 Contextualização (1.1–1.6) + Tabela 1
    ├── cap1-fundamentacao.tex # 2 Fundamentação (2.1–2.10) + Figs 1–7 + Tabs 2–3
    ├── cap2-metodologia.tex # 3 Metodologia (3.1–3.8) + Figs 8–10 + Tabs 4–5
    └── apendice-a.tex       # código MQL5 (lstinputlisting de ../MediasMoveis2)
```

## Regras de formatação aplicadas (Manual FATEC)

- Margens 3/2/3/2 cm; recuo 1,25 cm; espaçamento 1,5; sem espaço entre parágrafos.
- Fonte Times; títulos 14 negrito (só inicial maiúscula, à esquerda); subtítulos 12.
- Pré-textuais e divisões (RESUMO, SUMÁRIO, CAPÍTULO I…) centralizados, caixa-alta.
- Paginação só com o número, canto superior direito, a partir da introdução.
- Ilustrações/tabelas: legenda em cima, "Fonte:" embaixo, tamanho 10.
- Citações ABNT autor-data (abntex2cite, estilo `alf`).

## Pendências / pontos a revisar (ver também os comentários `% Nota` no .bib)

1. **Estrutura de numeração:** o original numera "1 Contextualização" dentro da
   Introdução; o *modelo* do manual deixa a Introdução sem número e começa em
   "1 Fundamentação". Aqui foi replicado o original — decidir se alinha ao manual.
2. **Citações a reconciliar com a lista de referências:**
   - BCB/COPOM: o texto usa `(BCB, 2025)`, `(COPOM, 2025)`; as entradas são
     `BRASIL. Banco Central do Brasil` sem data → saem verbosas e com letra de
     desambiguação. Padronizar.
   - `(METATRADER, 2010)` no texto vs referência `METAQUOTES (2024)`.
   - Citados sem referência na lista: **Bertini (2024)**, **Flávio (2023)**,
     **Dey (2016, apud Silva)** — hoje em texto puro. Adicionar referências?
   - **Anderson (1993)** foi citado no corpo mas faltava na lista; entrada
     reconstruída no `.bib` (confirmar dados).
3. **Bug do original corrigido:** havia duas "Figura 7". Aqui as figuras numeram
   1–10 automaticamente (10 no total).
4. **Tamanho dos títulos:** o Manual pede 14 pt; está em **13 pt** para aproximar
   do PDF original. Ajustável num único ponto (`\chaptitlefont` /
   `\ABNTEXchapterfont` no `main.tex`) — trocar para 12 ou 14 se preferir.
5. **Folha de aprovação** (banca): obrigatória só na versão final; deixei o
   `\input` comentado no `main.tex`.
