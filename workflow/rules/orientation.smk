rule learn_orientation:
    input:
        f1r2="results/variants/{sample}.f1r2.tar.gz"

    output:
        model="results/variants/{sample}.read-orientation-model.tar.gz"

    log:
        "logs/variants/{sample}.orientation.log"

    shell:
        r"""
        mkdir -p logs/variants

        gatk LearnReadOrientationModel \
            -I {input.f1r2} \
            -O {output.model} \
            > {log} 2>&1
        """
