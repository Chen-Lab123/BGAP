#!usr/bin/perl

if (@ARGV!=2){
        print "perl $0 <IS.fna> <IS-annotation.txt>\n";
        exit;
}
my (%hash,%hash1);
open (IN,$ARGV[0])||die;
$/=">";
while (<IN>){
        chomp;
        my ($anno,$seq)=(split /\n/,$_)[0,1];
        $anno=~s/>//g;
	my $id=(split /_/,$anno)[0];
        $seq=~s/\n//g;
        $hash{$id}=$seq;
}
close IN;

open (IN1,$ARGV[1])||die;
$/="\n";
<IN1>;
while (<IN1>){
        chomp;
        my @line1=split /\t/,$_;
        my $result="ISfinder~~~$line1[0]~~~$line1[1]_$line1[2]_$line1[3]";
        $hash1{$line1[0]}=$result;
}
close IN1;

for my $key (keys %hash1){
	if (exists $hash1{$key}){
		print ">$hash1{$key}\n";
	}
        if (exists $hash{$key}){
		print "$hash{$key}\n";
	}
}
