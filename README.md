# Developers - Building the Image

You need to build this Docker container since it contains restricted access code.  A pre-created version currently can't be found on DockerHub due to this limitation.

## Dependency Bundles

You need to download two controlled access bundles in order to build

Contains a dockerfile and several helper scripts to build and run the DKFZ workflows.

The Roddy binary is located in GNOS:
https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/7a4d2176-3a73-400d-8b58-3fed0b53798d/

The DKFZ dependency bundle is also located in GNOS:
https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/32749c9f-d8aa-4ff5-b32c-296976aec706

You can download them using:

    gtdownload -vv -c gnos.pem https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/7a4d2176-3a73-400d-8b58-3fed0b53798d
    gtdownload -vv -c gnos.pem https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/32749c9f-d8aa-4ff5-b32c-296976aec706

## Building

Once you have the above `Roddy` directory moved to the `docker/dkfz_dockered_workflows` directory you can build the Docker image.  The data bundle is actually pulled into this container at runtime.

    docker build -t pancancer/dkfz_dockered_workflows . 
