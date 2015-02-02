#!/usr/bin/perl
#Developer: Vishal Koparde, Ph.D.
#Created: 120725
#Modified:120725
#Version 1.0 - Called by GAP

use strict;
use warnings;
use Getopt::Long;
use lib qw(/usr/global/blp/perllib);
use Qsub;
use File::Basename;

our $asgard = "/usr/global/blp/bin/asgard";
our ($gapdir);
if (exists $ENV{'GAPDIR'}) {
$gapdir=$ENV{'GAPDIR'};
} else {
$gapdir="/usr/global/blp/GenomeAnnotationPipeline";
}

sub usage();

usage() if (scalar @ARGV==0);

my ($fasta,$blastxdb,$project,$workingDir,$summaryFile,$gff,$praThreshold,$help);

GetOptions ( 'fasta=s' => \$fasta,
   	     'db=s' => \$blastxdb,
             'project=s' => \$project,
             'wd=s' => \$workingDir,
             'summary=s' => \$summaryFile,
	     'gff=s' => \$gff,
	     'pqa=f' => \$praThreshold,
             'help|?' => \$help);

usage() if ($help);
if (!defined $workingDir) {
    $workingDir=`pwd`;
    chomp $workingDir;
}
die "$workingDir : Folder not found!\n" unless (-d $workingDir);
chdir($workingDir);
die "$fasta : File not Found!\n" unless (-e $fasta);

my ($fastaFileName,$fastaFilePath,$fastaFileExt);
($fastaFileName,$fastaFilePath,$fastaFileExt) = fileparse($fasta,qr"\..[^.]*$");
my $outFile="${workingDir}/blastres_${fastaFileName}${fastaFileExt}";
my $fastaNoPath=${fastaFileName}.${fastaFileExt};
my $blastx_cmd="$asgard -B -y -w";
$blastx_cmd.=" -i $fastaNoPath";
$blastx_cmd.=" -p blastx";
$blastx_cmd.=" -d $blastxdb";
my $jname="blastx_".$project;
my $jout=$jname.".tmp.out";
my $job_blastx=new Qsub(name=>$jname,outfile=>$jout,wd=>$workingDir,cmd=>$blastx_cmd);
$job_blastx->submit();

$job_blastx->waitForCompletion();
my $cmd;

my $outFileFiltered=$outFile.".filtered";
my $evalueMin=1e-4;
$praThreshold=90 unless defined $praThreshold;
$cmd = "${gapdir}/filter_blast_output -i $outFile -o $outFileFiltered -pra $praThreshold -fasta $fasta -evalue $evalueMin";
system ($cmd);

my $nseq=`grep -c ">" $fasta`;
chomp $nseq;
$cmd="blast2desc -b ${outFileFiltered} -d $blastxdb -n $nseq";
print $cmd."\n";
system($cmd);
die "blast2desc failed!\n" unless("${outFileFiltered}.desc");
my $uniqueProteinsHit;
if (defined $gff) {
open F1, "<${outFileFiltered}.desc";
open O1, ">${gff}.tmp";
my @gis;
while (my $line=<F1>) {
	chomp $line;
	my @m8desc = split "\t",$line;
	my @cnames = split "_",$m8desc[0];
	my @cbounds = split "-",pop(@cnames);
	my $cname = join "_",@cnames;
	my $gi = ($m8desc[1] eq $m8desc[-1]) ? $m8desc[1] : $m8desc[1].$m8desc[-1];
	push (@gis,$gi);
	my $pi = $m8desc[2];
	my $start = ($cbounds[0] - 1) + $m8desc[6];
	my $end = ($cbounds[0] - 1) + $m8desc[7];
	my $strand;
	($start, $end, $strand) = $end > $start ? ($start, $end, "+") : ($end, $start, "-");
	my @gffLine;
	push(@gffLine,$cname);
	push(@gffLine,"BLASTX");
	push(@gffLine,"Protein");
	push(@gffLine,$start);
	push(@gffLine,$end);
	push(@gffLine,$pi);
	push(@gffLine,$strand);
	push(@gffLine,".");
	push(@gffLine,$gi);
	printf O1 "%s\n",join("\t",@gffLine);
}
close(F1);
close(O1);
$uniqueProteinsHit = count_unique(@gis);
my $cmd="sort -k1,1 -k4,4n ${gff}.tmp -o ${gff}";
system($cmd);
unlink("${gff}.tmp");
}		 

my $nseqHit=`cut -f1 ${gff}|sort|uniq|wc -l`;
chomp $nseqHit;		

if (defined $summaryFile) {
open SF,">$summaryFile";
print SF "No. of genes              \t\t\t:$nseq\n";
print SF "No. of genes with Hit(s)  \t\t\t:$nseqHit\n";
print SF "No. of Unique Proteins Hit\t\t\t:$uniqueProteinsHit\n";
print SF "GffFile                   \t\t\t:$gff\n" if (defined $gff);
close(SF);
}
exit;

sub count_unique {
    my @array = @_;
    my %count;
    map { $count{$_}++ } @array;
    return scalar(keys %count);
}

sub usage() 
{
print <<EOF;
Run BLASTx with ASGARD

Developer : Vishal N Koparde, Ph. D.
Created   : 120725
Modified  : 130213
Version   : 1.0

options:
--fasta    genes in fasta format
--db       blastx database
--project  project name
--wd       working dir (default=current directory)
--summary  summary file
--pqa      percent of query that should be aligned (default 90%)
--gff      gff file name

EOF
exit 1;
}
