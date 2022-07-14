#!/usr/bin/perl

=head1 Description
	run prokka for genome annotation
=head1 Usage
	perl run_prokka.pl [options]
	-seq <string>  direction saving genome sequence files [*.fna, *.fas, *.fasta, *.seq]
	-sl  <string>  list of genome files
	-o   <string>  output dir, default current direction
	-cpu <string>  # of cpus to use, default 1
	-thd <num>     thread for dsub
	-noanno        fast gene prediction without annotation of CDS, tRNA, rRNA
	-h             show help

    prokka parameter:
    -kingdom  default Bacteria
    -genus
    -species

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

my ($seqdir, $seqlist, $outdir, $cpu, $help, $kingdom, $genus, $species, $thd, $noanno,$tag);
GetOptions (
	"seq:s"=>\$seqdir,
	"sl:s"=>\$seqlist,
	"o:s"=>\$outdir,
	"cpu:s"=>\$cpu,
	"h"=>\$help,
	"kingdom:s"=>\$kingdom,
	"genus:s"=>\$genus,
	"noanno"=>\$noanno,
	"species:s"=>\$species,
	"thd:s"=>\$thd,
);
die `pod2text $0` if ($help || (!$seqdir and !$seqlist));

unless ($outdir) {
	$outdir="./";
}
$outdir=abs_path($outdir);
unless (-e $outdir) {
	mkdir $outdir;
}
unless (-e "$outdir/prokka") {
	mkdir "$outdir/prokka";
}

unless ($cpu) {
	$cpu=10;
}

unless ($kingdom) {
	$kingdom="Bacteria";
}

unless ($thd) {
	$thd=12;
}

##################
##gene_prediction
##################

my @files;
if ($seqdir) {
	@files=glob "$seqdir/*.fna";
	push @files, glob "$seqdir/*.fas";
	push @files, glob "$seqdir/*.fasta";
	push @files, glob "$seqdir/*.seq";
}
elsif ($seqlist) {
	open (IN, $seqlist) || die;
	@files=<IN>;
	close IN;
}

my %shell;
open (OUT, ">$outdir/prokka/prokka.sh") || die;
foreach my $seq (@files) {
	chomp $seq;
	$seq=abs_path($seq);
	my $tag=(split /\./, basename($seq))[0];
	#my $tag_2=(split /\//, $seq)[-2];
	#$tag=$tag_2."-".$tag_1;
	#my $cmd_1="#"."\$"." -S /bin/bash"."\n"."conda activate R4.1"."\n";
	my $cmd_2="/datapool/software/anaconda3/envs/R4.1/bin/prokka --force --cpus $cpu --outdir $outdir/prokka/$tag --prefix $tag --locustag $tag --metagenome --kingdom $kingdom ";
	my $cmd=$cmd_2;
	$cmd.="--genus $genus " if ($genus);
	$cmd.="--species $species " if ($species);
	$cmd.="--noanno --norrna --notrna " if ($noanno);
	$cmd.=$seq;
	$shell{$tag}=$cmd;
	print OUT $cmd."\n";
}
close OUT;
`perl $Bin/dsub_batch.pl -thd $thd -mem 4 -env R4.1 $outdir/prokka/prokka.sh`;
sleep 10;
`cp $outdir/prokka/prokka.sh $outdir/prokka/prokka_tmp.sh`;
my %shell_tmp=%shell;
while (0+keys %shell_tmp>0) {
	#delete finished cmd and print unfinished;
	open (OUT, ">$outdir/prokka/prokka_tmp.sh") || die;
	foreach my $tag (sort keys %shell_tmp) {
		my $log_file=`ls $outdir/prokka/$tag/*.log`;
		chomp $log_file;
		if ($log_file){
			open (IN, $log_file) || die;
			my @tmp=<IN>;
			close IN;
			my $log=join '', @tmp;
			if ($log=~/Annotation\sfinished\ssuccessfully/) {
				delete $shell_tmp{$tag} if (exists $shell_tmp{$tag});
			}
			else {
				print OUT $shell_tmp{$tag}."\n";
			}
		}else{
			sleep 10;
		}
	}
	close OUT;
}
`rm $outdir/prokka/prokka_tmp.sh`;

