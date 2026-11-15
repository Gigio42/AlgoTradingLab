# GARCH 1000 só com filtro e ajuste, mantendo × encerrando no veto (15/11/2026) — estudo, NÃO está no TG

Pedido do autor em 15/11/2026: depois de terminar a bateria com o GARCH em 500
(`../filtro_ajuste_500_2026-11-13/`), fazer o mesmo com 1000. Mesmo protocolo,
só com `Janela_GARCH=1000`. Protocolo escrito antes de rodar: `PROTOCOLO.md`.
Com 1000, as outras ações ficam sem o par C1/T1.

**Estado: completo** (15/11/2026, 2h43 a 4h24). 52 otimizações com 52 passagens e
os testes da PETR4. Conferências em `../filtro_ajuste_500_2026-11-13/cru/conferencias.txt`,
todas bateram.

Mesma organização da pasta de 500: `M/` e `E/`, cada uma com `calibracao/`,
`escolhas/`, `testes/` e `relatorios_mt5/`.

- **Números do relatório:** saem junto com os de 500, em
  `../filtro_ajuste_500_2026-11-13/cru/`, gerados por `filtro_ajuste_500_dados.sh`.
- **Relatório:** `ia/relatorios/filtro-ajuste-500-1000/`.

Refazer:

```bash
JG=1000 bash ferramentas/scripts/filtro_ajuste_500.sh dados/resultados/filtro_ajuste_1000_2026-11-15 grades testes
```

O script pula as janelas já prontas.
