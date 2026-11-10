#!/usr/bin/perl
# Ajustes no XML do .docx que o pandoc não faz (chamado pelo converter.sh com a
# pasta do .docx já descompactado).
# Uso: perl posprocessar.pl <pasta> <título> <autores>
#
# 1. Quebra de seção: o pandoc a deixa num parágrafo vazio próprio, que pode
#    sobrar sozinho numa página em branco. Ela passa para o parágrafo anterior.
# 2. Marcas antes de tabelas: quadro em grade fechada, lista de siglas sem borda.
# 3. Última seção que abre com "CAPÍTULO N": primeira página sem número.
# 4. Numeração das linhas do código dos apêndices, como no PDF.
# 5. Título e autores nas propriedades do arquivo.
use strict; use warnings; use utf8;
my ($dir, $titulo, $autores) = @ARGV;
binmode STDOUT, ':utf8'; binmode STDERR, ':utf8';

sub ler { my $f = shift; local $/; open my $h, '<:utf8', $f or die "$f: $!"; my $t = <$h>; close $h; $t }
sub gravar { my ($f, $t) = @_; open my $h, '>:utf8', $f or die "$f: $!"; print $h $t; close $h }

my $doc = ler("$dir/word/document.xml");

# 1. quebra de seção vai para o parágrafo anterior
my $SECAO = qr{<w:p><w:pPr><w:sectPr>((?:(?!</w:sectPr>).)*)</w:sectPr></w:pPr></w:p>}s;
my ($novo, $pos, $juntadas, $soltas) = ('', 0, 0, 0);
while ($doc =~ /$SECAO/g) {
  my ($ini, $fim, $sect) = ($-[0], $+[0], $1);
  my $antes = substr($doc, $pos, $ini - $pos);
  my $p = rindex($antes, '<w:p>'); my $p2 = rindex($antes, '<w:p '); $p = $p2 if $p2 > $p;
  if ($antes =~ m{</w:p>\s*\z} && $p >= 0 && substr($antes, $p) !~ /<w:tbl[ >]/) {
    my $par = substr($antes, $p);
    if ($par =~ m{\A<w:p(?: [^>]*)?><w:pPr>}) { $par =~ s{</w:pPr>}{<w:sectPr>$sect</w:sectPr></w:pPr>} }
    else { $par =~ s{\A(<w:p(?: [^>]*)?>)}{$1<w:pPr><w:sectPr>$sect</w:sectPr></w:pPr>} }
    $novo .= substr($antes, 0, $p) . $par; $juntadas++;
  } else {
    $novo .= $antes . substr($doc, $ini, $fim - $ini); $soltas++;
  }
  $pos = $fim;
}
$doc = $novo . substr($doc, $pos);

# 2. estilo de tabela pela marca que o fatec.lua pôs antes dela
my %estilo_tabela = (MarcaQuadro => 'Quadro', MarcaSemBorda => 'TabelaSemBorda');
my %marcas;
$doc =~ s{<w:p><w:pPr><w:pStyle w:val="(Marca(?:Quadro|SemBorda))"\s*/></w:pPr></w:p>\s*(<w:tbl>.*?</w:tbl>)}{
  my ($m, $tbl) = ($1, $2); $marcas{$m}++;
  $tbl =~ s{<w:tblStyle w:val="Table"\s*/>}{<w:tblStyle w:val="$estilo_tabela{$m}"/>};
  $tbl =~ s{<w:pStyle w:val="Compact"\s*/>}{<w:pStyle w:val="SiglaCelula"/>}g if $m eq 'MarcaSemBorda';
  $tbl }gse;

# 3. seção final (do último "CAPÍTULO N" ao fim): o pandoc não copia a página nem
#    o cabeçalho do modelo para ela, só a numeração das notas. Ela é reescrita:
#    A4, margens 3/2/3/2, número no alto à direita e, se abre com "CAPÍTULO N",
#    primeira página sem número.
my $titlepg = $doc =~ s{<w:p><w:pPr><w:pStyle w:val="MarcaTitlePg"\s*/></w:pPr></w:p>\s*}{};
$doc =~ s{<w:sectPr>((?:(?!<w:sectPr>).)*?)</w:sectPr>(\s*</w:body>)}{
  my ($velho, $fim) = ($1, $2); my ($notas) = $velho =~ m{(<w:footnotePr>.*?</w:footnotePr>)}s; $notas //= '';
  '<w:sectPr><w:headerReference w:type="default" r:id="rIdCab1"/>'
  . ($titlepg ? '<w:headerReference w:type="first" r:id="rIdCab2"/>' : '') . $notas
  . '<w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1701" w:right="1134" w:bottom="1134" w:left="1701" w:header="709" w:footer="709" w:gutter="0"/>'
  . ($titlepg ? '<w:titlePg/>' : '') . "</w:sectPr>$fim" }se or die "seção final não encontrada\n";
die "sobrou marca no documento\n" if $doc =~ /w:val="Marca/;

# 4. numeração das linhas do código
my $listagens = 0;
$doc =~ s{(<w:p><w:pPr><w:pStyle w:val="SourceCode"\s*/></w:pPr>)(.*?)(</w:p>)}{
  my ($a, $corpo, $b) = ($1, $2, $3); my $n = 1; $listagens++;
  my $num = sub { sprintf '<w:r><w:rPr><w:rStyle w:val="NumeroLinha"/></w:rPr><w:t xml:space="preserve">%4d  </w:t></w:r>', $_[0] };
  $corpo =~ s{(<w:r><w:br\s*/></w:r>)}{$1 . $num->(++$n)}ge;
  $a . $num->(1) . $corpo . $b }gse;

gravar("$dir/word/document.xml", $doc);

# 5. propriedades do arquivo
my $core = ler("$dir/docProps/core.xml");
for ([title => $titulo], [creator => $autores]) {
  my ($k, $v) = @$_;
  $core =~ s{<dc:$k\s*/>|<dc:$k>.*?</dc:$k>}{<dc:$k>$v</dc:$k>}s or $core =~ s{</cp:coreProperties>}{<dc:$k>$v</dc:$k></cp:coreProperties>};
}
gravar("$dir/docProps/core.xml", $core);

printf "posprocessar: %d quebras de seção juntadas (%d mantidas), %d quadros, %d tabela(s) sem borda, %d listagens numeradas\n",
  $juntadas, $soltas, $marcas{MarcaQuadro} // 0, $marcas{MarcaSemBorda} // 0, $listagens;
