#$ -S /bin/bash
conda activate base
python3 /datapool/software/eggnog-mapper-master/emapper.py -i ./pangenome/output/*/pan_genome_reference.fa --itype CDS -m diamond --evalue 1e-05 -o pan_genome --output_dir ./pangenome/emapper
