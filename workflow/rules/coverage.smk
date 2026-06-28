rule coverage_metrics:
    input:
        bam="results/bqsr/{sample}.recal.bam",
        bai="results/bqsr/{sample}.recal.bam.bai",
        reference=config["reference"]["fasta"],
        intervals=config["mutect2"]["intervals"]

    output:
        metrics="results/coverage/{sample}.HsMetrics.txt"

    log:
        "logs/coverage/{sample}.coverage.log"

    shell:
        r"""
        mkdir -p results/coverage
        mkdir -p logs/coverage

        gatk CollectHsMetrics \
            -I {input.bam} \
            -O {output.metrics} \
            -R {input.reference} \
            --BAIT_INTERVALS {input.intervals} \
            --TARGET_INTERVALS {input.intervals} \
            > {log} 2>&1
        """
