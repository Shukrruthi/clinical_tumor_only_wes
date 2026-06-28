###############################################################################
# Base Quality Score Recalibration (BQSR) Module
###############################################################################

from pathlib import Path

# Dynamically derive the reference dictionary path from the FASTA filename
REFERENCE_FASTA = config["reference"]["fasta"]
REFERENCE_DICT = str(Path(REFERENCE_FASTA).with_suffix(".dict"))


rule baserecalibrator:
    input:
        bam="results/dedup/{sample}.marked.bam",
        bai="results/dedup/{sample}.marked.bam.bai",
        reference=REFERENCE_FASTA,
        fai=REFERENCE_FASTA + ".fai",
        dict=REFERENCE_DICT,
        dbsnp=config["known_sites"]["dbsnp"],
        mills=config["known_sites"]["mills"]
    output:
        "results/bqsr/{sample}.recal.table"
    log:
        "logs/bqsr/{sample}.baserecalibrator.log"
    benchmark:
        "benchmarks/bqsr/{sample}.baserecalibrator.txt"
    threads:
        config["threads"]["gatk"]
    params:
        java_xmx=config["java"]["xmx"]
    shell:
        r"""
        set -euo pipefail
        mkdir -p results/bqsr logs/bqsr
        gatk BaseRecalibrator \
            -R {input.reference} \
            -I {input.bam} \
            --known-sites {input.dbsnp} \
            --known-sites {input.mills} \
            -O {output} \
            > {log} 2>&1
        """

rule applybqsr:
    input:
        bam="results/dedup/{sample}.marked.bam",
        bai="results/dedup/{sample}.marked.bam.bai",
        reference=REFERENCE_FASTA,
        fai=REFERENCE_FASTA + ".fai",
        dict=REFERENCE_DICT,
        recal="results/bqsr/{sample}.recal.table"
    output:
        bam="results/bqsr/{sample}.recal.bam",
        bai="results/bqsr/{sample}.recal.bam.bai"
    log:
        "logs/bqsr/{sample}.applybqsr.log"
    benchmark:
        "benchmarks/bqsr/{sample}.applybqsr.txt"
    params:
        java_xmx=config["java"]["xmx"]
    threads:
        config["threads"]["gatk"]
    shell:
        r"""
        set -euo pipefail
        gatk ApplyBQSR \
            -R {input.reference} \
            -I {input.bam} \
            --bqsr-recal-file {input.recal} \
            --allow-missing-read-group true \
            -O {output.bam} \
            > {log} 2>&1

        samtools index {output.bam} >> {log} 2>&1
        """
