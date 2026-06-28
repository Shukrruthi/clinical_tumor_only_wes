rule normalize_variants:
    input:
        vcf="results/variants/{sample}.PASS.vcf.gz",
        tbi="results/variants/{sample}.PASS.vcf.gz.tbi",
        reference=config["reference"]["fasta"]

    output:
        vcf="results/variants/{sample}.normalized.vcf.gz",
        tbi="results/variants/{sample}.normalized.vcf.gz.tbi"

    log:
        "logs/variants/{sample}.normalize.log"

    shell:
        r"""
        mkdir -p logs/variants

        bcftools norm \
            -f {input.reference} \
            -m -both \
            {input.vcf} \
            -Oz \
            -o {output.vcf} \
            > {log} 2>&1

        tabix -p vcf {output.vcf} \
            >> {log} 2>&1
        """
