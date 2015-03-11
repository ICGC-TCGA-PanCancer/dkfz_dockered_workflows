FROM ubuntu:precise 
MAINTAINER Michael Heinold @ DKFZ

ENV HOSTNAME master

RUN echo '127.0.0.1 master' | cat - /etc/hosts > /tmp/tmp_host && cp /tmp/tmp_host /etc/hosts

RUN apt-get update; \
    mkdir -p /data/datastore/ /data/binaries/; \
    chmod 777 /data/datastore /data/binaries; \
    apt-get -y install apt-utils; \
    apt-get -y install tabix procmail zip subversion make cpanminus python-dev python-pip libgfortran3 libglu1-mesa-dev alien wget libfreetype6 libfreetype6-dev libpng-dev libcurl4-openssl-dev
RUN cpanm Math::CDF; \
    cpanm XML::XPath; \
 pip install pysam==0.8.0; \
 pip install pycairo; \
 pip install numpy==1.7.0; \
 pip install python-dateutil; \
 easy_install matplotlib==1.1.0; \
 pip install Biopython==1.57; \
 pip install scipy==0.12.0; \
    wget http://ftp.hosteurope.de/mirror/ftp.opensuse.org/distribution/12.2/repo/oss/suse/x86_64/libpng14-14-1.4.11-2.5.1.x86_64.rpm; \
    alien -i libpng14-14-1.4.11-2.5.1.x86_64.rpm; \
    ln --symbolic /usr/lib64/libpng14.so.14 /usr/lib/libpng14.so.14;

RUN apt-get -q -y --force-yes install sudo vim

#Grid engine setup - This is taken from the pancancer setup for SGE clusters.
RUN export DEBIAN_FRONTEND=noninteractive; \
	echo `head -n 1 /etc/hosts | cut -f 1` master > /tmp/hostsTmp && tail -n +2 /etc/hosts >> /tmp/hostsTmp && cp /tmp/hostsTmp /etc/hosts && echo master > /etc/hostname; \
	hostName=`hostname`; \
    export HOST=$hostName; \
    apt-get -q -y --force-yes install gridengine-client gridengine-common gridengine-exec gridengine-master; \
    /etc/init.d/gridengine-exec stop; \
    /etc/init.d/gridengine-master restart; \
    /etc/init.d/gridengine-exec start;
    
#RUN	
RUN	echo `head -n 1 /etc/hosts | cut -f 1` master > /tmp/hostsTmp && tail -n +2 /etc/hosts >> /tmp/hostsTmp && cp /tmp/hostsTmp /etc/hosts && echo master > /etc/hostname; \
	hostName=`hostname`; \
    export HOST=$hostName; \
    /etc/init.d/gridengine-exec stop; \
    /etc/init.d/gridengine-master restart; \
    /etc/init.d/gridengine-exec start; \
    qconf -am root; \
    qconf -au root users; \
    qconf -as $HOST

ADD scripts/sgeInit.sh /root/sgeInit.sh

RUN echo `head -n 1 /etc/hosts | cut -f 1` master > /tmp/hostsTmp; \
	tail -n +2 /etc/hosts >> /tmp/hostsTmp; \
	cp /tmp/hostsTmp /etc/hosts; \
	echo master > /etc/hostname; \
	cat /etc/hosts; \
	hostName=`hostname`; \
    export HOST=$hostName; \
    cd ~; chmod 777 sgeInit.sh; \
	bash sgeInit.sh; \
	rm sgeInit.sh;

RUN mkdir /root/bin

RUN apt-get update; easy_install Atlas; apt-get -y install libatlas-base-dev gfortran;

RUN easy_install scipy==0.12.0

RUN apt-get update; apt-get -y install libcairo2 libjpeg-dev

ADD scripts/sgeResetup.sh /root/sgeResetup.sh

ADD Roddy /root/bin/Roddy

#ADD RoddyWorkflows /root/bin/RoddyWorkflows

ADD runwrapper.sh /root/bin/runwrapper.sh

ADD scripts/getFinalCNEFile.py /root/bin/getFinalCNEFile.py

ADD scripts/setupSGE.sh /root/bin/sgeConfig.txt

RUN cd /root/bin/Roddy/dist/runtimeDevel && ln -sf groovy* groovy && ln -sf jdk* jdk && ln -sf jdk/jre jre; \
    cd /root/bin/Roddy && cp applicationPropertiesAllLocal.ini applicationProperties.ini; \
    bash /root/sgeResetup.sh; \
    qconf -Mc /root/bin/sgeConfig.txt; \
    mkdir -p /mnt/datastore/workflow_data; \
    mkdir /root/logs;
