#!/bin/bash
#callGenesWithGlimmer
if [ ! #$ -eq 2 ]; then
echo "callGenesWithGlimmer uses scripted developed by Sergey Pintus"
echo "callGenesWithGlimmer requires two parameters: assembly in fasta format and a project name"
exit
fi
fasta=$1
project=$2
/usr/global/blp/GenomeAnnotationPipeline/g3-from-scratch.csh $fasta $project
extract_glimmer3_seq.pl ${project}.predict $fasta > ${project}_genes.fas 2> ${project}.coords
