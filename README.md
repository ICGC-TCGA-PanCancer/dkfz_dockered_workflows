Contains a dockerfile and several helper scripts to build and run the DKFZ workflows.

The Roddy binary is located in GNOS:
https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/b9b93aa5-e1c4-4b54-a28f-0e78b893d47c or https://gtrepo-dkfz.annailabs.com/cghub/metadata/analysisFull/0f7d22da-2438-4b9c-b788-ccd9443284b9 for a tarball.

The DKFZ dependency bundle is also located in GNOS:
https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/41f20501-3f29-480d-863d-51c47efa112e

You can download them using:

    gtdownload -vv -c gnos.pem https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/0f7d22da-2438-4b9c-b788-ccd9443284b9
    gtdownload -vv -c gnos.pem https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/b9b93aa5-e1c4-4b54-a28f-0e78b893d47c
    gtdownload -vv -c gnos.pem https://gtrepo-dkfz.annailabs.com/cghub/data/analysis/download/41f20501-3f29-480d-863d-51c47efa112e
