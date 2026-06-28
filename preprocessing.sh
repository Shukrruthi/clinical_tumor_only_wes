#!/bin/bash

###############################################################################
# Clinical Neuroblastoma WES
#
# STEP 1
# Raw QC
# Read trimming
# QC after trimming
###############################################################################

set -euo pipefail

###############################################################################
# USER SETTINGS
###############################################################################

THREADS=8

INPUT_DIR="raw_input/"

RESULTS_DIR="results"

REPORTS_DIR="reports"

##############################################################################
R1=$(ls raw_input/*_R1*.fastq.gz)
R2=$(ls raw_input/*_R2*.fastq.gz)

SAMPLE=$(basename "${R1}" | sed 's/_R1.*//')

###############################################################################
# FASTP PARAMETERS
#
# Inspect the initial FastQC/MultiQC report and modify these values accordingly.
#
# QUALITY
#   Mean Phred score threshold.
#
# MIN_LENGTH
#   Minimum read length retained after trimming.
#
###############################################################################

QUALITY=20

MIN_LENGTH=50

###############################################################################
# CREATE OUTPUT DIRECTORIES
###############################################################################

mkdir -p ${RESULTS_DIR}/trimmed

mkdir -p ${REPORTS_DIR}/raw_fastqc

mkdir -p ${REPORTS_DIR}/trimmed_fastqc

mkdir -p ${REPORTS_DIR}/fastp

###############################################################################
# RAW FASTQC
###############################################################################

fastqc \
${INPUT_DIR}/${SAMPLE}_R1.fastq.gz \
${INPUT_DIR}/${SAMPLE}_R2.fastq.gz \
--threads ${THREADS} \
--outdir ${REPORTS_DIR}/raw_fastqc

###############################################################################
# MULTIQC BEFORE TRIMMING
###############################################################################

multiqc \
${REPORTS_DIR}/raw_fastqc \
-o ${REPORTS_DIR}/raw_fastqc

###############################################################################
# TRIMMING
###############################################################################

fastp \
-i ${INPUT_DIR}/${SAMPLE}_R1.fastq.gz \
-I ${INPUT_DIR}/${SAMPLE}_R2.fastq.gz \
-o ${RESULTS_DIR}/trimmed/${SAMPLE}_R1.clean.fastq.gz \
-O ${RESULTS_DIR}/trimmed/${SAMPLE}_R2.clean.fastq.gz \
--detect_adapter_for_pe \
--trim_poly_g \
--cut_right \
--cut_mean_quality ${QUALITY} \
--length_required ${MIN_LENGTH} \
--thread ${THREADS} \
--html ${REPORTS_DIR}/fastp/${SAMPLE}.html \
--json ${REPORTS_DIR}/fastp/${SAMPLE}.json

###############################################################################
# CREATE SAMPLE SHEET FOR SNAKEMAKE
###############################################################################

cat > config/samples.tsv <<EOF
sample_id	fq1	fq2
${SAMPLE}	results/trimmed/${SAMPLE}_R1.clean.fastq.gz	results/trimmed/${SAMPLE}_R2.clean.fastq.gz
EOF

###############################################################################
# POST-TRIM FASTQC
###############################################################################

fastqc \
${RESULTS_DIR}/trimmed/${SAMPLE}_R1.clean.fastq.gz \
${RESULTS_DIR}/trimmed/${SAMPLE}_R2.clean.fastq.gz \
--threads ${THREADS} \
--outdir ${REPORTS_DIR}/trimmed_fastqc

###############################################################################
# FINAL MULTIQC
###############################################################################

multiqc \
${REPORTS_DIR}/raw_fastqc \
${REPORTS_DIR}/trimmed_fastqc \
${REPORTS_DIR}/fastp \
-o ${REPORTS_DIR}

echo
echo "=============================================="
echo "Preprocessing completed successfully."
echo
echo "Inspect reports/multiqc_report.html"
echo
echo "If QC is satisfactory proceed to Snakemake."
echo "=============================================="
