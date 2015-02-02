#!/usr/bin/perl

#callGenesWithGlimmer


use warnings;
use strict;
use lib qw(/usr/global/blp/perllib);
use Qsub;
use Bio::Tools::GFF;
use Bio::Tools::Glimmer;

my ($gapdir);
if (exists $ENV{'GAPDIR'}) {
$gapdir=$ENV{'GAPDIR'};
} else {
$gapdir="/usr/global/blp/GenomeAnnotationPipeline";
}

my $fasta=shift;
my $prefix=shift;
my $workingDir=shift;
my $genesFasta=shift;
my $genesGff=shift;
my $coordsFile=shift;

my $Glimmer_cmd1="${gapdir}/g3-from-scratch.sh $fasta $prefix";
my $jname="GL1_".$prefix;
my $jnameout="GL1_".$prefix.".tmp.out";
my $job_gl1=new Qsub(name=>$jname,wd=>$workingDir,outfile=>$jnameout,cmd=>$Glimmer_cmd1);
$job_gl1->submit();

my $Glimmer_cmd2="${gapdir}/extract_glimmer3_seq.pl ${prefix}.predict $fasta $genesFasta $coordsFile $prefix";
$jname="GL2_".$prefix;
$jnameout="GL2_".$prefix.".tmp.out";
my $job_gl2=new Qsub(name=>$jname,wd=>$workingDir,outfile=>$jnameout,cmd=>$Glimmer_cmd2,waitfor=>"$job_gl1->{jobid}");
$job_gl2->submit();
$job_gl2->waitForCompletion();

my $cmd="perl ${gapdir}/glimCoords2gff.pl $coordsFile $prefix $genesGff";
system($cmd);
system("rm -rf *.glcoords");

exit;
