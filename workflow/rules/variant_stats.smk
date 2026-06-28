rule variant_stats:
    input:
        vcf="results/variants/{sample}.normalized.vcf.gz",
        tbi="results/variants/{sample}.normalized.vcf.gz.tbi"

    output:
        stats="results/variants/{sample}.stats.txt"

    log:
        "logs/variants/{sample}.stats.log"

    shell:
        r"""
        mkdir -p logs/variants

        bcftools stats \
            {input.vcf} \
            > {output.stats} \
            2> {log}
        """
