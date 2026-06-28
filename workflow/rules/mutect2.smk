rule mutect2:
    input:
        bam="results/bqsr/{sample}.recal.bam",
        bai="results/bqsr/{sample}.recal.bam.bai",
        reference=config["reference"]["fasta"],
        intervals=config["mutect2"]["intervals"],
        pon=config["mutect2"]["pon"],
        germline=config["mutect2"]["germline_resource"]

    output:
        vcf="results/variants/{sample}.unfiltered.vcf.gz",
        tbi="results/variants/{sample}.unfiltered.vcf.gz.tbi",
        f1r2="results/variants/{sample}.f1r2.tar.gz"

    log:
        "logs/mutect2/{sample}.mutect2.log"

    benchmark:
        "benchmarks/mutect2/{sample}.txt"

    threads:
        config["threads"]["gatk"]

    shell:
        r"""
        mkdir -p results/variants
        mkdir -p logs/mutect2
        mkdir -p benchmarks/mutect2

        gatk --java-options "-Xmx{config[java][xmx]}" Mutect2 \
            -R {input.reference} \
            -I {input.bam} \
            -L {input.intervals} \
            --germline-resource {input.germline} \
            --panel-of-normals {input.pon} \
            --f1r2-tar-gz {output.f1r2} \
            -O {output.vcf} \
            > {log} 2>&1
        """
