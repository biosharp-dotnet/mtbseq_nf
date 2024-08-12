include { RENAME_FILES } from '../../../modules/utils/rename_files.nf' addParams (params.RENAME_FILES)
include { TBFULL } from '../../../modules/mtbseq/tbfull.nf' addParams (params.TBFULL)

include { COHORT } from "./cohort_analysis.nf"

workflow NORMAL_MODE {

    take:
        reads_ch
        references_ch

    main:
        ch_versions = Channel.empty()
        ch_multiqc_files = Channel.empty()

        ch_genome_names = reads_ch.map{ it -> it[0].id}

        samples_tsv_file = reads_ch
                .map {it -> it[0].id}
                .collect()
                .flatten()
                .map { n -> "$n" + "\t" + "${params.library_name}" + "\n" }
                .collectFile(name: params.cohort_tsv, newLine: false, storeDir: "${params.outdir}", cache: false)

        RENAME_FILES(reads_ch)

        //NOTE: Requires atleast 5_CPU/16_MEM
        TBFULL(RENAME_FILES.out.collect(),
               params.user,
               references_ch)


        COHORT(ch_genome_names,
                        TBFULL.out.position_variants,
                        TBFULL.out.position_tables,
                        references_ch)


        ch_versions = ch_versions.mix(TBFULL.out.versions)
        ch_multiqc_files = ch_multiqc_files.mix(TBFULL.out.statistics)
                                .mix(TBFULL.out.classification)
                                .mix(COHORT.out.distance_matrix)
                                .mix(COHORT.out.groups)


    emit:
        versions       = ch_versions
        multiqc_files  = ch_multiqc_files.collect()


}
