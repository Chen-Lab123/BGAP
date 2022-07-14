#!/usr/bin/perl
=head1 Description
	phylogenetic analysis       
=head1 Usage
        perl run_ksnp.pl [options]
        -sl   <a file>       required, list of genome files
        -o    <a directory>  required, output dir, default current direction
	-k    <number>	     required, length of sequence flanking the SNP, default 13
        -h             	     show help

        ksnp parameter:
	-annotate <file name>	optional, list of reference genomes
	-CPU      <number>	optional, defaults to the number of processors available 
		
=head1 Example

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

my ($seqlist,$outdir,$kmer,$ref,$help);

GetOptions (
	"sl:s"=>\$seqlist,
	"o:s"=>\$outdir,
	"k:s"=>\$kmer,
	"annotate:s"=>\$ref,
	"h"=>\$help,
);
die `pod2text $0` if ($help || !$seqlist);

unless ($outdir){
	$outdir=".";
}

unless (-e $outdir){
	mkdir $outdir;
}

unless ($kmer){
	$kmer=13;
}

##################
#SNP
##################

	if (!$seqlist){
		print "No input genome files\n";
		exit;
	}
	
	mkdir "$outdir/SNP";
	
	open (OUT,">$outdir/SNP/genomes_trim.list")||die;
	if ($seqlist){
		open (IN,$seqlist)||die;
		while (<IN>){
			chomp;
			my $tag=(split /\./,basename($_))[0];
			print OUT "$_\t$tag\n";
		}
	}
	close IN;
	close OUT;
	
	open (SNP,">$outdir/SNP/ksnp.sh")||die;
	print SNP "/datapool/stu/yuejl/newpool/stu/yuejl/1-1/tool/kSNP/kSNP3.1_Linux_package/kSNP3/kSNP3 -in $outdir/SNP/genomes_trim.list -k $kmer -outdir $outdir/SNP/output/ -annotate $ref  | tee $outdir/SNP/runLogfile.txt\n";
	close SNP;
	
	open (TREE,">$outdir/SNP/fasttree.sh")||die;
	print TREE "/datapool/software/anaconda3/bin/fasttree -log $outdir/SNP/fasttree.log -quiet -nt -gtr $outdir/SNP/output/SNPs_all_matrix.fasta > $outdir/SNP/fasttree.tree\n";
	close TREE;
	
	`qsub -cwd $outdir/SNP/ksnp.sh`;
	my $num=`ls $outdir/SNP/output/SNPs_all_matrix.fasta|wc -l`;
	chomp($num);
	
	until ($num==1){
		sleep 600;
		my $num=`ls $outdir/SNP/output/SNPs_all_matrix.fasta|wc -l`;
		chomp($num);
		if ($num==1){
			`perl $Bin/dsub_batch.pl -thd 6 -mem 4 $outdir/SNP/fasttree.sh`;
			last;
		}
	}
