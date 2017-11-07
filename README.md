# DKFZ Dockered Workflows 

A dockerised version of the Roddy workflow derived from DKFZ's workflow. This is a cleaned up version as used in the ICGC/TCGA PanCancer project. See http://pancancer.info for more information.

## Running with the Dockstore command line

[![Docker Repository on Quay](https://quay.io/repository/pancancer/pcawg-dkfz-workflow/status "Docker Repository on Quay")](https://quay.io/repository/pancancer/pcawg-dkfz-workflow)

This tool has been validated as a CWL v1.0 CommandLineTool. 

Versions that we tested with are the following 
```
dockstore version 0.4-beta.7
avro (1.8.1)
cwl-runner (1.0)
cwl-upgrader (0.1.1)
cwltool (1.0.20160712154127)
schema-salad (1.14.20160708181155)
setuptools (25.1.6)
```

Successful testing was completed with the following command. 

    dockstore tool launch --entry Dockstore.cwl --local-entry --json Dockstore-BTCA-SG.json

Warning: Execution can take upwards of 2 hours for execution with the test data (listed in Dockstore.json). However, this workflow will *crash hard* near the end, meaning that the test data can only be used to see if the workflow kicks off successfully), see [#7](https://github.com/ICGC-TCGA-PanCancer/dkfz_dockered_workflows/issues/7). This data can be downloaded and uncompressed from https://s3-eu-west-1.amazonaws.com/wtsi-pancancer/testdata/HCC1143_ds.tar

`Dockstore-BTCA-SG.json` will execute to completion but will take a more substantial amount of time to execute (on the order of 1 day on a 8-core, 58GB of RAM host.  It may fail if the host has less than 8 cores). Note that the `BTCA-SG` code corresponds to a pan-cancer donor. You will need GNOS access with ICGC priviledges to access this protected data. Additionally the output location should exist and be writeable by the executing user.

Last success tested with the following hardware:
VCPU: 38
RAM: 244.1 GB
Disk Space: 5.3 TB

In either case, the DKFZ dependency bundle can be downloaded from https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/32749c9f-d8aa-4ff5-b32c-296976aec706 also using valid GNOS credentials and gtdownload. 

## Developers - Building the Image

*Warning* the following information is not up-to-date after wrapping in CWL and should be viewed as a guide to developers only. 

You need to build this Docker container since it contains restricted access code.  A pre-created version currently can't be found on DockerHub due to this limitation.

### Dependency Bundles

You need to download a controlled access bundles in order to build.

Contains a dockerfile and several helper scripts to build and run the DKFZ workflows.

The Roddy binary is located in GNOS:
https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/971daec1-e346-4c0f-bd80-f6d1feb69968

There are two files that need to be modified in the Roddy binary. applicationPropertiesAllLocal.ini and applicationProperties.ini both specify the root user. They need to be changed to the user 'roddy' rather than 'root'.  For example, change into the extracted Roddy folder and run:

    perl -pi.orig -e 's/(CLI\.executionServiceUser=)root/${1}roddy/;' *.ini

You can download them using:

    gtdownload -vv -c gnos.pem https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/971daec1-e346-4c0f-bd80-f6d1feb69968

**NOTE:** If you intend to run this container on its own, the file below is necessary. If you are running this container as a part of [DEWrapperWorkflow](https://github.com/ICGC-TCGA-PanCancer/DEWrapperWorkflow), you will not need to download it: these dependencies will be downloaded by DEWrapperWorkflow.

The DKFZ dependency bundle is located in GNOS:
https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/32749c9f-d8aa-4ff5-b32c-296976aec706

It can be downloaded like this:

    gtdownload -vv -c gnos.pem https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/32749c9f-d8aa-4ff5-b32c-296976aec706

### Building

Once you have the above `Roddy` directory moved to the `docker/dkfz_dockered_workflows` directory you can build the Docker image.  The data bundle is actually pulled into this container at runtime. The tag `1.3` below depends on the current release of this repo.

    docker build -t quay.io/pancancer/pcawg-dkfz-workflow:2.0.0 .
