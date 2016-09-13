#!/usr/bin/env cwl-runner

class: CommandLineTool
id: DKFZ-Workflow
label: DKFZ-Workflow
dct:creator:
  '@id': http://orcid.org/0000-0002-7681-6415
  foaf:name: Brian O'Connor
  foaf:mbox: mailto:briandoconnor@gmail.com
requirements:
- class: DockerRequirement
  dockerPull: quay.io/pancancer/pcawg-dkfz-workflow:2.0.0_cwl1.0

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
  ![pcawg logo](https://dcc.icgc.org/styles/images/PCAWG-final-small.png "pcawg logo")
  # PCAWG DKFZ Workflow
  The DKFZ workflow from the ICGC PanCancer Analysis of Whole Genomes (PCAWG) project. For more information see the PCAWG project [page](https://dcc.icgc.org/pcawg) and our GitHub
  [page](https://github.com/ICGC-TCGA-PanCancer) for our code including the source for
  [this workflow](https://github.com/ICGC-TCGA-PanCancer/dkfz_dockered_workflows).

cwlVersion: v1.0

