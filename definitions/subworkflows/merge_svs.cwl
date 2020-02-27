#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "Merge, annotate, and generate a TSV for SVs"
requirements:
    - class: ScatterFeatureRequirement
    - class: SubworkflowFeatureRequirement
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement

inputs:
    cohort_name:
        type: string?
    estimate_sv_distance:
        type: boolean
    genome_build:
        type: string
    max_distance_to_merge:
        type: int
    minimum_sv_calls:
        type: int
    minimum_sv_size:
        type: int
    same_strand:
        type: boolean
    same_type:
        type: boolean
    snps_vcf:
        type: File?
    sv_vcfs:
        type: File[]
outputs:
    bcftools_sv_vcf:
        type: File
        outputSource: bcftools_bgzip_merged_sv_vcf/bgzipped_file
    bcftools_annotated_tsv:
        type: File
        outputSource: bcftools_annotate_variants/sv_variants_tsv
    bcftools_annotated_tsv_filtered:
       type: File
       outputSource: bcftools_annotsv_filter/filtered_tsv
    bcftools_annotated_tsv_filtered_no_cds:
       type: File
       outputSource: bcftools_annotsv_filter_no_cds/filtered_tsv
    survivor_sv_vcf:
        type: File
        outputSource: survivor_bgzip_merged_sv_vcf/bgzipped_file
    survivor_annotated_tsv:
        type: File
        outputSource: survivor_annotate_variants/sv_variants_tsv
    survivor_annotated_tsv_filtered:
        type: File
        outputSource: survivor_annotsv_filter/filtered_tsv
    survivor_annotated_tsv_filtered_no_cds:
        type: File
        outputSource: survivor_annotsv_filter_no_cds/filtered_tsv
steps:
    survivor_merge_sv_vcfs:
        run: ../tools/survivor.cwl
        in: 
            vcfs: sv_vcfs
            max_distance_to_merge: max_distance_to_merge
            minimum_sv_calls: minimum_sv_calls
            same_type: same_type
            same_strand: same_strand
            estimate_sv_distance: estimate_sv_distance
            minimum_sv_size: minimum_sv_size
            cohort_name:
                default: "SURVIVOR-sv-merged.vcf"
        out:
            [merged_vcf]
    survivor_annotate_variants:
        run: ../tools/annotsv.cwl
        in:
            genome_build: genome_build
            input_vcf: survivor_merge_sv_vcfs/merged_vcf
            output_tsv_name:
                default: "SURVIVOR-merged-AnnotSV.tsv"
            snps_vcf:
                source: [snps_vcf]
                valueFrom: |
                    ${
                      if(self){
                        return [self];
                      }else{
                        return null;
                      }
                    }
        out:
            [sv_variants_tsv]
    survivor_bgzip_merged_sv_vcf:
        run: ../tools/bgzip.cwl
        in:
            file: survivor_merge_sv_vcfs/merged_vcf
        out:
            [bgzipped_file]
    bcftools_merge_sv_vcfs:
        run: ../tools/bcftools_merge.cwl
        in:
            merge_method:
                default: "none"
            output_type:
                default: "v"
            output_vcf_name:
                default: "bcftools-sv-merged.vcf"
            vcfs: sv_vcfs
        out:
            [merged_sv_vcf]
    bcftools_annotate_variants:
        run: ../tools/annotsv.cwl
        in:
            genome_build: genome_build
            input_vcf: bcftools_merge_sv_vcfs/merged_sv_vcf
            output_tsv_name:
                default: "bcftools-merged-AnnotSV.tsv"
            snps_vcf:
                source: [snps_vcf]
                valueFrom: |
                    ${
                      if(self){
                        return [self];
                      }else{
                        return null;
                      }
                    }
        out:
            [sv_variants_tsv]
    bcftools_bgzip_merged_sv_vcf:
        run: ../tools/bgzip.cwl
        in:
            file: bcftools_merge_sv_vcfs/merged_sv_vcf
        out:
            [bgzipped_file]

    bcftools_annotsv_filter:
        run: ../tools/annotsv_filter.cwl
        in:
            annotsv_tsv: bcftools_annotate_variants/sv_variants_tsv
            filtering_frequency:
                default: "0.05"
            output_tsv_name:
                default: "bcftools-merged.filtered.AnnotSV.tsv"
        out:
            [filtered_tsv]
    bcftools_annotsv_filter_no_cds:
        run: ../tools/annotsv_filter.cwl
        in:
            annotsv_tsv: bcftools_annotate_variants/sv_variants_tsv
            filtering_frequency:
                default: "0.05"
            all_CDS:
                default: true
            output_tsv_name:
                default: "bcftools-merged.filtered-noCDS.AnnotSV.tsv"
        out:
            [filtered_tsv]
    survivor_annotsv_filter:
        run: ../tools/annotsv_filter.cwl
        in:
            annotsv_tsv: survivor_annotate_variants/sv_variants_tsv
            filtering_frequency:
                default: "0.05"
            output_tsv_name:
                default: "survivor-merged.filtered.AnnotSV.tsv"
        out:
            [filtered_tsv]
    survivor_annotsv_filter_no_cds:
        run: ../tools/annotsv_filter.cwl
        in:
            annotsv_tsv: survivor_annotate_variants/sv_variants_tsv
            filtering_frequency:
                default: "0.05"
            all_CDS:
                default: true
            output_tsv_name:
                default: "survivor-merged.filtered-noCDS.AnnotSV.tsv"
        out:
            [filtered_tsv]
