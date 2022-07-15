#!/usr/bin/perl
=head1 Description
        Mass assembled screening of contigs for antimicrobial resistance, virulence genes, plasmids, IS sequences or mobile genetic elements.        
=head1 Usage
	perl run_abricate.pl [options]
        -abricate            mass screening
        -dblist              above database information
	-sl   <a file>       required, list of genome files
        -o    <a directory>  optional, output dir, default current direction
        -db   <string>       required, select one type:"abricate","Ab_vf","argannot","card","ecoh","ecoli_vf","Efs_vf","ISfinder","megares",
			     "MobileElementFinder","ncbi","ncbibetalactamase","plasmidfinder","resfinder","resfinder_new","Spn_vf","vfdb"
	-cov  <number>	     optional, mininum DNA coverage (default '75')
	-h                   show help

    abricate parameter:
    --minid=f <number>   optional, minimum DNA identity (default '75')
    --list         	 List included databases (default '0')
                
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

my ($seqlist,$outdir,$db,$minid,$coverage,$abricate,$dblist,$help);

GetOptions (
        "sl:s"=>\$seqlist,
        "o:s"=>\$outdir,
        "db:s"=>\$db,
	"cov:s"=>\$coverage,
	"abricate"=>\$abricate,
	"dblist"=>\$dblist,
        "h"=>\$help,
);
die `pod2text $0` if ($help||(!$abricate and !$dblist));

unless ($outdir){
        $outdir=".";
}

unless (-e $outdir){
        mkdir $outdir;
}

unless ($minid){
	$minid=75;
}

unless ($coverage){
	$coverage=75;
}

dblist() if ($dblist);
abricate() if ($abricate);

##################
#Screening
##################

sub dblist{
	if ($dblist){
		print "%VF
Ab_vf:  69 sequences -  Jul 8, 2022; from vfdb database; web: http://www.mgc.ac.cn/cgi-bin/VFs/genus.cgi?Genus=Acinetobacter
Efs_vf:  42 sequences -  Jul 8, 2022; from vfdb database; web: http://www.mgc.ac.cn/cgi-bin/VFs/genus.cgi?Genus=Enterococcus
Spn_vf:  37 sequences -  Jul 8, 2022; from vfdb database; web: http://www.mgc.ac.cn/cgi-bin/VFs/genus.cgi?Genus=Streptococcus
ecoli_vf:  2701 sequences -  Jul 8, 2022; web: https://github.com/phac-nml/ecoli_vf
vfdb:  2597 sequences -  Mar 17, 2017; article: doi:10.1093/nar/gkv1239

%AMR
argannot:  1749 sequences -  Jul 8, 2017; article: doi:10.1128/AAC.01310-13
megares:  6635 sequences -  Jul 8, 2022; article: doi:10.1093/nar/gkz1010
card:  2124 sequences -  Jul 8, 2017; web: https://card.mcmaster.ca/ doi:10.1093/nar/gkw1004
ncbi:  5386 sequences -  Jul 8, 2022; web: https://www.ncbi.nlm.nih.gov/bioproject/PRJNA313047 doi: 10.1128/AAC.00483-19
ncbibetalactamase:  1557 sequences -  Mar 17, 2017
resfinder:  2228 sequences -  Jul 8, 2017
resfinder_new:  3148 sequences -  May 12, 2022; article: doi:10.1093/jac/dks261

%IS
ISfinder:  5970 sequences -  Jun 25, 2022; web: https://github.com/thanhleviet/ISfinder-sequences

%MGE
MobileElementFinder:  4452 sequences -  Apr 13, 2022; web: https://bitbucket.org/mhkj/mgedb/src/master/

%PLASMID
plasmidfinder:  263 sequences -  Mar 19, 2017; web: https://bitbucket.org/genomicepidemiology/plasmidfinder_db/src/master/

%SEROTYPE
ecoh:  597 sequences -  Jul 8, 2022; web: https://github.com/katholt/srst2/tree/master/data doi:10.1099/mgen.0.000064\n";	
	}
}

sub abricate{
        if (!$seqlist or !$db){
                print "No input genome files or db name\n";
                exit;
        }
	mkdir "$outdir/$db";
	mkdir "$outdir/$db/result";
		
	open (OUT,">$outdir/$db/abricate.sh")||die;
        if ($seqlist){
                open (IN,$seqlist)||die;
                while (<IN>){
                        chomp;
                        my $tag=(split /\./,basename($_))[0];
                        print OUT "/datapool/software/anaconda3/bin/abricate $_ --db $db --minid=$minid > $outdir/$db/result/$tag"."_$db.tab\n";
                }
        }
        close IN;
        close OUT;
	`perl $Bin/dsub_batch.pl -thd 6 -mem 4 $outdir/$db/abricate.sh`;
	sleep 20;
	`/datapool/software/anaconda3/bin/abricate --summary $outdir/$db/result/*.tab --nopath |grep -v 'result' > $outdir/$db/summary.tab`;
	`perl $Bin/matrix_tr.pl $outdir/$db/summary.tab $coverage > $outdir/$db/summary.matrix`;
	my $i=`less $outdir/$db/abricate.sh|wc -l`;
	chomp($i);
	my $num=`ls $outdir/$db/result/*.tab|wc -l`;
        my @tmp=`wc -l $outdir/$db/result/*.tab|awk '{print $1}'`;
	my $num_1=(split /\s+/,$tmp[0])[1];
	my $num_2=(split /\s+/,$tmp[-2])[1];

	until ($i=$num && $num_1>2 && $num_2>2){
		sleep 10;
		my $num=`ls $outdir/$db/result/*.tab|wc -l`;
		my @tmp=`wc -l $outdir/$db/result/*.tab|awk '{print $1}'`;
		my $tmp_1=(split /\s+/,$tmp[0])[1];
		my $tmp_2=(split /\s+/,$tmp[-2])[1];
		if ($i=$num && $num_1>2 && $num_2>2){
			`/datapool/software/anaconda3/bin/abricate --summary $outdir/$db/result/*.tab --nopath |grep -v 'result' > $outdir/$db/summary.tab`;
			`perl $Bin/matrix_tr.pl $outdir/$db/summary.tab $coverage > $outdir/$db/summary.matrix`;		
			last;
		}
	}
}

