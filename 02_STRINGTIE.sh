#!/bin/bash
#PBS -c s
#PBS -j oe
#PBS -m abe
#PBS -N stringtie
#PBS -M username@my.jcu.edu.au
#PBS -l walltime=1000:00:00
#PBS -l nodes=1:ppn=4
#PBS -l pmem=4gb

f=DUMMY

cd /shares/32/jc320251/untouched_data

/sw/stringtie/1.3.1c/stringtie $f -G ../Homo_sapiens.GRCh38.87.gtf -o ${f%.bam}stringtie.gtf -p 4 -v -l ${f%_R1.bam}
