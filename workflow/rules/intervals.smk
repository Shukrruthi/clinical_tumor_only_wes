###############################################################################
# BED -> IntervalList
###############################################################################

rule bed_to_intervallist:
    input:
        bed=config["capture"]["bed"],
        dict=config["reference"]["dict"]

    output:
        interval=config["mutect2"]["intervals"]

    log:
        "logs/reference/bed_to_intervallist.log"

    shell:
        r"""
        mkdir -p logs/reference

        gatk BedToIntervalList \
            -I {input.bed} \
            -SD {input.dict} \
            -O {output.interval} \
            > {log} 2>&1
        """
