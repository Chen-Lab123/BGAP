#!/usr/bin/perl
=head1 Description
        Scan contig files against traditional PubMLST typing schemes
=head1 Usage
        perl run_mlst.pl [options]
	-mlst                identity mlst from contig files
	-dblist		     List allelles for all MLST schemes	
        -sl   <a file>       required, list of genome contig files
        -o    <a directory>  required, output dir, default current direction
	-h                   show help
        
    abricate parameter:
    -scheme             optional, don't autodetect, force this scheme on all inputs (default '')
    -minid [n.n]     	 DNA %identity of full allelle to consider 'similar' [~] (default '80')
    -mincov [n.n]    	 DNA %cov to report partial allele at all [?] (default '10')
    -minscore [n.n]  	 Minumum score out of 100 to match a scheme (when auto --scheme) (default '90')

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

my ($seqlist,$outdir,$scheme,$scheme_tag,$minid,$mincov,$minscore,$mlst,$dblist,$help);

GetOptions (
        "sl:s"=>\$seqlist,
        "o:s"=>\$outdir,
        "scheme:s"=>\$scheme,
	"minid:s"=>\$minid,
	"mincov:s"=>\$mincov,
	"minscore:s"=>\$minscore,
	"mlst"=>\$mlst,
	"dblist"=>\$dblist,
        "h"=>\$help,
);

unless ($outdir){
        $outdir=".";
}

unless (-e $outdir){
        mkdir $outdir;
}

unless ($minid){
	$minid=80;
}

unless ($mincov){
	$mincov=10;
}

unless ($minscore){
	$minscore=90;
}

dblist () if ($dblist);
mlst () if ($mlst);
die `pod2text $0` if ($help||(!$mlst and !$dblist));
##################
#MLST
##################

sub dblist {
	open (LIST,">$outdir/dblist.sh")||die;
	if ($dblist){
		print LIST "#"."\$"." ";
                print LIST "-S /bin/bash\n";
                print LIST "conda activate mlst\n";
                print LIST "mlst --longlist > $outdir/dblist\n";
	}
	close LIST;
	`qsub -cwd $outdir/dblist.sh`;
	sleep 20;
	my $list=`cat $outdir/dblist`;
	print "$list";
	`rm $outdir/dblist*`;
}

sub mlst {
	if (!$seqlist){
		print "No input genome files\n";
		exit;
	}
	mkdir "$outdir/mlst";
	open (OUT,">$outdir/mlst/mlst.sh")||die;
	if ($seqlist){
		open (IN,$seqlist)||die;
		my $filepath=<IN>;
		chomp($filepath);
		my $filetype=(split /\./,basename ($filepath))[-1];
		my $dir=dirname($filepath);
		my $file=$dir."/*.".$filetype;
		print OUT "#"."\$"." ";
		print OUT "-S /bin/bash\n";
		print OUT "conda activate mlst\n";
		if (!$scheme){
			print OUT "mlst --quiet --nopath --csv --minscore $minscore --minid $minid --mincov $mincov $file > $outdir/mlst/mlst.csv\n";
		}
		if ($scheme){
			print OUT "mlst --quiet --nopath --legacy --scheme $scheme --csv --minscore $minscore --minid $minid --mincov $mincov $file > $outdir/mlst/mlst.csv\n";
		}
	}
	close IN;
	close OUT;
	`qsub -cwd $outdir/mlst/mlst.sh`;
}
