#!/bin/bash

bash ~/sgeResetup.sh

CONFIG_FILE=/mnt/datastore/workflow_data/workflow.ini

# source in the configuration file:
[[ ! -f ${CONFIG_FILE} ]] && "There is no valid workflow.ini set!" && exit 0

source ${CONFIG_FILE}

for (( i=0; i<${#tumorBams[@]}; i++ )); do

	# Relink files

	tumorbam=${tumorBams[$i]}
	dellyfile=${dellyFiles[$i]}

	export pid=PCVP-000$i
	pidPath=/mnt/datastore/testdata/$pid
	alignmentFolder=$pidPath/alignment
	dellyFolder=$pidPath/delly
	mkdir -p $alignmentFolder $dellyFolder

	ln -sf $tumorbam $alignmentFolder/tumor_${pid}_merged.mdup.bam
	ln -sf $controlBam $alignmentFolder/control_${pid}_merged.mdup.bam
	ln -sf ${tumorbam}.bai $alignmentFolder/tumor_${pid}_merged.mdup.bam.bai
	ln -sf ${controlBam}.bai $alignmentFolder/control_${pid}_merged.mdup.bam.bai
	ln -sf $dellyfile ${dellyFolder}/${pid}.DELLY.somaticFilter.highConf.bedpe.txt

	touch $alignmentFolder/tumor_${pid}_merged.mdup.bam
	touch $alignmentFolder/control_${pid}_merged.mdup.bam 
	touch $alignmentFolder/tumor_${pid}_merged.mdup.bam.bai
	touch $alignmentFolder/control_${pid}_merged.mdup.bam.bai

	# Call Roddy

	cd ~/bin/Roddy

	export aceseqlog=/root/logs/aceseq_$pid.log
	export aceseqrc=/root/logs/aceseq_$pid.rc
	export snvlog=/root/logs/snv_$pid.log
	export snvrc=/root/logs/snv_$pid.rc
	export indellog=/root/logs/indel_$pid.log
	export indelrc=/root/logs/indel_$pid.rc

	export runACESeq=${runACESeq-true}
	export runIndel=${runIndel-true}
	export runSNV=${runSNV-true}

	multiplierACESeq=0
	multiplierSNV=0
	[[ $runACESeq == true ]] && multiplierACESeq=0
	[[ $runSNV == true ]] && multiplierSNV=0

	# Sleep several seconds / minutes / hours to get a better queueing
	export sleepSNV=`expr $multiplierACESeq \* 3600`
	export sleepIndel=`expr $multiplierACESeq \* 3600 + $multiplierSNV \* 3600`

	[[ $runACESeq == true ]] && (bash roddy.sh rerun dkfzPancancerBase@copyNumberEstimation $pid --waitforjobs --useconfig=applicationPropertiesAllLocal.ini > $aceseqlog; echo $? > $aceseqrc) & ps0=$!
	[[ $runSNV == true ]] && (sleep $sleepSNV; bash roddy.sh rerun dkfzPancancerBase@snvCalling $pid --waitforjobs --useconfig=applicationPropertiesAllLocal.ini > $snvlog; echo $? > $snvrc) & ps1=$!
	[[ $runIndel == true ]] && (sleep $sleepIndel; bash roddy.sh rerun dkfzPancancerBase@indelCalling $pid --waitforjobs --useconifg=applicationPropertiesAllLocal.ini > $indellog; echo $? > $indelrc) & ps2=$!

	wait $ps0 $ps1 $ps2
	
	# Roddy's built-in wait does not work in docker images...
	while [[ `qstat -t | wc -l` > 2 ]]; do
		sleep 60
	done

	# Collect files and write them to the output folder

	# Collect the log files

	resultLogFolder=/mnt/datastore/result_data/${pid}_logs
	cp -r $pidPath/roddyExecutionStore $resultLogFolder
	cp /root/logs/*$pid* $resultLogFolder

	# Copy the result files

	cp -r $pidPath ${pidPath}_final

done
# Always do that?
echo 0
