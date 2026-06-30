# Clinical Tumor-Only Whole Exome Sequencing (WES) Pipeline for Neuroblastoma

A Snakemake-based bioinformatics workflow for processing paired-end Illumina tumor-only whole exome sequencing (WES) data from raw FASTQ files to annotated somatic variant calls.

Developed for **BSEQCURE Therapeutics**

This repository implements the computational workflow defined in the Clinical Tumor-Only WES Pipeline SOP for Neuroblastoma. Methodology, acceptance criteria, and the clinical interpretation framework are maintained in the SOP and referenced, not duplicated, here. See Limitations for scientific and operational limitations.

---

# Overview

This repository provides a standardized and reproducible workflow for preprocessing, alignment, somatic variant calling, quality assessment, and functional annotation of tumor-only WES data.

The automated workflow includes:

- Raw read quality assessment (FastQC, MultiQC)
- Adapter trimming and quality filtering (fastp)
- Read alignment (BWA-MEM)
- Duplicate marking (GATK MarkDuplicates)
- Base Quality Score Recalibration (BQSR)
- Somatic variant calling (GATK Mutect2)
- Read orientation modeling
- Contamination estimation
- Variant filtering and normalization
- Coverage assessment
- Functional annotation using Ensembl VEP

This pipeline is intended for research use and workflow standardization at BSEQCURE Therapeutics. It is not a certified diagnostic medical device.

---

# Repository Scope

The automated workflow ends at annotated VCF generation, together with hybrid-capture coverage metrics and variant statistics.

The following analyses are described in the SOP but are not automated by this repository. They are downstream, manually performed analytical procedures that use the pipeline's outputs as starting inputs:

- Copy Number Variation (CNV) analysis
- Microsatellite Instability (MSI) assessment
- Tumor Mutational Burden (TMB) calculation
- HRR gene review and Loss of Heterozygosity (LOH) assessment
- Mandatory neuroblastoma gene review
- Clinical variant prioritization and ACMG/AMP-style classification
- Structured clinical report generation

Full rationale for this scope boundary and the analytical limitations that apply to the automated portion of the workflow are documented in Limitations.

---

# Repository Structure

```text
clinical_wes/
├── Snakefile
├── preprocessing.sh
├── config/
│   └── config.yaml
├── workflow/
│   ├── envs/
│   └── rules/
├── example_data/
│   ├── example_input/
│   ├── expected_output/
│   ├── samples_example.tsv
│   └── README.md
└── raw_input/
```

---

# Workflow Summary

The pipeline runs in two sequential phases.

### Phase 1 - Preprocessing (`preprocessing.sh`)

Executed once per sample:

```
FastQC (raw)
        ↓
MultiQC (raw)
        ↓
fastp trimming
        ↓
config/samples.tsv generation
        ↓
FastQC (trimmed)
        ↓
MultiQC (combined)
```

### Phase 2 - Snakemake Workflow

Executed after preprocessing:

```
Capture interval preparation (bed_to_intervallist via GATK BedToIntervalList)
        ↓
Alignment (bwa_mem via BWA-MEM and samtools)
        ↓
Duplicate marking (markduplicates via GATK MarkDuplicates)
        ↓
Base Quality Score Recalibration (baserecalibrator and applybqsr via GATK)
        ↓
Somatic variant calling (mutect2 tumor-only via GATK Mutect2)
        ↓
Orientation-bias modeling (learn_orientation via GATK LearnReadOrientationModel)
        ↓
Contamination estimation (pileup_summaries and calculate_contamination via GATK)
        ↓
Variant filtering (filter_mutect_calls and pass_variants via GATK and bcftools)
        ↓
Normalization (normalize_variants via bcftools norm)
        ↓
Variant statistics (variant_stats via bcftools stats)
        ↓
Coverage metrics (coverage_metrics via GATK CollectHsMetrics)
        ↓
Functional annotation (annotate_variants via Ensembl VEP 116)
```

# Software Requirements

Exact dependency lists are defined in:

- `workflow/envs/clinical_wes_environment.yaml` (main toolchain)
- `workflow/envs/clinical_wes_vep.yaml` (Ensembl VEP, kept in an isolated environment)

A Linux environment (native or WSL) with Conda is required.

---

# Installation

## 1. Clone the repository

```bash
git clone https://github.com/bseqcure/clinical_wes.git
cd clinical_wes
```

## 2. Create Conda environments

```bash
conda env create -f workflow/envs/clinical_wes_environment.yaml
conda env create -f workflow/envs/clinical_wes_vep.yaml
```

## 3. Activate the main environment

```bash
conda activate clinical_wes_environment
```

---

# Preparing Reference Resources

Create the required directory structure:

```bash
mkdir -p resources/reference resources/targets resources/annotation/vep_cache tmp
```

Place all reference files at the paths specified in `config/config.yaml`. Index and dictionary files must be consistent with the reference FASTA.

Download and install the Ensembl VEP GRCh38 offline cache (version 116) into `resources/annotation/vep_cache/` as described in the Ensembl VEP documentation.

---

# Preparing Raw FASTQ Files

```bash
cp /data/NB001_R1.fastq.gz raw_input/
cp /data/NB001_R2.fastq.gz raw_input/
```

The current implementation of `preprocessing.sh` processes one sample per run. The sample name is derived automatically from the R1 filename. Do not place more than one paired sample in `raw_input/` when running preprocessing.

---

# Running Preprocessing

Inspect and, if necessary, adjust the quality thresholds in `preprocessing.sh`: `QUALITY` and `MIN_LENGTH`.

```bash
chmod +x preprocessing.sh
./preprocessing.sh
```

Inspect `reports/multiqc_report.html` before proceeding. Confirm that adapter contamination has been removed, read quality is maintained, and read retention is acceptable. If QC is unsatisfactory, adjust `QUALITY` and `MIN_LENGTH` and rerun.

---

# Running Snakemake

```bash
# Verify config paths
cat config/config.yaml

# Dry run
snakemake --dry-run

# Execute
snakemake --cores 8 2>&1 | tee snakemake_run.log
```

---

# Documentation Set

| Document | Purpose |
|----------|---------|
| README.md (this document) | Repository overview, installation, quick start |
| Clinical_Tumor_Only_WES_SOP | Methodology, acceptance criteria, clinical interpretation framework |
| Limitations | Scientific and operational limitations |

---

# License

For internal use at BSEQCURE Therapeutics. Distribution and use outside BSEQCURE Therapeutics requires written authorization.

---

**SOP reference:** Clinical Tumor-Only Whole Exome Sequencing (WES) Pipeline for Neuroblastoma, BSEQCURE Therapeutics.
