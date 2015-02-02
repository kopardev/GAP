#!/usr/bin/perl -w

# Extracts sequences from FASTA file based on .predict file output by Glimmer3.
# Talk about stupidity...
# by J, 2007-05-21
# modified by VNK, 2012-07-14

use strict;

die "$0 <glimmer predict file> <assembly fasta file> <genes fasta file> <glimmer coords file> <short name>" unless ((scalar @ARGV)==5);

open(PRE, "<$ARGV[0]") or die "\nCould not open Glimmer prediction file $ARGV[0]\n";
open(SEQ, "<$ARGV[1]") or die "\nCould not open (multi-)FASTA sequence file $ARGV[1]\n";
open my $GENESFASTA, '>', $ARGV[2] or die "\nCould not open output FASTA file!\n";
open my $COORDS, '>',$ARGV[3] or die "\nCould not open output COORDS file!\n";
my $shortName=$ARGV[4];

my($buff, %pred);

while(<PRE>) {
 unless($_ =~ /^>/) {
   chomp;
   push @{$pred{$buff}}, $_;
 }
 else {
  chomp;
  my @tmp = split;
  $buff = substr($tmp[0], 1);
 }
}

my($seq,$id,$flag);

my $geneNumber=1;

while(<SEQ>) {
 unless($_ =~ /^>/) {
   chomp;
   $seq .= $_;
   $flag = 1;
 }
 else { 
   if($flag) { $geneNumber=extract($id, $seq, $GENESFASTA, $COORDS,$geneNumber,$shortName); }
   my @tmp = split;
   $id = substr($tmp[0], 1);
   $seq = "";
 }
}
if($flag) { $geneNumber=extract($id, $seq, $GENESFASTA, $COORDS,$geneNumber,$shortName); }

close $GENESFASTA;
close $COORDS;
exit;


############################ subs

sub extract {
 my($id, $seq, $GENESFASTA, $COORDS,$geneNumber,$shortName) = @_;
 if(exists $pred{$id}) {
   foreach my $line (@{$pred{$id}}) {
    my @tmp = split(/\s+/, $line);
    #print $GENESFASTA ">$id\_$tmp[0]\n";
    my $geneName=sprintf("%s_gene_%05d",$shortName,$geneNumber);
    $geneNumber++;
    print $GENESFASTA ">$geneName\n";
    #print $COORDS "$id\_$tmp[0]\t$tmp[1]\t$tmp[2]\t$id\n";
    print $COORDS "$geneName\t$tmp[1]\t$tmp[2]\t$id\n";
    my($st,$end);
    if($tmp[1] < $tmp[2]) { $st = $tmp[1]; $end = $tmp[2]; } else { $st = $tmp[2]; $end = $tmp[1]; }
    if($tmp[3] < 0) { print $GENESFASTA revcomp(substr($seq, $st-1, $end-$st+1)), "\n"; }
     else { print $GENESFASTA substr($seq, $st-1, $end-$st+1), "\n"; }
   }
 }
 return $geneNumber;
}

##########

sub revcomp {
 my($seq) = @_;
 $seq = reverse $seq;
 $seq =~ tr/ACGTacgt/TGCAtgca/;
 return $seq;
}
