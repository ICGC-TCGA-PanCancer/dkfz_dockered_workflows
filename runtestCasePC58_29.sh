referenceDirectory=/home/ubuntu/dependencies/bundledFiles

[[ -z $1 ]] && echo "Either container id or - has to be submitted" && exit 0
dockerimg=${1}
[[ $dockerimg == "-" ]] && dockerimg=`docker images | head -n 2 | tail -n 1 | awk '{print $3}'` 
runcommand="/bin/bash -c 'root/bin/runwrapper.sh'"
[[ ${2-original} == "bash" ]] && runcommand=/bin/bash

docker run -t -i \
	-v $referenceDirectory:/mnt/datastore/bundledFiles \
	-v /home/ubuntu/gnos_down:/mnt/datastore/workflow_data/gnos_down \
	-v $PWD/testConfigPC58_29.ini:/mnt/datastore/workflow_data/workflow.ini \
	-v /home/ubuntu/workspace:/mnt/datastore/testdata \
	-v /home/ubuntu/testdata_results:/mnt/datastore/resultdata \
	$dockerimg $runcommand
