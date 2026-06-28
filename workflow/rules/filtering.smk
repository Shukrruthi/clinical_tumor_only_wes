rule filter_mutect_calls:
    input:
        reference=config["reference"]["fasta"],
        vcf="results/variants/{sample}.unfiltered.vcf.gz",
        contamination="results/variants/{sample}.contamination.table",
        orientation="results/variants/{sample}.read-orientation-model.tar.gz"

    output:
        vcf="results/variants/{sample}.filtered.vcf.gz"

    log:
        "logs/variants/{sample}.filtermutect.log"

    shell:
        r"""
        mkdir -p logs/variants

        gatk FilterMutectCalls \
            -R {input.reference} \
            -V {input.vcf} \
            --contamination-table {input.contamination} \
            --ob-priors {input.orientation} \
            -O {output.vcf} \
            > {log} 2>&1
        """


rule pass_variants:
    input:
        vcf="results/variants/{sample}.filtered.vcf.gz"

    output:
        vcf="results/variants/{sample}.PASS.vcf.gz",
        tbi="results/variants/{sample}.PASS.vcf.gz.tbi"

    log:
        "logs/variants/{sample}.pass.log"

    shell:
        r"""
        bcftools view \
            -f PASS \
            {input.vcf} \
            -Oz \
            -o {output.vcf} \
            > {log} 2>&1

        tabix -p vcf {output.vcf} \
            >> {log} 2>&1
        """
