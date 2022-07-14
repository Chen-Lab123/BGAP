#!/usr/bin/perl
=head1 Description
        pan genome analysis and gene annotation.  
=head1 Usage
        perl run_roary.pl [options]
        -sl   <a file>       required, list of extracting gff files
        -o    <a directory>  required, output dir, default current direction
	-h                   show help
        
    roary parameter:
    -i    minimum percentage identity for blastp [default: 80]
    -p    number of threads [default: 10]
	
    emapper parameter:
    -e    Report only alignments below or equal the e-value threshold (default: 1e-5) 
       
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

my ($gfflist,$outdir,$identity,$thread,$evalue,$help);

GetOptions (
        "sl:s"=>\$gfflist,
        "o:s"=>\$outdir,
	"i:s"=>\$identity,
	"p:s"=>\$thread,
	"e:s"=>\$evalue,
        "h"=>\$help,
);
die `pod2text $0` if ($help || (!$gfflist));

unless ($outdir){
        $outdir=".";
}

unless (-e $outdir){
        mkdir $outdir;
}

unless ($identity){
	$identity=80;
}

unless ($thread){
	$thread=10;
}

unless ($evalue){
	$evalue=1e-5;
}

##################
#Pangenome
##################

	if (!$gfflist){
                print "No input gff files\n";
                exit;
        }
        
        mkdir "$outdir/pangenome";
	mkdir "$outdir/pangenome/input";
	mkdir "$outdir/pangenome/output";
	mkdir "$outdir/pangenome/emapper";
	
        if ($gfflist){
                open (IN,$gfflist)||die;
                while (<IN>){
                        chomp;
                  	`cp $_ $outdir/pangenome/input/`;
                }
		close IN;
        }
	
	open (OUT,">$outdir/pangenome/roary.sh")||die;
	print OUT "#"."\$"." ";
        print OUT "-S /bin/bash\n";
        print OUT "conda activate qiime2\n";
	print OUT "/datapool/software/anaconda3/envs/qiime2/bin/roary -f $outdir/pangenome/output/ -i $identity -e -n -v -p $thread $outdir/pangenome/input/*.gff\n";
        close OUT;
	`qsub -cwd $outdir/pangenome/roary.sh`;
		
	open (EM,">$outdir/pangenome/emapper.sh")||die;
	print EM "#"."\$"." ";
        print EM "-S /bin/bash\n";
        print EM "conda activate base\n";
	print EM "python3 /datapool/software/eggnog-mapper-master/emapper.py -i $outdir/pangenome/output/*/pan_genome_reference.fa --itype CDS -m diamond --evalue $evalue -o pan_genome --output_dir $outdir/pangenome/emapper\n";
	close EM;
		
	my $num=`ls $outdir/pangenome/output/*/pan_genome_reference.fa|wc -l`;
	chomp($num);
		
	until ($num==1){
		sleep 120;
		my $num=`ls $outdir/pangenome/output/*/pan_genome_reference.fa|wc -l`;
		chomp($num);
		if ($num==1){
			`qsub -cwd $outdir/pangenome/emapper.sh`;
			sleep 10;
			last;
		}	
	}


