#!/usr/bin/perl -w
use strict;
use warnings;

my $usage = "Usage: $0 <glimmer coords file> <short name> <gff>";

die $usage unless ((scalar @ARGV)==3);

my $glimmerCoordsFile = shift;
my $shortName = shift;
my $gff = shift;

die "$glimmerCoordsFile not found!\n" unless (-e $glimmerCoordsFile);

open F1,"<${glimmerCoordsFile}";
my @cnamesTmp;
system("rm -f *.glcoords");
while (<F1>) {
	chomp;
	my @columns = split /\t/;
	push (@cnamesTmp,$columns[3]);
	my $fname=$columns[3].".glcoords";
	open F2, ">>$fname";
	printf F2 "%s\n",$_;
	close(F2);
}
close(F1);
my @cnames=&find_unique(@cnamesTmp);

open O1,">${gff}.tmp";
my $geneNumber=0;
foreach my $cname (@cnames) {
	open F1, "<${cname}.glcoords";
	while (<F1>) {
    	chomp;
    	s/^\s*//;
    	my ($id, $start, $end, $rest) = split /\s+/, $_, 4;
    	my $strand;
    	($start, $end, $strand) = $end > $start ? ($start, $end, "+") : ($end, $start, "-");
    	$geneNumber++;
	my $geneName=sprintf("%s_gene_%05d",$shortName,$geneNumber);
	#print O1 join ("\t", $cname, "Glimmer", "gene", $start, $end, ".", $strand, ".", $id), "\n";
	print O1 join ("\t", $cname, "Glimmer", "gene", $start, $end, ".", $strand, ".", $geneName), "\n";
	}
	close(F1);
}
close(O1);
system("sort -k1,1 -k4,4n ${gff}.tmp -o ${gff}");
exit;

sub find_unique {
    my @array = @_;
    my %count;
    map { $count{$_}++ } @array;
    return (keys %count);
}
