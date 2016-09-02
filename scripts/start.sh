#!/usr/bin/env bash
set -o errexit
set -o pipefail

# kick off all services
HOSTNAME=`hostname`
echo $HOSTNAME
sed -i 's/placeholder/'$HOSTNAME'/g' /etc/ansible/hosts
cat /etc/ansible/hosts
ansible-playbook /root/docker-start.yml -c local
#cd ~seqware
#source ~seqware/.bash_profile
#source ~seqware/.bashrc 
#sudo -E -u seqware -i /bin/bash -c "${1-bash}"
sudo -E -u roddy -i /bin/bash -c "${1-bash}"
