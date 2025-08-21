#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: "targeted alignment and low vaf variant detection"
requirements:
    - class: SchemaDefRequirement
      types:
          - $import: ../types/labelled_file.yml
          - $import: ../types/sequence_data.yml
          - $import: ../types/trimming_options.yml
          - $import: ../types/vep_custom_annotation.yml
    - class: SubworkflowFeatureRequirement
inputs:
    reference:
        type:
            - string
            - File
        secondaryFiles: [.fai, ^.dict, .amb, .ann, .bwt, .pac, .sa]
    sequence:
        type: ../types/sequence_data.yml#sequence_data[]
        label: "sequence: sequencing data and readgroup information"
        doc: |
          sequence represents the sequencing data as either FASTQs or BAMs with accompanying
          readgroup information. Note that in the @RG field ID and SM are required.
    trimming:
        type:
            - ../types/trimming_options.yml#trimming_options
            - "null"
    bqsr_known_sites:
        type: File[]
        secondaryFiles: [.tbi]
        doc: "One or more databases of known polymorphic sites used to exclude regions around known polymorphisms from analysis."
    bqsr_intervals:
        type: string[]?
    bait_intervals:
        type: File
    target_intervals:
        type: File
        label: "target_intervals: interval_list file of targets used in the sequencing experiment"
        doc: |
            target_intervals is an interval_list corresponding to the targets for the capture reagent.
            Bed files with this information can be converted to interval_lists with Picard BedToIntervalList.
            In general for a WES exome reagent bait_intervals and target_intervals are the same.
    target_interval_padding:
        type: int
        label: "target_interval_padding: number of bp flanking each target region in which to allow variant calls"
        doc: |
            The effective coverage of capture products generally extends out beyond the actual regions
            targeted. This parameter allows variants to be called in these wingspan regions, extending
            this many base pairs from each side of the target regions.
        default: 100
    per_base_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
    per_target_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
    summary_intervals:
        type: ../types/labelled_file.yml#labelled_file[]
    omni_vcf:
        type: File
        secondaryFiles: [.tbi]
    picard_metric_accumulation_level:
        type: string
    varscan_strand_filter:
        type: int?
        default: 0
    varscan_min_coverage:
        type: int?
        default: 8
    varscan_min_var_freq:
        type: float?
        default: 0.01
    varscan_p_value:
        type: float?
        default: 0.90
    varscan_min_reads:
        type: int?
        default: 2
    maximum_population_allele_frequency:
        type: float?
        default: 0.001
    vep_cache_dir:
        type:
            - string
            - Directory
    vep_ensembl_assembly:
        type: string
        doc: "genome assembly to use in vep. Examples: GRCh38 or GRCm38"
    vep_ensembl_version:
        type: string
        doc: "ensembl version - Must be present in the cache directory. Example: 95"
    vep_ensembl_species:
        type: string
        doc: "ensembl species - Must be present in the cache directory. Examples: homo_sapiens or mus_musculus"
    synonyms_file:
        type: File?
    annotate_coding_only:
        type: boolean?
        default: true
    vep_pick:
        type:
            - "null"
            - type: enum
              symbols: ["pick", "flag_pick", "pick_allele", "per_gene", "pick_allele_gene", "flag_pick_allele", "flag_pick_allele_gene"]
    variants_to_table_fields:
        type: string[]?
        default: [CHROM,POS,REF,ALT,set]
    variants_to_table_genotype_fields:
        type: string[]?
        default: [GT,AD,AF,DP]
    vep_to_table_fields:
        type: string[]?
        default: [Consequence,SYMBOL,Feature_type,Feature,HGVSc,HGVSp,cDNA_position,CDS_position,Protein_position,Amino_acids,Codons,HGNC_ID,Existing_variation,gnomADe_AF,CLIN_SIG,SOMATIC,PHENO]
    sample_name:
        type: string
    docm_vcf:
        type: File
        secondaryFiles: [.tbi]
    vep_custom_annotations:
        type: ../types/vep_custom_annotation.yml#vep_custom_annotation[]
        doc: "custom type, check types directory for input format"
    qc_minimum_mapping_quality:
        type: int?
    qc_minimum_base_quality:
        type: int?
    readcount_minimum_mapping_quality:
        type: int?
    readcount_minimum_base_quality:
        type: int?
    read_umi_separator:
        type: string
        default: ":"
    read_umi_source:
        type: string
        default: "read_id"

outputs:
    cram:
        type: File
        outputSource: index_cram/indexed_cram
    dedup_cram:
       type: File
       outputSource: dedup_index_cram/indexed_cram
    dedup_stats_edit_distance:
        type: File
        outputSource: dedup/stats_edit_distance
    dedup_stats_per_umi:
        type: File
        outputSource: dedup/stats_per_umi
    dedup_stats_per_umi_per_position:
        type: File
        outputSource: dedup/stats_per_umi_per_position
    mark_duplicates_metrics:
        type: File
        outputSource: alignment_and_qc/mark_duplicates_metrics

    qc_dir:
        type: Directory
        outputSource: gather_qc/gathered_directory
    dedup_qc_dir:
        type: Directory
        outputSource: gather_dedup_qc/gathered_directory
    variants:
        type: Directory
        outputSource: gather_detect_variants/gathered_directory
    dedup_variants:
        type: Directory
        outputSource: gather_dedup_detect_variants/gathered_directory

steps:
    alignment_and_qc:
        run: alignment_exome.cwl
        in:
            reference: reference
            sequence: sequence
            trimming: trimming
            bqsr_known_sites: bqsr_known_sites
            bqsr_intervals: bqsr_intervals
            bait_intervals: bait_intervals
            target_intervals: target_intervals
            per_base_intervals: per_base_intervals
            per_target_intervals: per_target_intervals
            summary_intervals: summary_intervals
            omni_vcf: omni_vcf
            picard_metric_accumulation_level: picard_metric_accumulation_level   
            qc_minimum_mapping_quality: qc_minimum_mapping_quality
            qc_minimum_base_quality: qc_minimum_base_quality
        out:
            [bam, mark_duplicates_metrics, insert_size_metrics, insert_size_histogram, alignment_summary_metrics, hs_metrics, per_target_coverage_metrics, per_target_hs_metrics, per_base_coverage_metrics, per_base_hs_metrics, summary_hs_metrics, flagstats, verify_bam_id_metrics, verify_bam_id_depth]
    pad_target_intervals:
        run: ../tools/interval_list_expand.cwl
        in: 
            interval_list: target_intervals
            roi_padding: target_interval_padding
        out:
            [expanded_interval_list]
    dedup:
        run: ../subworkflows/dedup.cwl
        in:
            bam: alignment_and_qc/bam
            umi_separator: read_umi_separator
            umi_source: read_umi_source
            reference: reference
            bait_intervals: bait_intervals
            target_intervals: target_intervals
            omni_vcf: omni_vcf
            picard_metric_accumulation_level: picard_metric_accumulation_level
            qc_minimum_mapping_quality: qc_minimum_mapping_quality
            qc_minimum_base_quality: qc_minimum_base_quality
            per_base_intervals: per_base_intervals
            per_target_intervals: per_target_intervals
            summary_intervals: summary_intervals
        out: [stats_per_umi_per_position, stats_per_umi, stats_edit_distance, dedup_bam, insert_size_metrics, insert_size_histogram, alignment_summary_metrics, hs_metrics, per_target_coverage_metrics, per_target_hs_metrics, per_base_coverage_metrics, per_base_hs_metrics, summary_hs_metrics, flagstats, verify_bam_id_metrics, verify_bam_id_depth]
    detect_variants:
        run: low_vaf_detect_variants.cwl
        in:
            reference: reference
            bam: alignment_and_qc/bam
            roi_intervals: pad_target_intervals/expanded_interval_list
            varscan_strand_filter: varscan_strand_filter
            varscan_min_coverage: varscan_min_coverage
            varscan_min_var_freq: varscan_min_var_freq
            varscan_p_value: varscan_p_value
            varscan_min_reads: varscan_min_reads
            maximum_population_allele_frequency: maximum_population_allele_frequency
            vep_cache_dir: vep_cache_dir
            vep_ensembl_assembly: vep_ensembl_assembly
            vep_ensembl_version: vep_ensembl_version
            vep_ensembl_species: vep_ensembl_species
            synonyms_file: synonyms_file
            vep_pick: vep_pick
            variants_to_table_fields: variants_to_table_fields
            variants_to_table_genotype_fields: variants_to_table_genotype_fields
            vep_to_table_fields: vep_to_table_fields
            sample_name: sample_name
            docm_vcf: docm_vcf
            vep_custom_annotations: vep_custom_annotations
            readcount_minimum_mapping_quality: readcount_minimum_mapping_quality
            readcount_minimum_base_quality: readcount_minimum_base_quality
        out:
            [mutect_vcf, varscan_vcf, docm_gatk_vcf, deepsomatic_vcf, deepsomatic_raw_vcf, deepsomatic_gvcf, annotated_vcf, final_vcf, final_tsv, vep_summary, tumor_snv_bam_readcount_tsv, tumor_indel_bam_readcount_tsv]
    dedup_detect_variants:
        run: low_vaf_detect_variants.cwl
        in:
            reference: reference
            bam: dedup/dedup_bam
            roi_intervals: pad_target_intervals/expanded_interval_list
            varscan_strand_filter: varscan_strand_filter
            varscan_min_coverage: varscan_min_coverage
            varscan_min_var_freq: varscan_min_var_freq
            varscan_p_value: varscan_p_value
            varscan_min_reads: varscan_min_reads
            maximum_population_allele_frequency: maximum_population_allele_frequency
            vep_cache_dir: vep_cache_dir
            vep_ensembl_assembly: vep_ensembl_assembly
            vep_ensembl_version: vep_ensembl_version
            vep_ensembl_species: vep_ensembl_species
            synonyms_file: synonyms_file
            vep_pick: vep_pick
            variants_to_table_fields: variants_to_table_fields
            variants_to_table_genotype_fields: variants_to_table_genotype_fields
            vep_to_table_fields: vep_to_table_fields
            sample_name: sample_name
            docm_vcf: docm_vcf
            vep_custom_annotations: vep_custom_annotations
            readcount_minimum_mapping_quality: readcount_minimum_mapping_quality
            readcount_minimum_base_quality: readcount_minimum_base_quality
        out:
            [mutect_vcf, varscan_vcf, docm_gatk_vcf, deepsomatic_vcf, deepsomatic_raw_vcf, deepsomatic_gvcf, annotated_vcf, final_vcf, final_tsv, vep_summary, tumor_snv_bam_readcount_tsv, tumor_indel_bam_readcount_tsv]
    gather_qc:
        run: ../tools/gather_to_sub_directory.cwl
        in:
            outdir:
                default: "qc"
            files:
                source: [alignment_and_qc/insert_size_metrics, alignment_and_qc/insert_size_histogram, alignment_and_qc/alignment_summary_metrics, alignment_and_qc/flagstats, alignment_and_qc/verify_bam_id_metrics, alignment_and_qc/verify_bam_id_depth]
                linkMerge: merge_flattened
            files_files:
                source: [alignment_and_qc/per_target_coverage_metrics, alignment_and_qc/per_target_hs_metrics, alignment_and_qc/per_base_coverage_metrics, alignment_and_qc/per_base_hs_metrics, alignment_and_qc/summary_hs_metrics]
        out:
            [gathered_directory]
    gather_dedup_qc:
        run: ../tools/gather_to_sub_directory.cwl
        in:
            outdir:
                default: "dedup_qc"
            files:
                source: [dedup/insert_size_metrics, dedup/insert_size_histogram, dedup/alignment_summary_metrics, dedup/flagstats, dedup/verify_bam_id_metrics, dedup/verify_bam_id_depth]
                linkMerge: merge_flattened
            files_files:
                source: [dedup/per_target_coverage_metrics, dedup/per_target_hs_metrics, dedup/per_base_coverage_metrics, dedup/per_base_hs_metrics, dedup/summary_hs_metrics]
        out:
            [gathered_directory]
    gather_dedup_detect_variants:
        run: ../tools/gather_to_sub_directory.cwl
        in:
            outdir:
                default: "dedup_detect_variants"
            files:
                source: [dedup_detect_variants/mutect_vcf, dedup_detect_variants/varscan_vcf, dedup_detect_variants/docm_gatk_vcf, dedup_detect_variants/deepsomatic_vcf, dedup_detect_variants/deepsomatic_raw_vcf, dedup_detect_variants/deepsomatic_gvcf, dedup_detect_variants/annotated_vcf, dedup_detect_variants/final_vcf, dedup_detect_variants/final_tsv, dedup_detect_variants/vep_summary, dedup_detect_variants/tumor_snv_bam_readcount_tsv, dedup_detect_variants/tumor_indel_bam_readcount_tsv]
                linkMerge: merge_flattened
        out:
            [gathered_directory]
    gather_detect_variants:
        run: ../tools/gather_to_sub_directory.cwl
        in:
            outdir:
                default: "detect_variants"
            files:
                source: [detect_variants/mutect_vcf, detect_variants/varscan_vcf, detect_variants/docm_gatk_vcf, detect_variants/deepsomatic_vcf, detect_variants/deepsomatic_raw_vcf, detect_variants/deepsomatic_gvcf, detect_variants/annotated_vcf, detect_variants/final_vcf, detect_variants/final_tsv, detect_variants/vep_summary, detect_variants/tumor_snv_bam_readcount_tsv, detect_variants/tumor_indel_bam_readcount_tsv]
                linkMerge: merge_flattened
        out:
            [gathered_directory]
    bam_to_cram:
        run: ../tools/bam_to_cram.cwl
        in:
            bam: alignment_and_qc/bam
            reference: reference
        out:
            [cram]
    index_cram:
         run: ../tools/index_cram.cwl
         in:
            cram: bam_to_cram/cram
         out:
            [indexed_cram]
    dedup_bam_to_cram:
        run: ../tools/bam_to_cram.cwl
        in:
            bam: dedup/dedup_bam
            reference: reference
        out:
            [cram]
    dedup_index_cram:
         run: ../tools/index_cram.cwl
         in:
            cram: dedup_bam_to_cram/cram
         out:
            [indexed_cram]
