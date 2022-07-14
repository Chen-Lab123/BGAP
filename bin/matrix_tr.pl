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
$line[0]=~s/#//g;
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
		for my $n (@array){
			if ($n ne "." && $n>=$identity_cutoff){
				print "1\t";
				last;
			}
			if ($n eq "."){
				print "0\t";
				last;
			}
			if ($n ne "." && $n<80){
				print "0\t";
				last;
			}
		}
	}
	print "\n";
}
close IN;
