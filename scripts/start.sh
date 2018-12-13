#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -x

# kick off all services
HOSTNAME=`hostname`
gosu root chmod a+wrx /etc
gosu root chmod a+wrx /tmp
gosu root chmod a+wrx /var/spool/cwl
export TMPDIR=/tmp
export HOME=/var/spool/cwl
gosu root sed -i 's/placeholder/'$HOSTNAME'/g' /etc/ansible/hosts
cat /etc/ansible/hosts
gosu root chmod -R a+wrx /root
gosu root ansible-playbook /root/docker-start.yml -c local
gosu roddy ln -sf /roddy/.roddy /var/spool/cwl/.roddy
gosu roddy /bin/bash -c "$*"
#allow cwltool to pick up the results created by seqware
gosu root chmod -R a+wrx  /var/spool/cwl
