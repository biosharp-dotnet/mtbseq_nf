include { TBBWA } from '../../../modules/mtbseq/tbbwa.nf' addParams (params.TBBWA)
include { TBREFINE } from '../../../modules/mtbseq/tbrefine.nf' addParams (params.TBREFINE)
include { TBPILE } from '../../../modules/mtbseq/tbpile.nf' addParams (params.TBPILE)
include { TBLIST } from '../../../modules/mtbseq/tblist.nf' addParams (params.TBLIST)
include { TBVARIANTS } from '../../../modules/mtbseq/tbvariants.nf' addParams (params.TBVARIANTS)
include { TBSTATS } from '../../../modules/mtbseq/tbstats.nf' addParams (params.TBSTATS)
include { TBSTRAINS } from '../../../modules/mtbseq/tbstrains.nf' addParams (params.TBSTRAINS)

include { COHORT_ANALYSIS } from "./cohort_analysis.nf"

workflow SAMPLE_ANALYSIS {
    take:
        reads_ch
        references_ch

    main:
        TBBWA(reads_ch, params.user, references_ch)
        TBREFINE(TBBWA.out.bam_tuple, params.user, references_ch)
        TBPILE(TBREFINE.out.gatk_bam, params.user, references_ch)
        TBLIST(TBPILE.out.mpileup, params.user, references_ch)
        TBVARIANTS(TBLIST.out.position_table_tuple, params.user, references_ch)

    // NOTE: These are part of per-sample-analysis but they need the output from
    // all other processes to compute the metrics for the cohort.
        TBSTATS(TBBWA.out.bam.collect(),
                TBLIST.out.position_table.collect(),
                params.user,
                references_ch)

        TBSTRAINS(TBLIST.out.position_table.collect(),
                  params.user,
                  references_ch)

    emit:
        genome_names = reads_ch.map{ it -> it[0].id}
        position_variants = TBVARIANTS.out.tbjoin_input.collect()
        position_tables = TBLIST.out.tbjoin_input.collect()
        statistics = TBSTATS.out.statistics
        classification = TBSTRAINS.out.classification

}



workflow PARALLEL_ANALYSIS {
    take:
        reads_ch
        references_ch

    main:
        SAMPLE_ANALYSIS(reads_ch, references_ch)

        COHORT_ANALYSIS(SAMPLE_ANALYSIS.out.genome_names,
                        SAMPLE_ANALYSIS.out.position_variants,
                        SAMPLE_ANALYSIS.out.position_tables,
                        references_ch)

        ch_versions = Channel.empty().mix(COHORT_ANALYSIS.out.versions)
        ch_multiqc_files = Channel.empty().mix(SAMPLE_ANALYSIS.out.statistics)
        ch_multiqc_files.mix(SAMPLE_ANALYSIS.out.classification)
        ch_multiqc_files.mix(COHORT_ANALYSIS.out.distance_matrix)
        ch_multiqc_files.mix(COHORT_ANALYSIS.out.groups)

    emit:
        versions       = ch_versions
        multiqc_files  = ch_multiqc_files
}
