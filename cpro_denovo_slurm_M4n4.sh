#!/bin/bash			
#SBATCH -n 10
#SBATCH -N 1
#SBATCH --mem 50000
#SBATCH -o M4n4.out
#SBATCH -e M4n4.err
#SBATCH -t 2-23:00 
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=cam435@cornell.edu
#SBATCH --clusters=cbsumm22

export LD_LIBRARY_PATH=/usr/local/gcc-7.3.0/lib64:/usr/local/gcc-7.3.0/lib #specify library path
export PATH=/programs/stacks-2.3e/bin:$PATH #specify library path

#mkdir samples
mkdir stacks_M4n4
#cp /home/cam435/cpro_ddrad/cpro_stacks_final/cpro_pop_map_test.txt .
#cp /home/cam435/cpro_ddrad/cpro_stacks_final/samples_renamed/*fq ./samples

denovo_map.pl -M 4 -T 10 --time-components -o ./stacks_M4n4 --popmap ./cpro_pop_map_test.txt --samples ./samples -X "cstacks:-n 4" -X "populations:-r 0.8"