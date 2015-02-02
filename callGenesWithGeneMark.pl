#!/usr/bin/perl
#Developer: Vishal Koparde, Ph.D.
#Created: 120710
#Modified:120710
#Version 1.0 - Called by GAP

use strict;
use warnings;
use Getopt::Long;
use lib qw(/usr/global/blp/perllib);
use Qsub;
use Bio::Tools::GFF;
use Bio::Tools::Genemark;


sub usage();

usage() if (scalar @ARGV==0);

my ($fastaSorted,$gmsnGenesFile,$workingDir,$genesFasta,$genesGff,$genesFastaTmp,$prefix,$force,$help);

GetOptions ( 'sortedFasta=s' => \$fastaSorted,
             'gmsnFile=s' => \$gmsnGenesFile,
             'genesFasta=s' => \$genesFasta,
             'genesGff=s' => \$genesGff,
             'prefix=s' => \$prefix,
             'wd=s' => \$workingDir,
             'force' => \$force,
             'help|?' => \$help);

usage() if ($help);

die "Fasta file $fastaSorted not found!" if (! -e $fastaSorted);
die "prefix not defined!" unless (defined $prefix);
$gmsnGenesFile = $prefix.".gmsn_genes" if (! defined $gmsnGenesFile);
$genesFasta = $prefix."_genes.fasta" if (! defined $genesFasta);
$genesGff = $prefix."_genes.gff" if (! defined $genesGff);
$genesFastaTmp = $genesFasta.".tmp";
if (!defined $workingDir) {
    $workingDir=`pwd`;
    chomp $workingDir;
}

die "$genesFasta exists, please use --force to overwrite!\n" if (-e $genesFasta && ! $force);

my $GeneMark_cmd1="/usr/global/blp/GeneMark/GeneMarkS/genemark_suite_linux_64/gmsuite/gmsn.pl -euk $fastaSorted -output $gmsnGenesFile";
my $jname = "GM1_".$prefix;
my $jnameout = $jname.".tmp.out";
my $job_gm1=new Qsub(name=>$jname,wd=>$workingDir,outfile=>$jnameout,cmd=>$GeneMark_cmd1);
$job_gm1->submit();

$jname = "GM2_".$prefix;
$jnameout = $jname.".tmp.out";
#my $GeneMark_cmd2="/usr/global/blp/GenomeAnnotationPipeline/lst2fasta.pl -c $fastaSorted -l $gmsnGenesFile -o $genesFastaTmp";
my $GeneMark_cmd2="/usr/global/blp/GenomeAnnotationPipeline/lst2fasta.pl -c $fastaSorted -l $gmsnGenesFile -o $genesFasta";
my $job_gm2=new Qsub(name=>$jname,wd=>$workingDir,outfile=>$jnameout,cmd=>$GeneMark_cmd2,waitfor=>"$job_gm1->{jobid}");
$job_gm2->submit();

#$jname = "GM3_".$prefix;
#$jnameout = $jname.".tmp.out";
#my $GeneMark_cmd3="fasta_change_seqid -i $genesFastaTmp -o $genesFasta -l -p ${prefix}_gene -a";
#my $job_gm3=new Qsub(name=>$jname,wd=>$workingDir,outfile=>$jnameout,cmd=>$GeneMark_cmd3,waitfor=>"$job_gm2->{jobid}");
#$job_gm3->submit();

$job_gm2->waitForCompletion();
my $cmd="perl /usr/global/blp/GenomeAnnotationPipeline/gmsn2gff.pl $gmsnGenesFile $genesGff $prefix";
system($cmd);

exit;

sub usage() 
{
print <<EOF;
Call Genes Using GeneMarkS

Developer : Vishal N Koparde, Ph. D.
Created   : 120710
Modified  : 120710
Version   : 1.0

options:
--sortedFasta      Fasta file sorted by size of sequences (large-to-small)
--gmsnFile         Intermediate GeneMark File (optional)
--genesFasta       Output Genes Fasta File (optional)
--genesGff         Output Genes GFF v.3 File (optional)
--prefix           Sequence ID prefix for the genes fasta file, generally organism short name(required)
--wd               Working Directory (Default="pwd")
--force            Overwrite all files
--help             This help
EOF
exit 1;
}