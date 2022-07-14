#!usr/bin/perl -w

if (@ARGV!=1){
	print "perl $0 <two_list>\n";
	exit;
}
my (%list1,%list2,%hash,@name);
open (IN,$ARGV[0])||die;
while (<IN>){
	chomp;
	my @line=split /\t/,$_;
	$list1{$line[0]}=1;
	$list2{$line[1]}=1;
	$hash{$line[0]}{$line[1]}=1;
	#print "$line[0]\t$line[1]\t$hash{$line[0]}{$line[1]}\n";
}

my @list1_key=sort {$a cmp $b} keys %list1;
my @list2_key=sort {$a cmp $b} keys %list2;

for my $n (@list2_key){
	push @name,$n;
}
print " \t";

for my $m (0..$#name){
	print "$name[$m]\t";
}
print "\n";

for my $a (@list1_key){
	print "$a\t";
	for my $b (0..$#name){
		if (exists $hash{$a}{$name[$b]}){
			print "$hash{$a}{$name[$b]}\t";
		}else{
			print "0\t";
		}
	}
	print "\n";
}

close IN;
