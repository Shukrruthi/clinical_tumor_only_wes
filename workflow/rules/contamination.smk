rule pileup_summaries:
    input:
        bam="results/bqsr/{sample}.recal.bam",
        bai="results/bqsr/{sample}.recal.bam.bai",
        intervals=config["mutect2"]["intervals"],
        germline=config["mutect2"]["germline_resource"]

    output:
        table="results/variants/{sample}.pileups.table"

    log:
        "logs/variants/{sample}.pileups.log"

    shell:
        r"""
        mkdir -p logs/variants

        gatk GetPileupSummaries \
            -I {input.bam} \
            -V {input.germline} \
            -L {input.intervals} \
            -O {output.table} \
            > {log} 2>&1
        """


rule calculate_contamination:
    input:
        table="results/variants/{sample}.pileups.table"

    output:
        contamination="results/variants/{sample}.contamination.table"

    log:
        "logs/variants/{sample}.contamination.log"

    shell:
        r"""
        gatk CalculateContamination \
            -I {input.table} \
            -O {output.contamination} \
            > {log} 2>&1
        """
