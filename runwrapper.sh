#!/bin/bash
set -x

sudo bash ~/sgeResetup.sh

CONFIG_FILE=/mnt/datastore/workflow_data/workflow.ini

# source in the configuration file:
[[ ! -f ${CONFIG_FILE} ]] && "There is no valid workflow.ini set!" && exit 0

source ${CONFIG_FILE}

for (( i=0; i<${#tumorBams[@]}; i++ )); do
	# Relink files

	export tumorbam=${tumorBams[$i]}
	export dellyfile=${dellyFiles[$i]}

	export pid=${aliquotIDs[$i]}
	export pidPath=/mnt/datastore/testdata/$pid
	export alignmentFolder=$pidPath/alignment
	export snvCallingFolder=$pidPath/mpileup
	export aceSeqFolder=$pidPath/ACEseq
	export indelCallingFolder=$pidPath/platypus_indel
	export dellyFolder=$pidPath/delly
	export JAVA_HOME=/roddy/bin/Roddy/dist/runtimeDevel/jre

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

	export aceseqlog=/roddy/logs/aceseq_$pid.log
	export aceseqrc=/roddy/logs/aceseq_$pid.rc
	export snvlog=/roddy/logs/snv_$pid.log
	export snvrc=/roddy/logs/snv_$pid.rc
	export indellog=/roddy/logs/indel_$pid.log
	export indelrc=/roddy/logs/indel_$pid.rc

	export runACESeq=${runACESeq-true}
	export runIndel=${runIndel-true}
	export runSNV=${runSNV-true}

	multiplierACESeq=0
	multiplierSNV=0
	[[ $runACESeq == true ]] && multiplierACESeq=5
	[[ $runSNV == true ]] && multiplierSNV=5

	# Sleep several seconds / minutes / hours to get a better queueing
	export sleepSNV=`expr $multiplierACESeq \* 60`
	export sleepIndel=`expr $multiplierACESeq \* 60 + $multiplierSNV \* 60`

	[[ $runACESeq == true ]] && (bash roddy.sh rerun dkfzPancancerBase@copyNumberEstimation $pid --waitforjobs --useconfig=applicationPropertiesAllLocal.ini > $aceseqlog; echo $? > $aceseqrc) & ps0=$!
	[[ $runSNV == true ]] && (sleep $sleepSNV; bash roddy.sh rerun dkfzPancancerBase@snvCalling $pid --waitforjobs --useconfig=applicationPropertiesAllLocal.ini > $snvlog; echo $? > $snvrc) & ps1=$!
	[[ $runIndel == true ]] && (sleep $sleepIndel; bash roddy.sh rerun dkfzPancancerBase@indelCalling $pid --waitforjobs --useconfig=applicationPropertiesAllLocal.ini > $indellog; echo $? > $indelrc) & ps2=$!

	wait $ps0 $ps1 $ps2

	# Finalize access rights for the workspace folder
	cd /mnt/datastore/testdata; find -type d | xargs chmod u+rwx,g+rwx,o+rwx; find -type f | xargs chmod u+rw,g+rw,o+rw

	echo "Wait for Roddy jobs to finish"
	# Roddy's built-in wait does not work reliable in docker images...
	while [[ `qstat -t | wc -l` > 2 ]]; do
			sleep 60
	done
	
	echo "Check job state logfiles"
	# Now check all the job state logfiles from the last three entries in the result folder.
	# Only take the last directory of every workflow.
	jobstateFiles=( `ls -d $pidPath/r*/*copy*/job* | tail -n 1` `ls -d $pidPath/r*/*snv*/job* | tail -n 1` `ls -d $pidPath/r*/*indel*/job* | tail -n 1` )
	failed=false
	for logfile in ${jobstateFiles[@]}
	do
		cntStarted=`cat $logfile | grep -v null: | grep ":STARTED:" | wc -l`
		cntSuccessful=`cat $logfile | grep -v null: | grep ":0:"| wc -l`
		cntErrornous=`expr $cntStarted - $cntSuccessful`
		[[ $cntErrornous -gt 0 ]] && failed=true && echo "Errors found for jobs in $logfile"
		[[ $cntErrornous == 0 ]] && echo "No errors found for $logfile"
	done
	
	[[ $failed == true ]] && echo "There was at least one error in a job status logfile. Will exit now!" && exit 5

	# From now on, ignore any errors and return 0!
	
	# Collect files and write them to the output folder

	# Collect the log files

	echo "Copying log files"
	export resultFolder=/mnt/datastore/resultdata
	export resultLogFolder=/mnt/datastore/resultdata/${pid}_logs
	export resultFilesFolder=/mnt/datastore/resultdata/data
	cp -r $pidPath/roddyExecutionStore $resultLogFolder
	cp /roddy/logs/*$pid* $resultLogFolder

	export roddyVersionString=`grep useRoddyVersion /roddy/bin/Roddy/applicationPropertiesAllLocal.ini`
	export pluginVersionString=`grep usePluginVersion /roddy/bin/Roddy/applicationPropertiesAllLocal.ini`
#	export workflowVersion=`/roddy/bin/Roddy/dist/runtimeDevel/groovy/bin/groovy -e 'println args[0].split("[=]")[1].split("[,]").find { it.contains("COWorkflows") }.split("[:]")[1].replace(".", "-")' $pluginVersionString`
	workflowVersionIndel=1-0-132-1
	workflowVersionSNV=1-0-132-1
	workflowVersionCNE=1-0-189
	# Copy the result files
	#cp -r $pidPath ${pidPath}_final
	export prefixSNV=${pid}.dkfz-snvCalling_${workflowVersionSNV}.${date}
	export prefixIndel=${pid}.dkfz-indelCalling_${workflowVersionIndel}.${date}
	export prefixACESeq=${pid}.dkfz-copyNumberEstimation_${workflowVersionCNE}.${date}

	# Separated output files
	export snvVCFGermlineFile=${resultFolder}/${prefixSNV}.germline.snv_mnv.vcf.gz
	export snvTbxGermlineFile=${resultFolder}/${prefixSNV}.germline.snv_mnv.vcf.gz.tbi
	export snvVCFSomaticFile=${resultFolder}/${prefixSNV}.somatic.snv_mnv.vcf.gz
	export snvTbxSomaticFile=${resultFolder}/${prefixSNV}.somatic.snv_mnv.vcf.gz.tbi
	export snvJsonFile=${resultFolder}/${prefixSNV}.snv_mnv.json
	export snvJsonTabTempFile=${resultFolder}/${prefixSNV}.snv_mnv.json.tab.tmp
	# Tarball
	export snvOptFile=${resultFolder}/${prefixSNV}.somatic.snv_mnv.tar.gz

	# Separated output files
	export indelVCFGermlineFile=${resultFolder}/${prefixIndel}.germline.indel.vcf.gz
	export indelTbxGermlineFile=${resultFolder}/${prefixIndel}.germline.indel.vcf.gz.tbi
	export indelVCFSomaticFile=${resultFolder}/${prefixIndel}.somatic.indel.vcf.gz
	export indelTbxSomaticFile=${resultFolder}/${prefixIndel}.somatic.indel.vcf.gz.tbi
	export indelJsonFile=${resultFolder}/${prefixIndel}.indel.json
	export indelJsonTabTempFile=${resultFolder}/${prefixIndel}.indel.json.tab.tmp
	# Tarball
	export indelOptFile=${resultFolder}/${prefixIndel}.somatic.indel.tar.gz

	export aceSeqVCFFile=${resultFolder}/${prefixACESeq}.somatic.cnv.vcf.gz
	export aceSeqTbxFile=${resultFolder}/${prefixACESeq}.somatic.cnv.vcf.gz.tbi
	export aceSeqOptFile=${resultFolder}/${prefixACESeq}.somatic.cnv.tar.gz

	echo "Filter and / or copy final files"

	perl -e 'use warnings; use strict; open(IN, "zcat $ARGV[0] |") or die "Could not open the zipped vcf file $ARGV[0]\n";open(GER, "| bgzip > $ARGV[1]") or die "Could not open the germline outfile $ARGV[1]\n";open(SOM, "| bgzip > $ARGV[2]") or die "Could not open the somatic outfile $ARGV[2]\n";while(<IN>){if($_ =~ /^#/){print GER $_; print SOM $_; next;}if($_ =~ /GERMLINE/){print GER $_;next;}my @l = split("\t", $_); my ($dpc) = $l[9] =~ /^\d\/\d\:(\d+)\:/; next if($l[2] =~ /^rs\d+/ && $dpc < 10); if($_ =~ /SOMATIC/){print SOM $_; next;}}' ${snvCallingFolder}/*pancan.vcf.gz ${snvVCFGermlineFile} ${snvVCFSomaticFile} || exit 2

	perl -e 'use warnings; use strict; open(IN, "zcat $ARGV[0] |") or die "Could not open the zipped vcf file $ARGV[0]\n";open(GER, "| bgzip > $ARGV[1]") or die "Could not open the germline outfile $ARGV[1]\n";open(SOM, "| bgzip > $ARGV[2]") or die "Could not open the somatic outfile $ARGV[2]\n";while(<IN>){if($_ =~ /^#/){print GER $_; print SOM $_; next;}if($_ =~ /GERMLINE/){print GER $_;next;}if($_ =~ /SOMATIC/){print SOM $_; next;}}' ${indelCallingFolder}/*pancan.vcf.gz ${indelVCFGermlineFile} ${indelVCFSomaticFile} || exit 3

	tabix -p vcf ${snvVCFGermlineFile}
	tabix -p vcf ${snvVCFSomaticFile}
	tabix -p vcf ${indelVCFGermlineFile}
	tabix -p vcf ${indelVCFSomaticFile}

	export finalCNEFile=`python /roddy/bin/getFinalCNEFile.py $pid $aceSeqFolder`
	export finalCNEParameterFile=`python /roddy/bin/getFinalCNEFile.py  $pid $aceSeqFolder 1`

	cp $finalCNEFile ${aceSeqVCFFile}
	cp $aceSeqFolder/plots/*.json ${resultFolder}/${prefixACESeq}.cnv.gcbias.json

	`python /roddy/bin/convertTabToJson.py -k cnv -f $finalCNEParameterFile -i ${pid} -o ${resultFolder}/${prefixACESeq}.cnv.json `

	echo "Create SNV json file"
	SOMSNVPREFILTER=`head -1 ${snvCallingFolder}/*_QC_values.tsv | cut -f 2`
	SOMSNVFINAL=`zcat ${snvVCFSomaticFile} | grep -v "#" | grep -w PASS | wc -l`
	SOMSNVALL=`zcat ${snvVCFSomaticFile} | grep -v "#" | wc -l`
	GERSNVLIKELY=`zcat ${snvVCFGermlineFile} | grep -v "#" | grep -w PASS | wc -l`
	
	echo -e "all_somatic\tcaller\tlikely_germline\tpassed_somatic\tsomatic_unfiltered\n${SOMSNVALL}\tmpileup_DKFZ\t${GERSNVLIKELY}\t${SOMSNVFINAL}\t${SOMSNVPREFILTER}" > ${snvJsonTabTempFile}
	python /roddy/bin/convertTabToJson.py -k snv_mnv -f ${snvJsonTabTempFile} -i ${pid} -o ${snvJsonFile} && rm ${snvJsonTabTempFile}
	
	echo "Create INDEL json file"
	SOMINDELFINAL=`zcat ${indelVCFSomaticFile} | grep -v "#" | grep -w PASS | wc -l`
	SOMINDELALL=`zcat ${indelVCFSomaticFile} | grep -v "#" | wc -l`
	GERINDELLIKELY=`zcat ${indelVCFGermlineFile} | grep -v "#" | grep -w PASS | wc -l`
	
	echo -e "all_somatic\tcaller\tlikely_germline\tpassed_somatic\n${SOMINDELALL}\tPlatypus_DKFZ\t${GERINDELLIKELY}\t${SOMINDELFINAL}" > ${indelJsonTabTempFile}
	python /roddy/bin/convertTabToJson.py -k indel -f ${indelJsonTabTempFile} -i ${pid} -o ${indelJsonFile} && rm ${indelJsonTabTempFile}
	
	python /roddy/bin/combineJsons.py -c ${resultFolder}/${prefixACESeq}.cnv.json -s ${snvJsonFile} -i ${indelJsonFile} -g ${resultFolder}/${prefixACESeq}.cnv.gcbias.json -o ${resultFolder}/${pid}.qc_metrics.dkfz.json -t ${pid}
	tabix -p vcf ${aceSeqVCFFile}

	echo "Create tarballs"
	#Tar up SNV tarball
	(cd ${pidPath}; tar -cvzf ${snvOptFile} mpileup ) &
	#And the indel tarball
	(cd ${pidPath}; tar -cvzf ${indelOptFile} platypus_indel ) &
	#And finally the aceseq tarball
	(cd ${pidPath}; tar -cvzf ${aceSeqOptFile} ACEseq ) &

	wait

	echo "Calculating md5 sums"
	for resultfile in `ls $resultFolder/$pid.dkfz*.tbi $resultFolder/$pid.dkfz*.gz`
	do
		echo "call md5sum for $i"
		cat $resultfile | md5sum | cut -b 1-33 > ${resultfile}.md5
	done

	echo "Setup proper access rights"
	# Finalize access rights for the result folder
	find -type d | xargs chmod u+rwx,g+rwx,o+rwx; find -type f | xargs chmod u+rw,g+rw,o+rw

done

# Always do that? 
echo 0
