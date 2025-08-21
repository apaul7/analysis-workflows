#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "runs deepsomatic"

baseCommand: ["/usr/bin/python", "/opt/deepvariant/bin/deepsomatic/run_deepsomatic.py"]

requirements:
    - class: ResourceRequirement
      coresMin: 4
      ramMin: 20000
    - class: DockerRequirement
      dockerPull: "google/deepsomatic:1.9.0"

arguments: ["--output_gvcf", "$(inputs.output_base).g.vcf.gz", "--output_vcf", "$(inputs.output_base).vcf.gz", "--make_examples_extra_args", "--max_reads_per_partition=0", "--num_shards", "$(runtime.cores)"]
inputs:
    reference:
        type:
            - string
            - File
        secondaryFiles: [.fai, ^.dict]
        inputBinding:
            position: 1
            prefix: "--ref"
        doc: "Genome reference to use. Must have an associated FAI index as well. Supports text or gzipped references. Should match the reference used to align the BAM file provided to --reads."
    tumor_bam:
        type: File
        secondaryFiles: [^.bai]
        inputBinding:
            position: 2
            prefix: "--reads_tumor"
        doc: "Required. Aligned, sorted, indexed BAM file containing the reads from  the tumor sample we want to call. Should be aligned to a reference genome compatible with --ref"
    normal_bam:
        type: File?
        secondaryFiles: [^.bai]
        inputBinding:
            position: 3
            prefix: "--reads_normal"
        doc: "Required. Aligned, sorted, indexed BAM file containing the reads from the normal sample. Should be aligned to a reference genome compatible with --ref.NOTE: It is possible to not provide this flag. However, it is not officially supported yet."
    model_type:
        type:
            type: enum
            symbols: ['WGS', 'WES', 'PACBIO', 'ONT', 'FFPE_WGS', 'FFPE_WES', 'FFPE_WGS_TUMOR_ONLY', 'FFPE_WES_TUMOR_ONLY', 'WGS_TUMOR_ONLY', 'WES_TUMOR_ONLY', 'PACBIO_TUMOR_ONLY', 'ONT_TUMOR_ONLY']
        inputBinding:
            position: 4
            prefix: "--model_type"
        doc: "Required. Type of model to use for variant calling. Set this flag to use the default model associated with each type, and it will set necessary flags corresponding to each model. If you want to use a customized model, add --customized_model flag in addition to this flag"
    normal_sample_name: 
        type: string?
        inputBinding:
            position: 5
            prefix: "--sample_name_normal"
        doc: "Sample name to use instead of the sample name from the input reads_normal BAM (SM tag in the header). This flag is used for both make_examples_somatic and postprocess_variants"
    tumor_sample_name: 
        type: string?
        inputBinding:
            position: 6
            prefix: "--sample_name_tumor"
        doc: "Sample name to use instead of the sample name from the input reads_tumor BAM (SM tag in the header). This flag is used for both make_examples_somatic and postprocess_variants"
    pon_filter:
        type: boolean?
        default: true
        inputBinding:
            position: 7
            valueFrom: |
                ${
                    return self ? "--use_default_pon_filtering=true" : null;
                }
        doc: "Optional. If true then default PON filtering will be used in tumor-only models."
    output_base:
        type: string

outputs:
    gvcf:
        type: File
        secondaryFiles: [.tbi]
        outputBinding:
            glob: "$(inputs.output_base).g.vcf.gz"
    vcf:
        type: File
        secondaryFiles: [.tbi]
        outputBinding:
            glob: "$(inputs.output_base).vcf.gz"
