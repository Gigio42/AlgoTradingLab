# Configuração do latexmk (usado pela extensão LaTeX Workshop do VS Code).
# Faz a compilação automática do editor sair igual à do Makefile: depois do
# bibtex, ajusta as citações do .bbl às regras da FATEC-ID (caixa mista dentro
# do parêntese, NBR 6023:2025). Sem isto, o PDF gerado pelo editor sai com
# "(ALMEIDA, 2016)" em caixa alta.
$pdf_mode = 1;
$bibtex = 'bibtex %O %S && perl -i ../ferramentas/scripts/citacoes_abnt.pl %B.bbl';
