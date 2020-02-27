#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: "Convert default cnvkit .cns output to standard vcf format"

requirements:
    - class: DockerRequirement
      dockerPull: etal/cnvkit:0.9.5
    - class: ShellCommandRequirement
    - class: ResourceRequirement
      ramMin: 8000
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
baseCommand: ["/usr/bin/python", "/usr/local/bin/cnvkit.py", "call"]
arguments: [
    { position: -1, valueFrom: $(inputs.male_reference), prefix: "-y" },
    "-o", "adjusted.tumor.cns",
    { shellQuote: false, valueFrom: "&&" },
    "/usr/bin/python", "/usr/local/bin/cnvkit.py", "export", "vcf", "adjusted.tumor.cns"
]
inputs:
    segment_filter:
        type:
          - "null"
          - type: enum
            symbols: ["ampdel", "ci", "cn", "sem"]
        inputBinding:
            position: -3
            prefix: "--filter"
        doc: "method for filtering/merging neighboring copy number segments"
    cns_file:
        type: File
        inputBinding:
            position: -2
    male_reference:
        type: boolean?
        default: false
        inputBinding:
            position: 1
            prefix: "-y"
    cnr_file:
        type: File?
        inputBinding:
            position: 2
            prefix: "--cnr"
    sample_name:
        type: string?
        inputBinding:
            position: 4
            prefix: "-i"
    output_name:
        type: string
        inputBinding:
            position: 3
            prefix: "-o"
outputs:
    cnvkit_vcf:
        type: File
        outputBinding:
            glob: $(inputs.output_name)
