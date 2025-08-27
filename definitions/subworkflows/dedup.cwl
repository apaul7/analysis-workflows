#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "umi dedup w/ umi_tools subworkflow"
requirements:
    - class: SubworkflowFeatureRequirement
    - class: SchemaDefRequirement
      types:
          - $import: ../types/labelled_file.yml
inputs:
    bam:
        type: File
        secondaryFiles: ${if (self.nameext === ".bam") {return self.basename + ".bai"} else {return self.basename + ".crai"}}
    umi_separator:
        type: string
    umi_source:
        type: string
    reference:
        type:
            - string
            - File
        secondaryFiles: [.fai, ^.dict]
    bait_intervals:
        type: File
    target_intervals:
        type: File
    omni_vcf:
        type: File
        secondaryFiles: [.tbi]
    picard_metric_accumulation_level:
        type: string
        default: ALL_READS
    qc_minimum_mapping_quality:
        type: int?
    qc_minimum_base_quality:
        type: int?
    per_base_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
    per_target_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
    summary_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
outputs:
    dedup_bam:
        type: File
        secondaryFiles: [^.bai]
        outputSource: index/indexed_bam
    stats_edit_distance:
        type: File
        outputSource: dedup/stats_edit_distance
    stats_per_umi:
        type: File
        outputSource: dedup/stats_per_umi
    stats_per_umi_per_position:
        type: File
        outputSource: dedup/stats_per_umi_per_position

    insert_size_metrics:
        type: File?
        outputSource: qc/insert_size_metrics
    insert_size_histogram:
        type: File?
        outputSource: qc/insert_size_histogram
    alignment_summary_metrics:
        type: File
        outputSource: qc/alignment_summary_metrics
    hs_metrics:
        type: File
        outputSource: qc/hs_metrics
    per_target_coverage_metrics:
        type: File[]
        outputSource: qc/per_target_coverage_metrics
    per_target_hs_metrics:
        type: File[]
        outputSource: qc/per_target_hs_metrics
    per_base_coverage_metrics:
        type: File[]
        outputSource: qc/per_base_coverage_metrics
    per_base_hs_metrics:
        type: File[]
        outputSource: qc/per_base_hs_metrics
    summary_hs_metrics:
        type: File[]
        outputSource: qc/summary_hs_metrics
    flagstats:
        type: File
        outputSource: qc/flagstats
    verify_bam_id_metrics:
        type: File
        outputSource: qc/verify_bam_id_metrics
    verify_bam_id_depth:
        type: File
        outputSource: qc/verify_bam_id_depth
steps:
    dedup:
        run: ../tools/dedup.cwl
        in:
            bam: bam
            umi_separator: umi_separator
            umi_source: umi_source
        out:
            [stats_edit_distance, stats_per_umi, stats_per_umi_per_position, dedup_bam]
    index:
        run: ../tools/index_bam.cwl
        in:
            bam: dedup/dedup_bam
        out:
            [indexed_bam]
    qc:
        run: ../subworkflows/qc_exome.cwl
        in:
            bam: index/indexed_bam
            reference: reference
            bait_intervals: bait_intervals
            target_intervals: target_intervals
            per_base_intervals: per_base_intervals
            per_target_intervals: per_target_intervals
            summary_intervals: summary_intervals
            omni_vcf: omni_vcf
            picard_metric_accumulation_level: picard_metric_accumulation_level
            minimum_mapping_quality: qc_minimum_mapping_quality
            minimum_base_quality: qc_minimum_base_quality
        out: [insert_size_metrics, insert_size_histogram, alignment_summary_metrics, hs_metrics, per_target_coverage_metrics, per_target_hs_metrics, per_base_coverage_metrics, per_base_hs_metrics, summary_hs_metrics, flagstats, verify_bam_id_metrics, verify_bam_id_depth]
