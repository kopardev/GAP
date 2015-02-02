#!/usr/bin/perl

use strict;
use warnings;

my $genesGff=shift;
my $assemblyFasta=shift;

system("/usr/global/blp/bin/samtools faidx ${assemblyFasta}");
system("/usr/global/blp/bin/complementBed -i ${genesGff} -g ${assemblyFasta}.fai > ${genesGff}.complement");

open COM, "<${genesGff}.complement";

my $currentContig="";
my @intergenicLengths;
my ($start,$end);
while (my $line=<COM>) {
    chomp($line);
    my @cols=split /\t/,$line;
    if ($currentContig ne $cols[0]) {
        $currentContig=$cols[0];
        $start=$cols[2];
        next;
    }
    $end=$cols[1];
    push @intergenicLengths,abs($start-$end);
    $start=$cols[2];
}
close COM;

my $sum=0;
$sum += $_ for (@intergenicLengths);
my $avg = 1.0 * $sum / (scalar @intergenicLengths);

printf "%10.2f\n", $avg;
#unlink("${genesGff}.complement");
exit;

