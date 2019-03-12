FROM ubuntu:precise 
MAINTAINER Michael Heinold @ DKFZ

ENV HOSTNAME master

# install the dependencies
RUN apt-get update && apt-get install -y \
    alien \
    apt-utils \
    cpanminus \
    git \
    gfortran \
    ghostscript \
    libatlas-base-dev \
    libcairo2 \
    libcurl4-openssl-dev \
    libfreetype6 \
    libfreetype6-dev \
    libgfortran3 \
    libglu1-mesa-dev \
    libjpeg-dev \
    libpng-dev \
    make \
    procmail \
    python-apt \
    python-dev \
    python-jinja2 \
    python-pip \
    python-yaml \
    samtools \
    subversion \
    sudo \
    tabix \
    vim \
    wget \
    zip \
    && rm -rf /var/lib/apt/lists/*

# install perl modules
RUN cpanm Math::CDF

# install python modules
RUN pip install --index-url https://pypi.python.org/simple/ --upgrade pip && hash -r
RUN pip install pysam==0.8.0 \
    && pip install numpy==1.7.0 \
    && pip install python-dateutil \
    && pip install matplotlib==1.0.1 \
    && pip install Biopython==1.57 \
    && pip install scipy==0.12.0

# add user
RUN useradd roddy -d /roddy
RUN adduser roddy sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# copy files
COPY scripts/sgeResetup.sh /roddy/sgeResetup.sh

COPY scripts/sgeInit.sh /roddy/sgeInit.sh

COPY runwrapper.sh /roddy/bin/runwrapper.sh

COPY scripts/run_workflow.pl /roddy/bin/run_workflow.pl

COPY scripts/getFinalCNEFile.py /roddy/bin/getFinalCNEFile.py

COPY scripts/convertTabToJson.py /roddy/bin/convertTabToJson.py

COPY scripts/setupSGE.sh /roddy/bin/sgeConfig.txt

COPY scripts/combineJsons.py /roddy/bin/combineJsons.py

COPY scripts/python_modules /roddy/bin/python_modules/

# now getting Roddy binary from a public URL since authors indicated this is fine
RUN wget --quiet -O Roddy_2.2.49_COW_1.0.132-1_CNE_1.0.189.tar.gz https://dcc.icgc.org/api/v1/download?fn=/PCAWG/pcawg_dkfz_caller/Roddy_2.2.49_COW_1.0.132-1_CNE_1.0.189.tar.gz \
    && tar zxf Roddy_2.2.49_COW_1.0.132-1_CNE_1.0.189.tar.gz \
    && mv Roddy /roddy/bin/

COPY patches/analysisCopyNumberEstimation.xml /roddy/bin/Roddy/dist/plugins/CopyNumberEstimationWorkflow_1.0.189/resources/configurationFiles/analysisCopyNumberEstimation.xml

RUN cd /roddy/bin/Roddy/dist/plugins/CopyNumberEstimationWorkflow_1.0.189/resources/configurationFiles \
    && for f in *.xml; do cat $f |perl -nae 'if(/ memory="(.+?)"/) {$mem=$1; s/ memory=".+?"/ memory="6"/ if $mem < 6}; print' > tmp.xml && mv tmp.xml $f; done

RUN cd /roddy/bin/Roddy/dist/plugins/COWorkflows_1.0.132-1/resources/configurationFiles \
    && for f in *.xml; do cat $f |perl -nae 'if(/ memory="(.+?)"/) {$mem=$1; s/ memory=".+?"/ memory="6"/ if $mem < 6}; print' > tmp.xml && mv tmp.xml $f; done

RUN cd /roddy/bin/Roddy/dist/plugins/DefaultPlugin/resources/configurationFiles \
    && for f in *.xml; do cat $f |perl -nae 'if(/ memory="(.+?)"/) {$mem=$1; s/ memory=".+?"/ memory="6"/ if $mem < 6}; print' > tmp.xml && mv tmp.xml $f; done


#Grid engine setup - This is taken from the pancancer setup for SGE clusters.
RUN export DEBIAN_FRONTEND=noninteractive \
    && echo `head -n 1 /etc/hosts | cut -f 1` master > /tmp/hostsTmp \
    && tail -n +2 /etc/hosts >> /tmp/hostsTmp \
    && cp /tmp/hostsTmp /etc/hosts \
    && echo master > /etc/hostname \
	&& hostName=`hostname` \
    && export HOST=$hostName \
    && apt-get update && apt-get install -y \
    gridengine-client \
    gridengine-common \
    gridengine-exec \
    gridengine-master \
    && rm -rf /var/lib/apt/lists/* \
    && /etc/init.d/gridengine-exec stop \
    && /etc/init.d/gridengine-master restart \
    && /etc/init.d/gridengine-exec start \
    && qconf -am roddy \
    && qconf -au roddy users \
    && qconf -as $HOST \
    && cd /roddy \
    && chmod 777 sgeInit.sh \
    && bash sgeInit.sh \
    && rm sgeInit.sh

RUN cd /roddy/bin/Roddy/dist/runtimeDevel \
    && ln -sf groovy* groovy \
    && ln -sf jdk* jdk \
    && ln -sf jdk/jre jre \
    && cd /roddy/bin/Roddy \
    && cp applicationPropertiesAllLocal.ini applicationProperties.ini \
    && chmod a+x /roddy/sgeResetup.sh \
    && bash /roddy/sgeResetup.sh \
    && qconf -Mc /roddy/bin/sgeConfig.txt

RUN mkdir -p /mnt/datastore/workflow_data \
    && mkdir -p /roddy/logs \
    && mkdir -p /data/datastore/ /data/binaries/ \
    && chmod 777 /data/datastore /data/binaries /mnt/datastore /roddy/bin /roddy/logs

RUN chown -R roddy:roddy /tmp/* \
    && chown -R roddy:roddy /roddy

# use ansible to create our dockerfile, see http://www.ansible.com/2014/02/12/installing-and-building-docker-with-ansible
RUN mkdir /ansible
WORKDIR /ansible

# get a specific version of ansible , add sudo to seqware, create a working directory
RUN git clone http://github.com/ansible/ansible.git /ansible \
    && git checkout v1.6.10
ENV PATH /ansible/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV ANSIBLE_LIBRARY /ansible/library
ENV PYTHONPATH /ansible/lib:$PYTHONPATH

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

# needed for starting up the container
VOLUME /var /etc /root /usr /reference /data /roddy /mnt
# nested volumes, not sure why we need these but otherwise they end up read-only
VOLUME /var/run/gridengine

CMD ["/bin/bash", "/start.sh"]