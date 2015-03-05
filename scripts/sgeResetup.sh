#!/bin/bash
echo `head -n 1 /etc/hosts | cut -f 1` master > /tmp/hostsTmp
tail -n +2 /etc/hosts >> /tmp/hostsTmp
cp /tmp/hostsTmp /etc/hosts && echo master > /etc/hostname
hostName=`hostname`
export HOST=$hostName

/etc/init.d/gridengine-exec stop
/etc/init.d/gridengine-master restart
/etc/init.d/gridengine-exec start

