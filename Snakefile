###############################################################################
# BSEQCURE THERAPEUTICS
# Clinical Neuroblastoma Tumor-Only WES Pipeline
###############################################################################

import pandas as pd

###############################################################################
# Configuration
###############################################################################

configfile: "config/config.yaml"

###############################################################################
# Sample sheet
###############################################################################

samples = (
    pd.read_csv("config/samples.tsv", sep="\t")
      .set_index("sample_id")
)

SAMPLES = samples.index.tolist()

###############################################################################
# Helper functions
###############################################################################

def get_fastq_r1(wildcards):
    return samples.loc[wildcards.sample, "fq1"]


def get_fastq_r2(wildcards):
    return samples.loc[wildcards.sample, "fq2"]

###############################################################################
# Final target
###############################################################################

rule all:
    input:
        expand(
            "results/annotation/{sample}.vep.vcf.gz",
            sample=SAMPLES
        ),
        expand(
            "results/coverage/{sample}.HsMetrics.txt",
            sample=SAMPLES
        ),
        expand(
            "results/variants/{sample}.stats.txt",
            sample=SAMPLES
        )

###############################################################################
# Workflow modules
###############################################################################

include: "workflow/rules/common.smk"
include: "workflow/rules/alignment.smk"
include: "workflow/rules/markduplicates.smk"
include: "workflow/rules/bqsr.smk"
include: "workflow/rules/intervals.smk"
include: "workflow/rules/mutect2.smk"
include: "workflow/rules/orientation.smk"
include: "workflow/rules/contamination.smk"
include: "workflow/rules/filtering.smk"
include: "workflow/rules/normalization.smk"
include: "workflow/rules/variant_stats.smk"
include: "workflow/rules/coverage.smk"
include: "workflow/rules/annotation.smk"
