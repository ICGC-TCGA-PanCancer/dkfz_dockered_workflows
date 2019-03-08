#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -x

# kick off all services
HOSTNAME=`hostname`
gosu root chmod a+wrx /etc
gosu root chmod a+wrx /tmp

export TMPDIR=/tmp
env

gosu root sed -i 's/placeholder/'$HOSTNAME'/g' /etc/ansible/hosts
cat /etc/ansible/hosts
gosu root chmod -R a+wrx /root
gosu root ansible-playbook /root/docker-start.yml -c local

# newer version of cwltool no longer mounts hardcoded '/var/spool/cwl'
# as $HOME (used for output in the container). Need to pass current
# user's $HOME as output-dir. The other choice is $PWD, which is set
# using '--workdir' in 'docker run' command by cwltool. Currently version
# of cwltool set $PWD same as $HOME
OUTPUT_DIR=$HOME

# allow cwltool to pick up the results created by seqware
gosu root chmod -R a+wrx $OUTPUT_DIR

cd $OUTPUT_DIR
gosu roddy /bin/bash -c "$* --output-dir $OUTPUT_DIR"

