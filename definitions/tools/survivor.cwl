#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "Run SURVIVOR to merge SV calls"

baseCommand: ["/bin/bash", "/usr/bin/survivor_merge_helper.sh"]

requirements:
    - class: InlineJavascriptRequirement
    - class: DockerRequirement
      dockerPull: "mgibio/survivor-cwl:1.0.6.2"
    - class: ResourceRequirement
      ramMin: 2000
      coresMin: 1
    - class: StepInputExpressionRequirement

inputs:
    vcfs:
        type: File[]
        inputBinding:
            position: 1
            itemSeparator: ","
        doc: "Array of VCFs to merge SV calls of"
    max_distance_to_merge:
        type: int
        inputBinding:
            position: 2
        doc: "Maximum distance of variants to consider for merging"
    minimum_sv_calls:
        type: int
        inputBinding:
            position: 3
        doc: "Minimum number of sv calls needed to be merged"
    same_type:
        type: boolean
        inputBinding:
            position: 4
            valueFrom: |
                ${
                  if(inputs.same_type){
                    return "1";
                  } else {
                    return "0";
                  }
                }
        doc: "Require merged SVs to be of the same type"
    same_strand:
        type: boolean
        inputBinding:
            position: 5
            valueFrom: |
                ${
                  if(inputs.same_strand){
                    return "1";
                  } else {
                    return "0";
                  }
                }
        doc: "Require merged SVs to be on the same strand"
    estimate_sv_distance:
        type: boolean
        inputBinding:
            position: 6
            valueFrom: |
                ${
                  if(inputs.estimate_sv_distance){
                    return "1";
                  } else {
                    return "0";
                  }
                }
        doc: "Estimate distance based on the size of SV"
    minimum_sv_size:
        type: int
        inputBinding:
            position: 7
        doc: "Minimum size of SVs to merge"
    output_name:
        type: string?
        inputBinding:
            position: 8
        default: "SURVIVOR-sv-merged.vcf"
        doc: "Used to generate the output file name"

outputs:
  merged_vcf:
    type: File
    outputBinding:
      glob: "$(inputs.output_name)"

