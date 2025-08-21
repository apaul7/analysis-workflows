#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

baseCommand: ["/opt/bcftools/bin/bcftools", "filter", "--include", "FILTER='PASS'"]

requirements:
    - class: ResourceRequirement
      ramMin: 4000
    - class: DockerRequirement
      dockerPull: "mgibio/bcftools-cwl:1.12"

inputs:
    output_type:
        type:
            type: enum
            symbols: ["b", "u", "z", "v"]
        default: "z"
        inputBinding:
            position: 4
            prefix: "--output-type"
        doc: "output file format"
    output_vcf_name:
        type: string?
        default: "bcftools_passed_filtered.vcf.gz"
        inputBinding:
            position: 5
            prefix: "--output"
        doc: "output vcf file name"
    vcf:
        type: File
        inputBinding:
            position: 6
        doc: "input bgzipped tabix indexed vcf to filter for PASS filter"

outputs:
    filtered_vcf:
        type: File
        outputBinding:
            glob: $(inputs.output_vcf_name)

