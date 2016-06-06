#!/usr/bin/env cwl-runner

class: CommandLineTool
id: "DKFZ-Workflow"
label: "DKFZ-Workflow"

description: |
    ![pcawg logo](https://dcc.icgc.org/styles/images/PCAWG-final-small.png "pcawg logo")
    # PCAWG DKFZ Workflow
    The DKFZ workflow from the ICGC PanCancer Analysis of Whole Genomes (PCAWG) project. For more information see the PCAWG project [page](https://dcc.icgc.org/pcawg) and our GitHub
    [page](https://github.com/ICGC-TCGA-PanCancer) for our code including the source for
    [this workflow](https://github.com/ICGC-TCGA-PanCancer/dkfz_dockered_workflows).
    ## IMPORTANT NOTE
    This workflow is not yet compatible with the Dockstore CLI since it uses two non-standard parametrizations for
    Docker.  Because of this, the usage command show below uses a direct Docker call.  Future releases will
    use the Docker command line interface since this is simpler.  In the command below make sure you
    substitute the correct file paths for your system.
    ```
    Usage:
    # using direct docker call to ensure '-h master' is used and the root filesystem is writeable
    $> docker run -it --volume=<PATH>/dkfz-workflow-dependencies_150318_0951.tar.gz:/var/lib/cwl/dkfz-workflow-dependencies_150318_0951.tar.gz:ro \
       -h master \
       --volume=<PATH>/normal.bam:/var/lib/cwl/normal.bam:ro \
       --volume=<PATH>/tumor.bam:/var/lib/cwl/tumor.bam:ro \
       --volume=<PATH>/delly.bedpe.txt:/var/lib/cwl/delly.bedpe.txt:ro \
       --volume=<PATH>/outputs:/var/spool/cwl:rw \
       --volume=<PATH>:/tmp:rw \
       --workdir=/var/spool/cwl \
       --user=1000 --rm --env=TMPDIR=/tmp \
       quay.io/pancancer/pcawg-dkfz-workflow:2.0.0 /bin/bash
    # now run the wrapper inside this container to execute the workflow
    $>perl /roddy/bin/run_workflow.pl --run-id run_id \
           --normal-bam /var/lib/cwl/normal.bam --tumor-bam /var/lib/cwl/tumor.bam \
           --reference-gz /var/lib/cwl/dkfz-workflow-dependencies_150318_0951.tar.gz  \
           --delly-bedpe /var/lib/cwl/delly.bedpe.txt
    ```

dct:creator:
  "@id": "http://orcid.org/0000-0002-7681-6415"
  foaf:name: "Brian O'Connor"
  foaf:mbox: "mailto:briandoconnor@gmail.com"

requirements:
  - class: ExpressionEngineRequirement
    id: "#node-engine"
    requirements:
    - class: DockerRequirement
      dockerPull: commonworkflowlanguage/nodejs-engine
    engineCommand: cwlNodeEngine.js
  - class: DockerRequirement
    dockerPull: quay.io/pancancer/pcawg-dkfz-workflow:2.0.0

inputs:
  - id: "#run-id"
    type: string
    inputBinding:
      position: 1
      prefix: "--run-id"
  - id: "#normal-bam"
    type: File
    inputBinding:
      position: 2
      prefix: "--normal-bam"
  - id: "#tumor-bam"
    type: File
    inputBinding:
      position: 3
      prefix: "--tumor-bam"
  - id: "#reference-gz"
    type: File
    inputBinding:
      position: 4
      prefix: "--reference-gz"

outputs:
  - id: "#somatic_sv_vcf"
    type: File
    outputBinding:
      glob: "*.somatic.snv_mnv.vcf.gz"

baseCommand: ["perl", "/roddy/bin/run_workflow.pl"]
