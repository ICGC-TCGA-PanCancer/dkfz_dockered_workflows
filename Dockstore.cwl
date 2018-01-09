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
  dockerPull: quay.io/pancancer/pcawg-dkfz-workflow:2.0.1_cwl1.0

inputs:
  run-id:
    type: string
    inputBinding:
      position: 1
      prefix: --run-id
  tumor-bam:
    type: File
    inputBinding:
      position: 3
      prefix: --tumor-bam
  normal-bam:
    type: File
    inputBinding:
      position: 2
      prefix: --normal-bam
  reference-gz:
    type: File
    inputBinding:
      position: 4
      prefix: --reference-gz
  delly-bedpe:
    type: File
    inputBinding:
      position: 5 
      prefix: --delly-bedpe

outputs:
  somatic_cnv_tar_gz:
    type: File
    outputBinding:
      glob: '*.somatic.cnv.tar.gz'
  somatic_cnv_vcf_gz:
    type: File
    outputBinding:
      glob: '*.somatic.cnv.vcf.gz'
  germline_indel_vcf_gz:
    type: File
    outputBinding:
      glob: '*.germline.indel.vcf.gz'
  somatic_indel_tar_gz:
    type: File
    outputBinding:
      glob: '*.somatic.indel.tar.gz'
  somatic_indel_vcf_gz:
    type: File
    outputBinding:
      glob: '*.somatic.indel.vcf.gz'
  germline_snv_mnv_vcf_gz:
    type: File
    outputBinding:
      glob: '*.germline.snv_mnv.vcf.gz'
  somatic_snv_mnv_tar_gz:
    type: File
    outputBinding:
      glob: '*.somatic.snv_mnv.tar.gz'
  somatic_snv_mnv_vcf_gz:
    type: File
    outputBinding:
      glob: '*.somatic.snv_mnv.vcf.gz'

baseCommand: [/start.sh, perl, /roddy/bin/run_workflow.pl]
doc: |
  PCAWG DKFZ variant calling workflow is developed by German Cancer Research Center (DKFZ, [https://www.dkfz.de](https://www.dkfz.de)), it consists of software components calling somatic substitutions, indels and copy number variations using uniformly aligned tumor / normal WGS sequences. The workflow has been dockerized and packaged using CWL workflow language, the source code is available on GitHub at: [https://github.com/ICGC-TCGA-PanCancer/dkfz_dockered_workflows](https://github.com/ICGC-TCGA-PanCancer/dkfz_dockered_workflows). The workflow is also registered in Dockstore at: [https://dockstore.org/containers/quay.io/pancancer/pcawg-dkfz-workflow](https://dockstore.org/containers/quay.io/pancancer/pcawg-dkfz-workflow).


    ## Run the workflow with your own data
    
    ### Prepare compute environment and install software packages
    The workflow has been tested in Ubuntu 16.04 Linux environment with the following hardware and software settings.
    
    1. Hardware requirement (assuming X30 coverage whole genome sequence)
    - CPU core: 16
    - Memory: 64GB
    - Disk space: 1TB
    
    2. Software installation
    - Docker (1.12.6): follow instructions to install Docker https://docs.docker.com/engine/installation
    - CWL tool
    ```
    pip install cwltool==1.0.20170217172322
    ```
    
    ### Prepare input data
    1. Input aligned tumor / normal BAM files
    
    The workflow uses a pair of aligned BAM files as input, one BAM for tumor, the other for normal, both from the same donor. Here we assume file names are `tumor_sample.bam` and `normal_sample.bam`, and both files are under `bams` subfolder.
    
    2. Dependent structural variant input file
    This is a file produced by EMBL (aka DELLY) workflow. Please follow instruction [here](#!Synapse:syn2351328/wiki/506133) to run EMBL workflow.
    
    3. Reference data file
    
    The workflow also uses one precompiled reference files as input, they can be downloaded from the ICGC Data Portal at [https://dcc.icgc.org/releases/PCAWG/reference_data/pcawg-dkfz](https://dcc.icgc.org/releases/PCAWG/reference_data/pcawg-dkfz). We assume the reference file is under `reference` subfolder. 
    
    4. Job JSON file for CWL
    
    Finally, we need to prepare a JSON file with input, reference and output files specified. Please replace the `tumor` and `normal` parameters with your real BAM file names. Parameters for output are file name suffixes, usually don't need to be changed.
    
    Name the JSON file: `pcawg-dkfz-variant-caller.job.json`
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


cwlVersion: v1.0

