rule annotate_variants:
    input:
        vcf="results/variants/{sample}.normalized.vcf.gz",
        tbi="results/variants/{sample}.normalized.vcf.gz.tbi",
        reference=config["reference"]["fasta"]

    output:
        vcf="results/annotation/{sample}.vep.vcf.gz",
        tbi="results/annotation/{sample}.vep.vcf.gz.tbi"

    log:
        "logs/annotation/{sample}.vep.log"

    threads: 8

    shell:
        r"""
        set -euo pipefail
        eval "$(conda shell.bash hook)"
        conda activate clinical_wes_vep

        mkdir -p results/annotation
        mkdir -p logs/annotation

        vep \
            --cache \
            --offline \
            --dir_cache resources/annotation/vep_cache \
            --species homo_sapiens \
            --assembly GRCh38 \
            --fasta {input.reference} \
            --fork {threads} \
            --vcf \
            --everything \
            --compress_output bgzip \
            --force_overwrite \
            --input_file {input.vcf} \
            --output_file {output.vcf} \
            > {log} 2>&1

        tabix -p vcf {output.vcf}
        """
