#!/usr/bin/env cwl-runner

class: CommandLineTool
id: DKFZ-Workflow
label: DKFZ-Workflow
dct:creator:
  '@id': http://orcid.org/0000-0002-7681-6415
  foaf:name: Brian O'Connor
  foaf:mbox: mailto:briandoconnor@gmail.com

dct:contributor:
  foaf:name: Denis Yuen
  foaf:mbox: mailto:denis.yuen@oicr.on.ca

requirements:
- class: DockerRequirement
  dockerPull: quay.io/pancancer/pcawg-dkfz-workflow:standard-output-names

cwlVersion: v1.0

inputs:
  normal-bam:
    type: File
    inputBinding:
      position: 1
      prefix: --normal-bam
    secondaryFiles:
    - .bai
  tumor-bam:
    type: File
    inputBinding:
      position: 2
      prefix: --tumor-bam
    secondaryFiles:
    - .bai
  reference-gz:
    type: File
    inputBinding:
      position: 3
      prefix: --reference-gz
  delly-bedpe:
    type: File
    inputBinding:
      position: 4
      prefix: --delly-bedpe
  run-id:
    type: string?
    inputBinding:
      position: 5
      prefix: --run-id


outputs:
  somatic_cnv_tar_gz:
    type: File
    outputBinding:
      glob: '*.somatic.cnv.tar.gz'
    secondaryFiles:
    - .md5
  somatic_cnv_vcf_gz:
    type: File
    outputBinding:
      glob: '*.somatic.cnv.vcf.gz'
    secondaryFiles:
    - .md5
    - .tbi
    - .tbi.md5
  germline_indel_vcf_gz:
    type: File
    outputBinding:
      glob: '*.germline.indel.vcf.gz'
    secondaryFiles:
    - .md5
    - .tbi
    - .tbi.md5
  somatic_indel_tar_gz:
    type: File
    outputBinding:
      glob: '*.somatic.indel.tar.gz'
    secondaryFiles:
    - .md5
  somatic_indel_vcf_gz:
    type: File
    outputBinding:
      glob: '*.somatic.indel.vcf.gz'
    secondaryFiles:
    - .md5
    - .tbi
    - .tbi.md5
  germline_snv_mnv_vcf_gz:
    type: File
    outputBinding:
      glob: '*.germline.snv_mnv.vcf.gz'
    secondaryFiles:
    - .md5
    - .tbi
    - .tbi.md5
  somatic_snv_mnv_tar_gz:
    type: File
    outputBinding:
      glob: '*.somatic.snv_mnv.tar.gz'
    secondaryFiles:
    - .md5
  somatic_snv_mnv_vcf_gz:
    type: File
    outputBinding:
      glob: '*.somatic.snv_mnv.vcf.gz'
    secondaryFiles:
    - .md5
    - .tbi
    - .tbi.md5
  qc_metrics:
    type: File
    outputBinding:
      glob: '*.qc_metrics.tar.gz'
    secondaryFiles:
    - .md5

baseCommand: [/start.sh, perl, /roddy/bin/run_workflow.pl]
doc: |
    PCAWG DKFZ variant calling workflow is developed by German Cancer Research Center
    (DKFZ, https://www.dkfz.de), it consists of software components calling somatic substitutions, indels
    and copy number variations using uniformly aligned tumor / normal WGS sequences. The workflow has been
    dockerized and packaged using CWL workflow language, the source code is available on
    GitHub at: https://github.com/ICGC-TCGA-PanCancer/dkfz_dockered_workflows.

    This workflow has been tested using cwltool version *1.0.20180116213856*. Newer cwltool may not work.

    ## Run the workflow with your own data

    ### Prepare compute environment and install software packages
    The workflow has been tested in Ubuntu 16.04 Linux environment with the following hardware and software
    settings.

    #### Hardware requirement (assuming 30X coverage whole genome sequence)
    - CPU core: 16
    - Memory: 64GB
    - Disk space: 1TB

    #### Software installation
    - Docker (1.12.6): follow instructions to install Docker https://docs.docker.com/engine/installation
    - CWL tool
    ```
    pip install cwltool==1.0.20180116213856
    ```

    ### Prepare input data
    #### Input aligned tumor / normal BAM files

    The workflow uses a pair of aligned BAM files as input, one BAM for tumor, the other for normal,
    both from the same donor. Here we assume file names are *tumor_sample.bam* and *normal_sample.bam*,
    and are under *bams* subfolder.

    #### Dependent structural variant file
    This is a file produced by EMBL (aka DELLY) structural variation calling workflow. Please follow instruction
    [here](https://dockstore.org/containers/quay.io/pancancer/pcawg_delly_workflow) to run EMBL workflow
    to get the *run_id.embl-delly.somatic.sv.bedpe.txt* file.

    #### Reference data file

    The workflow also uses one precompiled reference file (*dkfz-workflow-dependencies_150318_0951.tar.gz*) as input,
    they can be downloaded from the ICGC Data Portal under https://dcc.icgc.org/releases/PCAWG/reference_data/pcawg-dkfz.
    We assume the reference file is under *reference* subfolder.

    #### Job JSON file for CWL

    Finally, we need to prepare a JSON file with input, reference and output files specified. Please replace
    the *tumor* and *normal* parameters with your real BAM file names. Parameters for output are file name
    suffixes, usually don't need to be changed.

    Name the JSON file: *pcawg-dkfz-variant-caller.job.json*
    ```
    {
      "run-id": "run_id",
      "tumor-bam": {
        "path":"bams/tumor_sample.bam",
        "class":"File"
      },
      "normal-bam": {
        "path":"bams/normal_sample.bam",
        "class":"File"
      },
      "reference-gz": {
        "path": "reference/dkfz-workflow-dependencies_150318_0951.tar.gz",
        "class": "File"
      },
      "delly-bedpe":
      {
        "path":"delly-bedpe/run_id.embl-delly.somatic.sv.bedpe.txt",
        "class":"File"
      },
      "germline_indel_vcf_gz": {
        "path": "germline.indel.vcf.gz",
        "class": "File"
      },
      "somatic_snv_mnv_vcf_gz": {
        "path": "somatic.snv.mnv.vcf.gz",
        "class": "File"
      },
      "germline_snv_mnv_vcf_gz": {
        "path": "germline.snv.mnv.vcf.gz",
        "class": "File"
      },
      "somatic_cnv_tar_gz": {
        "path": "somatic.cnv.tar.gz",
        "class": "File"
      },
      "somatic_cnv_vcf_gz": {
        "path": "somatic.cnv.vcf.gz",
        "class": "File"
      },
      "somatic_indel_tar_gz": {
        "path": "somatic.indel.tar.gz",
        "class": "File"
      },
      "somatic_snv_mnv_tar_gz": {
        "path": "somatic.snv.mnv.tar.gz",
        "class": "File"
      },
      "somatic_indel_vcf_gz": {
        "path": "somatic.indel.vcf.gz",
        "class": "File"
      }
    }
    ```

    ### Run the workflow
    #### Option 1: Run with CWL tool
    - Download CWL workflow definition file
    ```
    wget -O pcawg-dkfz-variant-caller.cwl "https://github.com/ICGC-TCGA-PanCancer/dkfz_dockered_workflows/blob/2.0.2_cwl1.0/Dockstore.cwl"
    ```

    - Run `cwltool` to execute the workflow
    ```
    nohup cwltool --debug --non-strict pcawg-dkfz-variant-caller.cwl pcawg-dkfz-variant-caller.job.json > pcawg-dkfz-variant-caller.log 2>&1 &
    ```

    #### Option 2: Run with the Dockstore CLI
    See the *Launch with* section below for details.
