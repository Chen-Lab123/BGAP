#$ -S /bin/bash
conda activate qiime1
python /datapool/software/anaconda3/bin/PhageMiner.py 3222_contigs.gbk
#$ -S /bin/bash
conda activate qiime1
python /datapool/software/anaconda3/bin/PhageMiner.py 5202_contigs.gbk
#$ -S /bin/bash
conda activate qiime1
python /datapool/software/anaconda3/bin/PhageMiner.py 5403_contigs.gbk
