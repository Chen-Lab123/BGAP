#!/usr/bin/perl 
=head1 Description
        genome assembly
=head1 Usage
        perl reads_assembly.pl [options]
        general input and output:
        -rl  <a file>       list of fastq file of read(file suffix must be ".fastq.gz"), one strain per line, PE read seperated by ",", and different by "\n"
        -t   <type>         type:"next-generation","nanopore"
        -o   <a directory>  output dir, default current directory [./]
        -thd <num>          thread for dsub
        -h                  show help

=head1 Example
        perl reads_assembly.pl -rl reads.list -t next-generation

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

my ($assembly,$type,$readlist,$outdir,$help,$thd);

GetOptions (
        "t:s"=>\$type,
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
#assembly
##################
        if (!$readlist){
                print "No input read files\n";
                exit;
        }
        if (!$type){
                print "No input read type: 'next-generation' or 'nanopore'\n";
                exit;
        }
        
        mkdir "$outdir/assembly";
        
        open (OUT, ">$outdir/assembly.sh")||die;
        if ($readlist && $type eq "next-generation"){
		open (IN,$readlist)||die;
         	while (<IN>){
			chomp;
			my @tmp=split /\s+/, $_;
			my $tag=(split /[\_\.]/, basename((split /\,/, $_)[0]))[0];
                	my $cmd="/datapool/software/anaconda3/bin/spades.py --careful -o $outdir/assembly/$tag ";
                	my $i=1;
                	foreach my $line (@tmp) {
					my @read=split /\,/, $line;
					for (my $j=0; $j<@read; $j++) {
					$read[$j]=abs_path($read[$j]);
					}

					if (@read==1) {
						$cmd.="--s$i $read[0] ";
					}
					elsif (@read==2) {
						$cmd.="--pe$i-1 $read[0] --pe$i-2 $read[1] ";
					}
					elsif (@read==3) {
						$cmd.="--pe$i-1 $read[0] --pe$i-2 $read[1] --s$i $read[2] ";
					}
					$i++;
			}
			print OUT $cmd."\n";
		}
		`perl $Bin/dsub_batch.pl -thd 10 -mem 4 $outdir/assembly.sh`;
		`perl $Bin/pick_contigs_from_spades_result.pl $outdir/assembly/ $outdir/final_contig/ > $outdir/pick_1k_contig.sh`;
		`sh $outdir/pick_1k_contig.sh > $outdir/ass_stats.txt`;
		my $num=`less $outdir/ass_stats.txt|grep -c "Sequence information"`;
		chomp($num);
		my $i=`less assembly.sh|wc -l`;
		chomp($i);
		until($num=$i){
			sleep 10;
			`perl $Bin/pick_contigs_from_spades_result.pl $outdir/assembly/ $outdir/final_contig/ > $outdir/pick_1k_contig.sh`;
			`sh $outdir/pick_1k_contig.sh > $outdir/ass_stats.txt`;
			my $num=`less $outdir/ass_stats.txt|grep -c "Sequence information"`;
			chomp($num);
			if ($num=$i){
				last;
			}       
		}
        }
		
	if ($readlist && $type eq "nanopore"){
		open (IN,$readlist)||die;
            	while (<IN>){
			chomp;
			my @tmp=split /\s+/, $_;
			my $tag=(split /[\_\.]/, basename((split /\,/, $_)[0]))[0];
                	my $cmd="/datapool/software/anaconda3/bin/unicycler -o $outdir/assembly/$tag ";
                	my $i=1;
                	foreach my $line (@tmp) {
				my @read=split /\,/, $line;
                    		for (my $j=0; $j<@read; $j++) {
					$read[$j]=abs_path($read[$j]);
                   		 }	
				
				if (@read==1) {
					$cmd.="-l $read[0] ";
                    		}
                    		elsif (@read==2) {
					$cmd.="-1 $read[0] -2 $read[1] ";
                    		}
				elsif (@read==3) {
					$cmd.="-1 $read[0] -2 $read[1] -l $read[2] ";
                   		}
                    		$i++;
			}
				print OUT $cmd."\n";
		}	
            	`perl $Bin/dsub_batch.pl -thd 10 -mem 4 $outdir/assembly.sh`;
            	`perl $Bin/pick_contigs_from_unicycler_result.pl $outdir/assembly/ $outdir/final_contig/ > $outdir/pick_1k_contig.sh`;
		`sh $outdir/pick_1k_contig.sh > $outdir/ass_stats.txt`;
		my $num=`less $outdir/ass_stats.txt|grep -c "Sequence information"`;
		chomp($num);
		my $i=`less assembly.sh|wc -l`;
		chomp($i);
		until($num=$i){
			sleep 10;
			`perl $Bin/pick_contigs_from_unicycler_result.pl $outdir/assembly/ $outdir/final_contig/ > $outdir/pick_1k_contig.sh`;
			`sh $outdir/pick_1k_contig.sh > $outdir/ass_stats.txt`;
			my $num=`less $outdir/ass_stats.txt|grep -c "Sequence information"`;
			chomp($num);
			if ($num=$i){
				last;
			}       
		 }
	}	
	close IN;
	close OUT;
