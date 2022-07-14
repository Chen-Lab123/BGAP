#!/usr/bin/perl
=head1 Description
        prophage identification in bacterial genomes.        
=head1 Usage
        perl run_PhageMiner.pl [options]
        -sl   <a file>       required, list of extracting genebank files
        -o    <a directory>  required, output dir, default current direction
	-h                   show help
                
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

my ($gblist,$outdir,$help);

GetOptions (
        "sl:s"=>\$gblist,
        "o:s"=>\$outdir,
        "h"=>\$help,
);
die `pod2text $0` if ($help || (!$gblist));

unless ($outdir){
        $outdir=".";
}

unless (-e $outdir){
        mkdir $outdir;
}

##################
#Screening
##################

	if (!$gblist){
                print "No input genebank files\n";
                exit;
        }
        
        mkdir "$outdir/phage";
	mkdir "$outdir/phage/result";
		
	open (OUT,">$outdir/phage/result/phage.sh")||die;
        if ($gblist){
                open (IN,$gblist)||die;
                while (<IN>){
                        chomp;
			my $gbk=(split /\//,$_)[-1];
                        `cp $_ $outdir/phage/result/ `;
			print OUT "#"."\$"." ";
			print OUT "-S /bin/bash\n";
			print OUT "conda activate qiime1\n";
                        print OUT "python /datapool/software/anaconda3/bin/PhageMiner.py $gbk\n";
                }
        }
        close IN;
        close OUT;
	
	`split -l 30 $outdir/phage/result/phage.sh -d -a 3 phage-`;
	`mv $outdir/phage-* $outdir/phage/result`;

	my @file=glob "$outdir/phage/result/phage-*";
	chdir "$outdir/phage/result/";
	for my $tmp (@file){
		my $file=basename($tmp);
		`qsub -cwd $file`;
	}
	sleep 10;
	chdir "../../";
	my $i=`less $outdir/phage/result/phage.sh|wc -l`;
	my $num=`ls $outdir/phage/result/*/*.csv|wc -l`;
	chomp($num);
	chomp($i);
	my $j=$i/3;
	`perl $Bin/summary.pl $outdir/phage/result/ csv > $outdir/phage/summary.tab`;
        `perl $Bin/matrix-2-list.pl $outdir/phage/summary.tab > $outdir/phage/summary.matrix`;
		
	until ($j=$num){
		sleep 120;
		my $num=`ls $outdir/phage/result/*/*.csv|wc -l`;
		chomp($num);
		if ($j=$num){
			`perl $Bin/summary.pl $outdir/phage/result/ csv > $outdir/phage/summary.tab`;
			`perl $Bin/matrix-2-list.pl $outdir/phage/summary.tab > $outdir/phage/summary.matrix`;
			`rm -rf $outdir/phage/result/*.gbk`;
			last;
		}
	}
