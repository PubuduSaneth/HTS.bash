#!/bin/bash

#  Novoalign_run.bash
#  
#
#  Created by PubuduSaneth on 7/21/14.
#

cwd=$(pwd)

echo -e "Please type the identifier common for all the sample folders"
read sId

prefix="${PWD##*/}"
echo -e "\nInitial health check for .fastq and .sam files\n"
echo "#!/bin/bash" > $prefix'_gatkRun.bash'
cp ~/lokiScripts/configScript_v.1.1_nextera.bash .
mv configScript_v.1.1_nextera.bash $prefix'.config'

for dir in $(find . -name "${sId}*" -type d)
do
    cd $dir
    r1Fastq=$(find . -name "*R1_001.fastq.gz")
    r2Fastq=$(find . -name "*R2_001.fastq.gz")
    samFile=$(find . -name "*sam")
    [[ $(echo $samFile | wc -w) -ne 1 ]] && { echo -e "more than 1 sam file: $samFile .. exiting the script" ; exit 0 ;}
    lane=$(echo $r1Fastq | cut -d _ -f2,3)
    echo -e "\n$dir\n\tRead1: $r1Fastq\n\tRead2: $r2Fastq\n\tSAM file:$samFile"
    echo "cd $dir" >> '../'$prefix'_gatkRun.bash'
    echo -e "echo \"analyzing ${dir:2}...\"" >> '../'$prefix'_gatkRun.bash'
    echo -e "bash ~/lokiScripts/runScript_nextera.bash ${samFile:2} > runScript.bash.log" >> '../'$prefix'_gatkRun.bash'
    echo -e "cd $cwd\n" >> '../'$prefix'_gatkRun.bash'
    cd $cwd
done
