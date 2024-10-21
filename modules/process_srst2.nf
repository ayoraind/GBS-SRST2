process SRST2_SRST2 {
    tag "$meta"

    container 'biocontainers/srst2:0.2.0--py27_2'

    publishDir "${params.output_dir}/", mode:'copy'

    input:
    tuple val(meta), path(fastq_s), path(db)

    output:
    tuple val(meta), path("*_genes_*_results.txt")               , optional:true, emit: gene_results
    tuple val(meta), path("*_fullgenes_*_results.txt")           , optional:true, emit: fullgene_results
    tuple val(meta), path("*_mlst_*_results.txt")                , optional:true, emit: mlst_results
    tuple val(meta), path("*.pileup")                            ,                emit: pileup
    tuple val(meta), path("*.sorted.bam")                        ,                emit: sorted_bam
    path "versions.yml"                                          ,                emit: versions

    
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reads = meta.single_end ? "--input_se ${fastq_s}" : "--input_pe ${fastq_s[0]} ${fastq_s[1]}"
    def database
    if (meta.db=="gene") {
        database = "--gene_db ${db}"
    } else if (meta.db=="mlst") {
        database = "--mlst_db ${db}"
    } else {
        error "Please set meta.db to either \"gene\" or \"mlst\""
    }


    """
    srst2 \\
        ${reads} \\
        --threads $task.cpus \\
        --output ${prefix} \\
        ${database} \\
        $args
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        srst2: \$(echo \$(srst2 --version 2>&1) | sed 's/srst2 //' ))
    END_VERSIONS
    """
}
