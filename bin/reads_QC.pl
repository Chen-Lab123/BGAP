#!/usr/bin/perl 
=head1 Description
	sequence quality control
=head1 Usage
	perl reads_QC.pl [options]
	general input and output:
	-rl  <a file>       list of fastq file of read(file suffix must be ".fastq.gz"), one strain per line, PE read seperated by ",", and different by "\n"
	-o   <a directory>  output dir, default current directory [./]
	-thd <num>          thread for dsub
	-h                  show help

=head1 Example
	perl reads_QC.pl -rl reads.list

=head1 Version
        Author: yuejinglin0802@163.com
        Date: 2022-07-04
=cut

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use FindBin qw($Bin $Script);
use Cwd qw/abs_path/;

my ($seq_QC,$readlist,$outdir,$help,$thd);

GetOptions (
	"sQC:s"=>\$seq_QC,
	"rl:s"=>\$readlist,
	"o:s"=>\$outdir,
	"h"=>\$help
);
die `pod2text $0` if ($help || !$readlist);

unless ($outdir) {
	$outdir=".";
}

unless (-e $outdir) {
	mkdir $outdir;
}

unless ($thd){
	$thd=8;
}

##################
#seq_QC
##################
	if (!$readlist){
		print "No input read files\n";
		exit;
	}
	mkdir "$outdir/seq_QC";
	mkdir "$outdir/seq_QC/result";
	my $fastqc="/datapool/software/anaconda3/envs/qiime2/bin/fastqc";
	
	open (OUT, ">$outdir/fastqc.sh")||die;
	if ($readlist){
		open (IN,$readlist)||die;
		while (<IN>){
			chomp;
			my @tmp=split /\,/,$_;
			for my $i (@tmp){
				my $cmd="$fastqc --extract $i -o $outdir/seq_QC/result";
				print OUT $cmd."\n";
			}
		}
	}
	close IN;
	close OUT;
	`perl $Bin/dsub_batch.pl -thd 10 -mem 4 $outdir/fastqc.sh`;
	`perl $Bin/fastqc_summary.pl $outdir/seq_QC/result > $outdir/seq_QC/fastqc_summary.txt`;
	my $num=`less $outdir/seq_QC/fastqc_summary.txt|wc -l`;
        chomp($num);
	until($num>1){
		sleep 10;
		`perl $Bin/fastqc_summary.pl $outdir/seq_QC/result > $outdir/seq_QC/fastqc_summary.txt`;
		my $num=`less $outdir/seq_QC/fastqc_summary.txt|wc -l`;
        	chomp($num);
		#print "$num\n";
		if ($num>1){
			last;
		}	
	}

