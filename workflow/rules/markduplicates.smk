###############################################################################
# Mark PCR duplicates
###############################################################################

rule markduplicates:
    input:
        bam="results/alignment/{sample}.sorted.bam"

    output:
        bam="results/dedup/{sample}.marked.bam",
        bai="results/dedup/{sample}.marked.bam.bai"

    params:
        metrics="metrics/{sample}.duplication_metrics.txt"

    threads:
        config["threads"]["gatk"]

    log:
        "logs/markduplicates/{sample}.markduplicates.log"

    benchmark:
        "benchmarks/markduplicates/{sample}.txt"

    shell:
        r"""
        set -euo pipefail
        mkdir -p results/dedup
        mkdir -p metrics
        mkdir -p logs/markduplicates

        gatk MarkDuplicates \
            -I {input.bam} \
            -O {output.bam} \
            -M {params.metrics} \
            --CREATE_INDEX false \
            > {log} 2>&1

        samtools index {output.bam} >> {log} 2>&1
        """
