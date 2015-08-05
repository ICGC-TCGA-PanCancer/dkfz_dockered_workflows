# Developers - Building the Image

You need to build this Docker container since it contains restricted access code.  A pre-created version currently can't be found on DockerHub due to this limitation.

## Dependency Bundles

You need to download a controlled access bundles in order to build.

Contains a dockerfile and several helper scripts to build and run the DKFZ workflows.

The Roddy binary is located in GNOS:
https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/971daec1-e346-4c0f-bd80-f6d1feb69968

There are two files that need to be modified in the Roddy binary. applicationPropertiesAllLocal.ini and applicationProperties.ini both specify the root user. They need to be changed to the user 'roddy' rather than 'root'.  For example, change into the extracted Roddy folder and run:

    perl -pi.orig -e 's/(CLI\.executionServiceUser=)root/${1}roddy/;' *.ini

You can download them using:

    gtdownload -vv -c gnos.pem https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/971daec1-e346-4c0f-bd80-f6d1feb69968

**NOTE:** If you intend to run this container on its own, the file below is necessary. If you are running this container as a part of [DEWrapperWorkflow](https://github.com/ICGC-TCGA-PanCancer/DEWrapperWorkflow), you will not need to downloade: these dependencies will be downloaded by DEWrapperWorkflow.

The DKFZ dependency bundle is located in GNOS:
https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/32749c9f-d8aa-4ff5-b32c-296976aec706

It can be downloaded like this:

    gtdownload -vv -c gnos.pem https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/32749c9f-d8aa-4ff5-b32c-296976aec706

## Building

Once you have the above `Roddy` directory moved to the `docker/dkfz_dockered_workflows` directory you can build the Docker image.  The data bundle is actually pulled into this container at runtime. The tag `1.3` below depends on the current release of this repo.

    docker build -t pancancer/dkfz_dockered_workflows:1.3 . 
