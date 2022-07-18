#!usr/bin/perl -w
if(@ARGV!=2){
	print "perl $0 <abricate-summary.tab> <identity_cutoff>\nidentity is the percentage(%)\n";
	exit;
}

my ($summary,$identity_cutoff)=@ARGV;
open (IN,$summary)||die;
my $name=<IN>;
chomp($name);
my @line=split /\t/,$name;
print "$line[0]\t";
for my $a (2..$#line){
	print "$line[$a]\t";
}
print "\n";
while (<IN>){
	chomp;
	my @line=split /\t/,$_;
	#print "$line[0]\t";
	my $tmp=(split /\//,$line[0])[-1];
	my $tag=(split /\./,$tmp)[0];
	print "$tag\t";
	for my $i (2..$#line){
		my @array=split /;/,$line[$i];
		if ($array[0] ne "."){
                        my @sort_array=sort {$a <=> $b} @array;
                        if ($sort_array[-1] >= $identity_cutoff){
				print "1\t";
			}else{
				print "0\t";
			}
                }
                if ($array[0] eq "."){
                        print "0\t";
                }
	
	}
	print "\n";
}
close IN;
