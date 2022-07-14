#$ -S /bin/bash
conda activate qiime2
/datapool/software/anaconda3/envs/qiime2/bin/roary -f ./pangenome/output/ -i 80 -e -n -v -p 10 ./pangenome/input/*.gff
