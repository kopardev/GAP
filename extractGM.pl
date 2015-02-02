#! /usr/bin/perl -w

# Extract fasta sequences from GeneMarkS output (.lst) file produced by gmhmmp when -a option is used

print STDERR "\nUsage:\n\n$0 < lst_file > pep_file\n\n";

$write = 'no';
while($string = <STDIN>){
	chomp $string;
	if($string =~ /^\>/){
		$write = 'yes';
	}
	if($string eq ''){
		$write = 'no';
	}
	if($write eq 'yes'){
		print $string."\n";
	}
}
