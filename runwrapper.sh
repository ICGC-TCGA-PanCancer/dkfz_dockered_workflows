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

	export pid=${aliquotIDs[$i]}
	pidPath=/mnt/datastore/testdata/$pid
	alignmentFolder=$pidPath/alignment
	snvCallingFolder=$pidPath/mpileup
	aceSeqFolder=$pidPath/ACESeq
	indelCallingFolder=$pidPath/platypus_indel
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
	[[ $runACESeq == true ]] && multiplierACESeq=5
	[[ $runSNV == true ]] && multiplierSNV=5

	# Sleep several seconds / minutes / hours to get a better queueing
	export sleepSNV=`expr $multiplierACESeq \* 60`
	export sleepIndel=`expr $multiplierACESeq \* 60 + $multiplierSNV \* 60`

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

	resultFolder=/mnt/datastore/resultdata
	resultLogFolder=/mnt/datastore/resultdata/${pid}_logs
	resultFilesFolder=/mnt/datastore/resultdata/data
	cp -r $pidPath/roddyExecutionStore $resultLogFolder
	cp /root/logs/*$pid* $resultLogFolder

	roddyVersionString=`grep useRoddyVersion /root/bin/Roddy/applicationPropertiesAllLocal.ini`
	export pluginVersionString=`grep usePluginVersion /root/bin/Roddy/applicationPropertiesAllLocal.ini`
	workflowVersion=`/root/bin/Roddy/dist/runtimeDevel/groovy/bin/groovy -e 'println args[0].split("[=]")[1].split("[,]").find { it.contains("COWorkflows") }.split("[:]")[1].replace(".", "-")' $pluginVersionString`
	# Copy the result files
	#cp -r $pidPath ${pidPath}_final
	prefixSNV=${pid}.dkfz-snvCalling_${workflowVersion}.${date}
	prefixIndel=${pid}.dkfz-indelCalling_${workflowVersion}.${date}.somatic
	prefixACESeq=${pid}.dkfz-copyNumberEstimation_${workflowVersion}.${date}.somatic

	snvVCFAllFile=$resultFolder/${prefixSNV}.all.snv_mnv.vcf.gz
	snvTbxAllFile=$resultFolder/${prefixSNV}.all.snv_mnv.vcf.gz.tbi
	snvVCFGermlineFile=$resultFolder/${prefixSNV}.germline.snv_mnv.vcf.gz
	snvTbxGermlineFile=$resultFolder/${prefixSNV}.germline.snv_mnv.vcf.gz.tbi
        snvVCFSomaticFile=$resultFolder/${prefixSNV}.somatic.snv_mnv.vcf.gz
        snvTbxSomaticFile=$resultFolder/${prefixSNV}.somatic.snv_mnv.vcf.gz.tbi
 	snvOptFile=$resultFolder/${prefixSNV}.snv_mnv.tar.gz
	indelVCFAllFile=$resultFolder${prefixIndel}.all.snv_mnv.vcf.gz
        indelTbxAllFile=$resultFolder${prefixIndel}.all.snv_mnv.vcf.gz.tbi
        indelVCFGermlineFile=$resultFolder/${prefixIndel}.germline.indel.vcf.gz
        indelTbxGermlineFile=$resultFolder/${prefixIndel}.germline.indel.vcf.gz.tbi
        indelVCFSomaticFile=$resultFolder/${prefixIndel}.somatic.indel.vcf.gz
        indelTbxSomaticFile=$resultFolder/${prefixIndel}.somatic.indel.vcf.gz.tbi
        indelOptFile=$resultFolder/${prefixIndel}.indel.tar.gz
        aceSeqVCFFile=$resultFolder/${prefixACESeq}.somatic.cnv.vcf.gz
        aceSeqTbxFile=$resultFolder/${prefixACESeq}.somatic.cnv.vcf.gz.tbi
        aceSeqOptFile=$resultFolder/${prefixACESeq}.somatic.cnv.tar.gz

	cp ${snvCallingFolder}/*pancan.vcf.gz ${snvVCFAllFile}
	cp ${snvCallingFolder}/*pancan.vcf.gz.tbi ${snvTbxAllFile}
        perl -e 'use warnings; use strict; open(IN, "zcat $ARGV[0] |") or die "Could not open the zipped vcf file $ARGV[0]\n";open(GER, "| bgzip > $ARGV[1]") or die "Could not open the germline outfile $ARGV[1]\n";open(SOM, "| bgzip > $ARGV[2]") or die "Could not open the somatic outfile $ARGV[2]\n";while(<IN>){if($_ =~ /^#/){print GER $_; print SOM $_; next;}if($_ =~ /GERMLINE/){print GER $_;next;}if($_ =~ /SOMATIC/){print SOM $_; next;}}' ${snvCallingFolder}/*pancan.vcf.gz ${snvVCFGermlineFile} ${snvVCFSomaticFile} || exit 2

        cp ${indelCallingFolder}/*pancan.vcf.gz ${indelVCFAllFile}
        cp ${indelCallingFolder}/*pancan.vcf.gz.tbi ${indelTbxAllFile}
        perl -e 'use warnings; use strict; open(IN, "zcat $ARGV[0] |") or die "Could not open the zipped vcf file $ARGV[0]\n";open(GER, "| bgzip > $ARGV[1]") or die "Could not open the germline outfile $ARGV[1]\n";open(SOM, "| bgzip > $ARGV[2]") or die "Could not open the somatic outfile $ARGV[2]\n";while(<IN>){if($_ =~ /^#/){print GER $_; print SOM $_; next;}if($_ =~ /GERMLINE/){print GER $_;next;}if($_ =~ /SOMATIC/){print SOM $_; next;}}' ${indelCallingFolder}/*pancan.vcf.gz ${indelVCFGermlineFile} ${indelVCFSomaticFile} || exit 3

	tabix -p vcf ${snvVCFGermlineFile}
	tabix -p vcf ${snvVCFSomaticFile}
	tabix -p vcf ${indelVCFGermlineFile}
	tabix -p vcf ${indelVCFSomaticFile}

	finalCNEFile=`python /root/bin/get_vcfNamePCAWG.py $pid $aceSeqFolder`

#Tar up SNV tarball
        (tar -cvzf ${resultFolder}/${prefixSNV}_all.somatic.snv_mnv.tar.gz $snvCallingFolder/*error_plot_before_filter.pdf $snvCallingFolder/*allSNVdiagnosticsPlots.pdf) &
        #And the indel tarball
        (tar -cvzf ${resultFolder}/${prefixSNV}_all.somatic.indel.tar.gz $indelCallingFolder/*raw*) &
        #And finally the aceseq tarball
        (tar --exclude=*pancan* -cvzf ${resultFolder}/${prefixACESeq}_all.somatic.cnv.tar.gz ${aceSeqFolder}/*.txt ${aceSeqFolder}/*.gz ${aceSeqFolder}/*.tbi ${aceSeqFolder}/*.png ${aceSeqFolder}/cnv_snp/ ${aceSeqFolder}/plots/) &
#       exit 0
        wait

done

# Always do that?
echo 0
