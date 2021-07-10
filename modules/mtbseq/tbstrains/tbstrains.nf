nextflow.enable.dsl = 2
// NOTE: To properly setup the gatk inside the docker image
// - Download the gatk-3.8.0 tar file from here https://console.cloud.google.com/storage/browser/gatk-software/package-archive/gatk;tab=objects?prefix=&forceOnObjectsSortingFiltering=false
// - tar -xvf GATK_TAR_FILE
// - gatk-register gatk_folder/gatk_jar


params.resultsDir = "${params.outdir}/tbstrains"
params.saveMode = 'copy'
params.shouldPublish = true

// TODO: Add the tbjoin workflow
process TBSTRAINS {
    tag "${genomeFileName}"
    publishDir params.resultsDir, mode: params.saveMode, enabled: params.shouldPublish

    input:
    tuple val(genomeFileName), path("Position_Tables/${genomeFileName}_${params.library_name}*.gatk_position_table.tab")
    path(gatk_jar)
    env USER

    output:
    path("${genomeFileName}/Classification/Strain_Classification.tab")

    script:

    """

    gatk-register ${gatk_jar}

    mkdir ${genomeFileName}
    MTBseq --step TBstrains
    mv  Classification ./${genomeFileName}/
    """

    stub:

    """
    mkdir ${genomeFileName}
    mkdir ${genomeFileName}/Classification
    touch ${genomeFileName}/Classification/Strain_Classification.tab
    echo "MTBseq --step TBstrains"
    """

}
