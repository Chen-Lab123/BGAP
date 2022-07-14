#!usr/bin/perl -w 
use File::Basename;

if (@ARGV!=2){
	print "perl $0 <dir> <filetype>\n";
	exit;
}

my ($dir,$type)=@ARGV;
print "";
my @files=glob "$dir/*/*.$type";

for my $file (@files){
	my $tag=(split /\//,dirname($file))[-1];
	open (IN,$file)||die;
	<IN>;
	while (<IN>){
		chomp;
		my @line=split /,/,$_;
		print "$tag\t$line[-1]\n";
	}
		close IN;
}
