#!/bin/bash

bash ~/sgeResetup.sh

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
	export JAVA_HOME=/root/bin/Roddy/dist/runtimeDevel/jre

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


	# Roddy's built-in wait does not work reliable in docker images...
	while [[ `qstat -t | wc -l` > 2 ]]; do
			sleep 60
	done
	
	# Now check all the job state logfiles from the last three entries in the result folder.
	# Only take the last directory of every workflow.
	jobstateFiles=( `ls -d $pidPath/r*/*copy*/job* | tail -n 1` `ls -d $pidPath/r*/*snv*/job* | tail -n 1` `ls -d $pidPath/r*/*indel*/job* | tail -n 1` )
	failed=false
	for i in ${jobstateFiles[@]}
	do
		cntStarted=`cat $i | grep -v null: | grep ":57427:" | wc -l`
		cntSuccessful=`cat $i | grep -v null: | grep ":0:"| wc -l`
		cntErrornous=`expr $cntStarted - $cntSuccessful`
		[[ $cntErrornous -gt 0 ]] && failed=true && echo "Errors found for jobs in $i"
		[[ $cntErrornous == 0 ]] && echo "No errors found for $i"
	done
	
	[[ $failed == true ]] && echo "There was at least one error in a job status logfile. Will exit now!" && exit 5

	# From now on, ignore any errors and return 0!
	
	# Collect files and write them to the output folder

	# Collect the log files

	export resultFolder=/mnt/datastore/resultdata
	export resultLogFolder=/mnt/datastore/resultdata/${pid}_logs
	export resultFilesFolder=/mnt/datastore/resultdata/data
	cp -r $pidPath/roddyExecutionStore $resultLogFolder
	cp /root/logs/*$pid* $resultLogFolder

	export roddyVersionString=`grep useRoddyVersion /root/bin/Roddy/applicationPropertiesAllLocal.ini`
	export pluginVersionString=`grep usePluginVersion /root/bin/Roddy/applicationPropertiesAllLocal.ini`
	export workflowVersion=`/root/bin/Roddy/dist/runtimeDevel/groovy/bin/groovy -e 'println args[0].split("[=]")[1].split("[,]").find { it.contains("COWorkflows") }.split("[:]")[1].replace(".", "-")' $pluginVersionString`
	# Copy the result files
	#cp -r $pidPath ${pidPath}_final
	export prefixSNV=${pid}.dkfz-snvCalling_${workflowVersion}.${date}
	export prefixIndel=${pid}.dkfz-indelCalling_${workflowVersion}.${date}.somatic
	export prefixACESeq=${pid}.dkfz-copyNumberEstimation_${workflowVersion}.${date}.somatic

	# Combined output files
	export snvVCFAllFile=${resultFolder}/${prefixSNV}_all.somatic.snv_mnv.vcf.gz
	export snvTbxAllFile=${resultFolder}/${prefixSNV}_all.somatic.snv_mnv.vcf.gz.tbi
	# Separated output files
	export snvVCFGermlineFile=${resultFolder}/${prefixSNV}.germline.snv_mnv.vcf.gz
	export snvTbxGermlineFile=${resultFolder}/${prefixSNV}.germline.snv_mnv.vcf.gz.tbi
	export snvVCFSomaticFile=${resultFolder}/${prefixSNV}.somatic.snv_mnv.vcf.gz
	export snvTbxSomaticFile=${resultFolder}/${prefixSNV}.somatic.snv_mnv.vcf.gz.tbi
	# Tarball
	export snvOptFile=${resultFolder}/${prefixSNV}_all.snv_mnv.tar.gz

	# Combined output files
	export indelVCFAllFile=${resultFolder}/${prefixIndel}_all.snv_mnv.vcf.gz
	export indelTbxAllFile=${resultFolder}/${prefixIndel}_all.snv_mnv.vcf.gz.tbi
	# Separated output files
	export indelVCFGermlineFile=${resultFolder}/${prefixIndel}.germline.indel.vcf.gz
	export indelTbxGermlineFile=${resultFolder}/${prefixIndel}.germline.indel.vcf.gz.tbi
	export indelVCFSomaticFile=${resultFolder}/${prefixIndel}.somatic.indel.vcf.gz
	export indelTbxSomaticFile=${resultFolder}/${prefixIndel}.somatic.indel.vcf.gz.tbi
	# Tarball
	export indelOptFile=${resultFolder}/${prefixIndel}.indel.tar.gz

	export aceSeqVCFFile=${resultFolder}/${prefixACESeq}.somatic.cnv.vcf.gz
	export aceSeqTbxFile=${resultFolder}/${prefixACESeq}.somatic.cnv.vcf.gz.tbi
	export aceSeqOptFile=${resultFolder}/${prefixACESeq}.somatic.cnv.tar.gz

	#cp ${snvCallingFolder}/*pancan.vcf.gz ${snvVCFAllFile}
	#cp ${snvCallingFolder}/*pancan.vcf.gz.tbi ${snvTbxAllFile}
	perl -e 'use warnings; use strict; open(IN, "zcat $ARGV[0] |") or die "Could not open the zipped vcf file $ARGV[0]\n";open(GER, "| bgzip > $ARGV[1]") or die "Could not open the germline outfile $ARGV[1]\n";open(SOM, "| bgzip > $ARGV[2]") or die "Could not open the somatic outfile $ARGV[2]\n";while(<IN>){if($_ =~ /^#/){print GER $_; print SOM $_; next;}if($_ =~ /GERMLINE/){print GER $_;next;}if($_ =~ /SOMATIC/){print SOM $_; next;}}' ${snvCallingFolder}/*pancan.vcf.gz ${snvVCFGermlineFile} ${snvVCFSomaticFile} || exit 2

	#cp ${indelCallingFolder}/*pancan.vcf.gz ${indelVCFAllFile}
	#cp ${indelCallingFolder}/*pancan.vcf.gz.tbi ${indelTbxAllFile}
	perl -e 'use warnings; use strict; open(IN, "zcat $ARGV[0] |") or die "Could not open the zipped vcf file $ARGV[0]\n";open(GER, "| bgzip > $ARGV[1]") or die "Could not open the germline outfile $ARGV[1]\n";open(SOM, "| bgzip > $ARGV[2]") or die "Could not open the somatic outfile $ARGV[2]\n";while(<IN>){if($_ =~ /^#/){print GER $_; print SOM $_; next;}if($_ =~ /GERMLINE/){print GER $_;next;}if($_ =~ /SOMATIC/){print SOM $_; next;}}' ${indelCallingFolder}/*pancan.vcf.gz ${indelVCFGermlineFile} ${indelVCFSomaticFile} || exit 3

	tabix -p vcf ${snvVCFGermlineFile}
	tabix -p vcf ${snvVCFSomaticFile}
	tabix -p vcf ${indelVCFGermlineFile}
	tabix -p vcf ${indelVCFSomaticFile}

	export finalCNEFile=`python /root/bin/getFinalCNEFile.py $pid $aceSeqFolder`

	#Tar up SNV tarball
	(cd ${snvCallingFolder}; tar -cvzf ${resultFolder}/${prefixSNV}_all.somatic.snv_mnv.tar.gz * ) &
	#And the indel tarball
	(cd ${indelCallingFolder}; tar -cvzf ${resultFolder}/${prefixIndel}_all.somatic.indel.tar.gz * ) &
	#And finally the aceseq tarball
	(cd ${aceSeqFolder}; tar --exclude=*pancan* -cvzf ${resultFolder}/${prefixACESeq}_all.somatic.cnv.tar.gz *.txt *.gz *.tbi *.png cnv_snp/ plots/ ) &

	wait

	# Finalize access rights for the result folder
	cd $resultFolder; find -type d | xargs chmod u+rwx,g+rwx,o+rwx; find -type f | xargs chmod u+rw,g+rw,o+rw
done

# Always do that? 
echo 0
