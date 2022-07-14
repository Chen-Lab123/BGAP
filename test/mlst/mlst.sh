#$ -S /bin/bash
conda activate mlst
mlst --quiet --nopath --legacy --scheme efaecalis --csv --minscore 90 --minid 80 --mincov 10 /datapool/stu/yuejl/genome-analysis-pipeline/test-1/final_contig/*.fas > ./mlst/mlst.csv
