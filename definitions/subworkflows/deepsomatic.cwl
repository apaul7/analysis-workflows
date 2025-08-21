#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "run deepsomatic workflow"
requirements:
    - class: MultipleInputFeatureRequirement
    - class: SubworkflowFeatureRequirement
inputs:
    reference:
        type:
            - string
            - File
        secondaryFiles: [.fai, ^.dict]
    tumor_bam:
        type: File
        secondaryFiles: [^.bai, .bai]
    normal_bam:
        type: File?
        secondaryFiles: [^.bai]
    tumor_sample_name:
        type: string?
    normal_sample_name:
        type: string?
    model_type:
       type:
           type: enum
           symbols: ['WGS', 'WES', 'PACBIO', 'ONT', 'FFPE_WGS', 'FFPE_WES', 'FFPE_WGS_TUMOR_ONLY', 'FFPE_WES_TUMOR_ONLY', 'WGS_TUMOR_ONLY', 'WES_TUMOR_ONLY', 'PACBIO_TUMOR_ONLY', 'ONT_TUMOR_ONLY']
       default: "WES_TUMOR_ONLY"
    pon_filter:
       type: boolean?
       default: true
    output_base:
       type: string
       default: "deepsomatic"

outputs:
    unfiltered_vcf:
        type: File
        outputSource: deepsomatic/vcf
        secondaryFiles: [.tbi]
    filtered_vcf:
        type: File
        outputSource: index/indexed_vcf
        secondaryFiles: [.tbi]
    gvcf:
        type: File
        outputSource: deepsomatic/gvcf
        secondaryFiles: [.tbi]
steps:
    deepsomatic:
        run: ../tools/deepsomatic.cwl
        in:
            reference: reference
            tumor_bam: tumor_bam
            tumor_sample_name: tumor_sample_name
            normal_bam: normal_bam
            normal_sample_name: normal_sample_name
            model_type: model_type
            pon_filter: pon_filter
            output_base: output_base
        out:
            [gvcf, vcf]
    filter:
        run: ../tools/bcftools_pass_filter.cwl
        in:
            vcf: deepsomatic/vcf
            output_vcf_name:
                default: "deepsomatic.pass.vcf.gz"
        out:
            [filtered_vcf]
    index:
        run: ../tools/index_vcf.cwl
        in:
            vcf: filter/filtered_vcf
        out:
            [indexed_vcf]
