## Introduction 

## BGAP：bacteria genome analysis pipeline  

A complete analysis pipeline for genome reads or contigs of bacteria.

for single bacteria isolate genome, BGAP can calculate sequence quality and screen genes related to bacterial molecular function.   
for mutiple bacteria isolate genomes, in addition to the above applications, BGAP also can process phylogenetic analysis and calculate the number and function of pan genome.   

It comes bundled with multiple flows:   
sequence quality control, genome assembly, assembly quality control, gene prediction, phylogenetic analysis, PubMLST typing, screening of antimicrobial resistance genes/virulece genes/plasmids/phages/mobile genetic elements and calculating the pan genome and gene annotation.   

BGAP can run on Linux.   

## Installation:

### Required software 

ncbi-blast+: https://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download   
fastqc: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/   
SPAdes: https://github.com/ablab/spades   
Unicycler: https://github.com/rrwick/Unicycler   
Prokka: https://github.com/tseemann/prokka   
kSNP: https://sourceforge.net/projects/ksnp/   
fasttree: http://www.microbesonline.org/fasttree/   
ABRicate: https://github.com/tseemann/abricate   
mlst: https://github.com/tseemann/mlst   
PhageMiner: https://github.com/RezaRezaeiJavan/PhageMiner   
Roary: https://github.com/sanger-pathogens/Roary   
EggNOG-mapper: https://github.com/eggnogdb/eggnog-mapper   

## Analysis flows:   

### sequence quality control
perl ./bin/reads_QC.pl -rl reads.list  

### genome assembly and assembly quality control 
perl ./bin/reads_assembly.pl -rl reads.list -t next-generation (or nanopore)   

### gene prediction  
perl ./bin/run_prokka.pl -sl genomes.list   

### phylogenetic analysis  
perl ./bin/run_ksnp.pl -sl genomes.list -annotate AE016830.1.fasta (reference genomes,optional)  

### PubMLST typing  
perl ./bin/run_mlst.pl -mlst -sl genomes.list -scheme efaecalis (scheme,optional)    

### screening of antimicrobial resistence genes/virulence genes/plasmids/IS sequence/mobile genetic elements  
perl ./bin/run_abricate.pl -abricate -sl genomes.list -db resfinder_new (or other database name)   

### screening of phages   
perl ./bin/run_PhageMiner.pl -sl genomes-gbk.list    

### calculating the pan genome and gene annotation   
perl ./bin/run_roary.pl -sl genomes-gff.list   

## Database and test  

### database  
database : ./db/  
database information: perl ./bin/run_abricate.pl -dblist  

### test  
test reads data : ./test/rawdata  
test input and output files : ./test/  

## Issues  
please report problems to the Issues Page.  

## Author  
 
