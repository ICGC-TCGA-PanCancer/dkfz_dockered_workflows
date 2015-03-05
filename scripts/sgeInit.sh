#!/bin/bash

echo `head -n 1 /etc/hosts | cut -f 1` master > /tmp/hostsTmp
tail -n +2 /etc/hosts >> /tmp/hostsTmp
cp /tmp/hostsTmp /etc/hosts && echo master > /etc/hostname
hostName=`hostname`
export HOST=$hostName

    /etc/init.d/gridengine-exec stop;
    /etc/init.d/gridengine-master restart;
    /etc/init.d/gridengine-exec start;

cat >/tmp/qconf-editor.sh <<EOF
#!/bin/sh
sleep 1
perl -pi -e 's/^hostname.*$/hostname $hostName/' \$1
EOF

chmod +x /tmp/qconf-editor.sh
export EDITOR=/tmp/qconf-editor.sh
qconf -ae
cat >/tmp/qconf-editor.sh <<EOF
#!/bin/sh
sleep 1
perl -pi -e 's/^hostlist.*$/hostlist $hostName/' \$1
EOF

chmod +x /tmp/qconf-editor.sh
export EDITOR=/tmp/qconf-editor.sh
qconf -ahgrp @allhosts
qconf -mhgrp @allhosts
qconf -aattr hostgroup hostlist $hostName @allhosts
qconf -aq main.q
qconf -mq main.q
qconf -aattr queue hostlist @allhosts main.q
qconf -aattr queue slots "[$hostName=`nproc`]" main.q
qconf -mattr queue load_thresholds "np_load_avg=`nproc`" main.q
qconf -rattr exechost complex_values s_data=`free -b |grep Mem | cut -d" " -f5` $hostName
TMPPROFILE=/tmp/serial.profile
echo "pe_name           serial
	slots             9999
	user_lists        NONE
	xuser_lists       NONE
	start_proc_args   /bin/true
	stop_proc_args    /bin/true
	allocation_rule   \$pe_slots
	control_slaves    FALSE
	job_is_first_task TRUE
	urgency_slots     min
	accounting_summary FALSE" > $TMPPROFILE
qconf -Ap $TMPPROFILE
qconf -aattr queue pe_list serial main.q
rm $TMPPROFILE
/etc/init.d/gridengine-exec stop
sleep 4
/etc/init.d/gridengine-master stop
sleep 4
pkill -9 sge_execd
pkill -9 sge_qmaster
sleep 4
/etc/init.d/gridengine-master restart
/etc/init.d/gridengine-exec restart
