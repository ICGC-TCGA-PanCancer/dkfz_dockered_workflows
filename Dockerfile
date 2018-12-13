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

RUN useradd roddy -d /roddy

#RUN
RUN	echo `head -n 1 /etc/hosts | cut -f 1` master > /tmp/hostsTmp && tail -n +2 /etc/hosts >> /tmp/hostsTmp && cp /tmp/hostsTmp /etc/hosts && echo master > /etc/hostname; \
	hostName=`hostname`; \
    export HOST=$hostName; \
    /etc/init.d/gridengine-exec stop; \
    /etc/init.d/gridengine-master restart; \
    /etc/init.d/gridengine-exec start; \
    qconf -am roddy; \
    qconf -au roddy users; \
    qconf -as $HOST

ADD scripts/sgeInit.sh /roddy/sgeInit.sh

RUN echo `head -n 1 /etc/hosts | cut -f 1` master > /tmp/hostsTmp; \
	tail -n +2 /etc/hosts >> /tmp/hostsTmp; \
	cp /tmp/hostsTmp /etc/hosts; \
	echo master > /etc/hostname; \
	cat /etc/hosts; \
	hostName=`hostname`; \
    export HOST=$hostName; \
    cd /roddy; chmod 777 sgeInit.sh; \
	bash sgeInit.sh; \
	rm sgeInit.sh;

RUN mkdir /roddy/bin

RUN apt-get update; easy_install Atlas; apt-get -y install libatlas-base-dev gfortran;

RUN pip install --index-url=https://pypi.python.org/simple/ pip==10.0.1
RUN pip install scipy==0.12.0


RUN apt-get update; apt-get -y install libcairo2 libjpeg-dev ghostscript

RUN easy_install -U 'distribute'; \
    pip install numpy==1.7.0; \
    pip install pysam==0.8.0; \
    pip install matplotlib==1.0.1; \
    pip install Biopython==1.57;

ADD scripts/sgeResetup.sh /roddy/sgeResetup.sh

#ADD Roddy /roddy/bin/Roddy
# now getting Roddy binary from a public URL since authors indicated this is fine
RUN wget --quiet -O Roddy_2.2.49_COW_1.0.132-1_CNE_1.0.189.tar.gz https://dcc.icgc.org/api/v1/download?fn=/PCAWG/pcawg_dkfz_caller/Roddy_2.2.49_COW_1.0.132-1_CNE_1.0.189.tar.gz && \
    tar zxf Roddy_2.2.49_COW_1.0.132-1_CNE_1.0.189.tar.gz && \
    mv Roddy /roddy/bin/

#ADD RoddyWorkflows /roddy/bin/RoddyWorkflows

ADD runwrapper.sh /roddy/bin/runwrapper.sh

#ADD scripts/run_workflow.pl /roddy/bin/run_workflow.pl

ADD scripts/getFinalCNEFile.py /roddy/bin/getFinalCNEFile.py

ADD scripts/convertTabToJson.py /roddy/bin/convertTabToJson.py

ADD scripts/setupSGE.sh /roddy/bin/sgeConfig.txt

ADD scripts/combineJsons.py /roddy/bin/combineJsons.py

ADD scripts/python_modules /roddy/bin/python_modules

RUN cd /roddy/bin/Roddy/dist/runtimeDevel; \
    ln -sf groovy* groovy; \
    ln -sf jdk* jdk; \
    ln -sf jdk/jre jre; \
    cd /roddy/bin/Roddy && cp applicationPropertiesAllLocal.ini applicationProperties.ini; \
    bash /roddy/sgeResetup.sh; \
    qconf -Mc /roddy/bin/sgeConfig.txt; \
    mkdir -p /mnt/datastore/workflow_data; \
    mkdir /roddy/logs;

#ADD patches/projectsPanCancer.xml /roddy/bin/Roddy/dist/resources/configurationFiles/projectsPanCancer.xml

#ADD patches/pscbs_plots_functions.R /roddy/bin/Roddy/dist/plugins/COWorkflows_1.0.131/resources/analysisTools/copyNumberEstimationWorkflow/psbcs_plots_functions.R

#ADD patches/filterVcfForBias.py /roddy/bin/Roddy/dist/plugins/COWorkflows_1.0.131/resources/analysisTools/snvPipeline/filterVcfForBias.py

ADD patches/analysisCopyNumberEstimation.xml /roddy/bin/Roddy/dist/plugins/CopyNumberEstimationWorkflow_1.0.189/resources/configurationFiles/analysisCopyNumberEstimation.xml

RUN chown -R roddy:roddy /tmp/* && chown -R roddy:roddy /roddy && chmod -R 777 /data/datastore /roddy/bin /mnt/datastore /roddy/logs
RUN adduser roddy sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo '127.0.0.1  master' >> /etc/hosts

# use ansible to create our dockerfile, see http://www.ansible.com/2014/02/12/installing-and-building-docker-with-ansible
RUN mkdir /ansible
WORKDIR /ansible
RUN apt-get -y update ;\
    apt-get install -y samtools python-apt python-yaml python-jinja2 git wget sudo;\
    git clone http://github.com/ansible/ansible.git /ansible
# get a specific version of ansible , add sudo to seqware, create a working directory
RUN git checkout v1.6.10 ;
ENV PATH /ansible/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV ANSIBLE_LIBRARY /ansible/library
ENV PYTHONPATH /ansible/lib:$PYTHON_PATH

# setup sge
WORKDIR /root
COPY inventory /etc/ansible/hosts
COPY roles /root/roles
USER root
COPY scripts/start.sh /start.sh
COPY docker-start.yml /root/docker-start.yml
RUN sudo chmod a+x /start.sh

# install gosu which prevents unknown user issue
ENV GOSU_VERSION 1.10
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && chown root:users /usr/local/bin/gosu \
    && chmod +s /usr/local/bin/gosu \
    && chmod a+rx /start.sh

# modify for quick turn-around
ADD scripts/run_workflow.pl /roddy/bin/run_workflow.pl

RUN mkdir -p /roddy/.roddy/compressedAnalysisTools
RUN chown roddy:roddy /roddy/.roddy/compressedAnalysisTools

RUN cd /roddy/.roddy; \
    ln -sf /roddy/bin/Roddy/dist/runtimeDevel;

# needed for starting up the container
VOLUME /var /etc /root /usr /reference /data /roddy /mnt
# nested volumes, not sure why we need these but otherwise they end up read-only
VOLUME /var/run/gridengine

COPY jfxlibInfo /roddy/.roddy/

CMD ["/bin/bash", "/start.sh"]
