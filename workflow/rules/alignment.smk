###############################################################################
# Alignment using BWA-MEM
###############################################################################

SAMTOOLS_SORT_THREADS = config["threads"]["samtools"]

rule bwa_mem:
    input:
        r1="results/trimmed/{sample}_R1.clean.fastq.gz",
        r2="results/trimmed/{sample}_R2.clean.fastq.gz",
        ref=config["reference"]["fasta"]

    output:
        "results/alignment/{sample}.sorted.bam",
        "results/alignment/{sample}.sorted.bam.bai"

    log:
        "logs/alignment/{sample}.bwa.log"

    threads:
        config["threads"]["bwa"]

    params:
        sort_threads=SAMTOOLS_SORT_THREADS

    shell:
        r"""
        set -euo pipefail
        mkdir -p results/alignment
        mkdir -p logs/alignment

        (
            bwa mem \
                -t {threads} \
                -R '@RG\tID:{wildcards.sample}\tSM:{wildcards.sample}\tPL:ILLUMINA' \
                {input.ref} \
                {input.r1} \
                {input.r2} \
            | samtools sort \
                -@ {params.sort_threads} \
                -o {output[0]}
        ) > {log} 2>&1

        samtools index {output[0]}
        """
