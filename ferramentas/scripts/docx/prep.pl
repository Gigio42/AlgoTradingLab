#!/usr/bin/perl
# Pré-processa uma CÓPIA dos .tex do TG para o pandoc (nunca os originais).
# Uso: perl prep.pl main.aux citas.tsv arquivo.tex...
#
# - Os números de \ref e das legendas vêm do main.aux do pdflatex, então são os
#   mesmos do PDF.
# - As citações usam as formas que o abnTeX2 gravou no .bbl (citas.tsv, feito
#   pelo bbl.pl), também iguais às do PDF.
# - grafico e quadro viram figure; o fatec.lua dá a cada tipo o seu estilo de
#   legenda, que alimenta a sua lista (figuras, quadros, gráficos).
# - O que o pandoc não entende vira marcador @@...@@ ou EQNUM..EQNUM, que o
#   fatec.lua troca por estilo, campo ou quebra de seção do Word.
use strict; use warnings; use utf8;
binmode STDERR, ':utf8';
my ($aux, $citas, @arquivos) = @ARGV;

my %num;
open my $A, '<:utf8', $aux or die "$aux: $!";
while (<$A>) { $num{$1} = $2 if /^\\newlabel\{([^}]+)\}\{\{([^}]*)\}/; }
close $A;

my %cit;
open my $C, '<:utf8', $citas or die "$citas: $!";
while (<$C>) { chomp; my ($k, @v) = split /\t/; $cit{$k} = \@v; }
close $C;

# O pandoc descarta as larguras p{..} das colunas. Elas viram uma marca
# LARGURAS..FIM (fração dos 16 cm de texto; 0 = coluna l, c ou r), que vai na
# legenda das ilustrações ou num parágrafo antes da tabela solta. O fatec.lua
# tira a marca e aplica as larguras.
my $ESPEC = qr/\\begin\{tabular\}\{((?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*)\}/;
sub larguras {
  my ($spec) = $_[0] =~ $ESPEC or return '';
  $spec =~ s/[>@]\{(?:[^{}]|\{[^{}]*\})*\}//g;
  my @w;
  for ($spec =~ /([lcr]|p\{[^}]*\})/g) {
    if (/p\{([0-9.]+)cm\}/) { push @w, sprintf('%.4f', $1 / 16) }
    elsif (/p\{([0-9.]+)\\(?:textwidth|linewidth)\}/) { push @w, sprintf('%.4f', $1) }
    else { push @w, '0' }
  }
  return (grep { $_ ne '0' } @w) ? 'LARGURAS' . join('_', @w) . 'FIM' : '';
}

my %prefixo = (grafico => 'Gráfico', quadro => 'Quadro', figure => 'Figura', table => 'Tabela');
sub legenda {
  my ($amb, $c) = @_;
  my ($l) = $c =~ /\\label\{([^}]+)\}/;
  die "ilustração sem \\label ($amb)\n" unless defined $l && exists $num{$l};
  my $larg = larguras($c);
  $larg .= ' ' if $larg;
  $c =~ s/\\caption\{/\\caption{$larg\\textbf{$prefixo{$amb} $num{$l} –} /;
  my $novo = $amb eq 'table' ? 'table' : 'figure';
  return "\\begin{$novo}$c\\end{$novo}";
}
sub tabela_solta {   # tabela fora de ilustração (lista de siglas)
  my ($float, $tab) = @_;
  return $float if defined $float;
  my $m = larguras($tab);
  return ($m ? "\n\n\@\@$m\@\@\n\n" : '') . $tab;
}
sub citar {   # \cite -> (Implícita, ano; ...) e \citeonline -> Explícita (ano)
  my ($tipo, $pag, $chaves) = @_;
  my @k = split /\s*,\s*/, $chaves;
  for (@k) { die "citação sem entrada no .bbl: $_\n" unless $cit{$_} }
  my $p = defined $pag && length $pag ? ", $pag" : '';
  return '(' . join('; ', map { "$cit{$_}[1], $cit{$_}[2]" } @k) . "$p)" if $tipo eq 'cite';
  return join(', ', map { "$cit{$_}[0] ($cit{$_}[2]" . ($_ eq $k[-1] ? $p : '') . ')' } @k);
}

for my $f (@arquivos) {
  local $/; open my $F, '<:utf8', $f or die "$f: $!"; my $t = <$F>; close $F;
  $t =~ s/(?<!\\)%.*$//mg;                                            # comentários
  $t =~ s/\\begin\{(grafico|quadro|figure|table)\}(.*?)\\end\{\1\}/legenda($1, $2)/gse;
  $t =~ s/(\\begin\{(?:figure|table)\}.*?\\end\{(?:figure|table)\})|($ESPEC)/tabela_solta($1, $2)/gse;
  $t =~ s/\\ref\{([^}]+)\}/exists $num{$1} ? $num{$1} : die "\\ref sem número: $1\n"/ge;
  $t =~ s/\\cline\{[^}]*\}//g;                                        # o pandoc imprimiria "2-7"
  $t =~ s/\\(cite|citeonline)\s*(?:\[([^]]*)\])?\{([^}]+)\}/citar($1, $2, $3)/ge;
  # equações numeradas por capítulo, (1.1), (1.2)... como o abnTeX2 faz
  if ($f =~ /cap(\d)-/) { my ($c, $n) = ($1, 0);
    my $eq = sub { my $e = shift; $e =~ s/\\label\{[^}]*\}//g; $e =~ s/^\s+|\s+$//g; $n++;
                   return "\n\nEQNUM$c.${n}EQNUM \$$e\$\n\n" };
    $t =~ s/\\begin\{equation\}(.*?)\\end\{equation\}/$eq->($1)/gse; }
  $t =~ s/\\setdiv\{([^}]*)\}/\n\n\@\@DIV $1\@\@\n\n/g;
  # espaços verticais da capa e da folha de rosto (o fatec.lua converte em altura)
  $t =~ s/\\vspace\{([0-9.]+)\\textheight\}/\n\n\@\@ESPACO $1\@\@\n\n/g;
  $t =~ s/\\vspace\{\\onelineskip\}/\n\n\@\@ESPACO linha\@\@\n\n/g;
  $t =~ s/\\vfill\b/\n\n\@\@VFILL\@\@\n\n/g;
  $t =~ s/\\begin\{(?:capa|folhaderosto)\}/\n\n\@\@CAPA\@\@\n\n/g;
  $t =~ s/\\end\{(?:capa|folhaderosto)\}/\n\n\@\@FIMCAPA\@\@\n\n/g;
  $t =~ s/\\hfill\\begin\{minipage\}\{[^}]*\}\}?(.*?)\\end\{minipage\}/\n\n\@\@NATUREZA\@\@\n\n$1\n\n\@\@FIMNATUREZA\@\@\n\n/gs;
  $t =~ s/\\begin\{resumo\}\[([^]]*)\]/\n\n\@\@PRETIT $1\@\@\n\n/g;
  $t =~ s/\\begin\{resumo\}/\n\n\@\@PRETIT RESUMO\@\@\n\n/g;
  $t =~ s/\\end\{resumo\}/\n\n\@\@QUEBRA\@\@\n\n/g;
  $t =~ s/\\chapter\*\{Lista de siglas\}/\n\n\@\@PRETIT LISTA DE SIGLAS\@\@\n\n/g;
  $t =~ s/\\(?:clearpage|cleardoublepage|newpage)\b/\n\n\@\@QUEBRA\@\@\n\n/g;
  $t =~ s/\\listoffigures\*?/\n\n\@\@LISTA LOF\@\@\n\n/g;
  $t =~ s/\\listofquadros\*?/\n\n\@\@LISTA LOQ\@\@\n\n/g;
  $t =~ s/\\listofgraficos\*?/\n\n\@\@LISTA LGR\@\@\n\n/g;
  $t =~ s/\\listoftables\*?/\n\n\@\@LISTA LOT\@\@\n\n/g;
  $t =~ s/\\tableofcontents\*?/\n\n\@\@LISTA TOC\@\@\n\n/g;
  $t =~ s/\\textual\b/\n\n\@\@SECAO\@\@\n\n/g;                        # fim dos pré-textuais
  $t =~ s/\\addcontentsline\{[^}]*\}\{[^}]*\}\{[^}]*\}//g;
  $t =~ s/\\pdfbookmark\[[^]]*\]\{[^}]*\}\{[^}]*\}//g;
  if ($f =~ /apendice-([a-z])/) { my $L = uc $1;
    $t =~ s/\\chapter\{(.*?)\}\n/\\chapter*{APÊNDICE $L – $1}\n/; }
  open $F, '>:utf8', $f or die; print $F $t; close $F;
}
