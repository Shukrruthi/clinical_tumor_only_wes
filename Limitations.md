# BSEQCURE THERAPEUTICS
## Limitations: Clinical Tumor-Only Whole Exome Sequencing (WES) Pipeline for Neuroblastoma

* **Prepared by:** Shukrruthi K Iyengar
* **Document type:** Scientific and Operational Limitations Statement
* **Applies to:** `preprocessing.sh`, `Snakefile`, and all rule modules in `workflow/rules/`

---

## 1. Purpose and Scope
This document enumerates the scientific, technical, and procedural limitations of the `clinical_wes` pipeline as implemented, comprising `preprocessing.sh` and the Snakemake workflow defined across the `Snakefile`. It is intended to be read alongside, not in place of, the SOP's own discussion of acceptance criteria (SOP section 11), tumor purity (SOP section 4.3), and biomarker scope (SOP section 9), and is intended for inclusion, by reference, in the "Limitations" section of any clinical report generated using this pipeline's outputs (SOP section 10).

Where a limitation arises from the inherent nature of tumor-only short-read WES, it is described here as a **methodological limitation**. Where it arises specifically from the current state of automation in this repository, it is described as an **implementation limitation**. Only limitations that genuinely apply to the current implementation are included.

## 2. Tumor-Only Analysis Limitations
The pipeline performs somatic variant calling without a matched constitutional (germline) normal sample, using GATK Mutect2 in tumor-only mode (rule `mutect2`). In the absence of a patient-matched normal, somatic status cannot be established by direct subtraction of a normal sample's genotype; the workflow instead relies on statistical filtering against a Panel of Normals (PON) and a population germline-frequency resource (gnomAD), as described in SOP section 7.1. This is a well-established practice for tumor-only WES, but it is inherently less specific than matched tumor-normal calling, and the distinction between true somatic variants, rare inherited polymorphisms, and clonal hematopoiesis-associated variants (in samples with hematologic admixture) cannot be made directly from sequencing data alone.

Two consequences follow directly:
1. **Somatic calls remain subject to residual germline contamination**, discussed in Section 5.
2. **Sensitivity for low allele-fraction somatic variants is reduced** relative to a matched-normal design because supporting evidence from a true patient-matched normal is unavailable. This compounds with the tumor-purity effects described in Section 7.

## 3. Dependence on the Panel of Normals (PON)
The `mutect2` rule supplies a PON to GATK Mutect2 via `--panel-of-normals`, configured at `config["mutect2"]["pon"]` (`resources/reference/1000g_pon.hg38.vcf.gz`). The PON's role is to suppress recurrent technical artifacts that are not patient-specific; its effectiveness is bounded by its composition, sequencing platform, and capture chemistry. A PON constructed from runs, platforms, or capture designs that differ from the validated production assay (Illumina paired-end WES, Agilent SureSelectXT Human All Exon V8) may incompletely suppress assay-specific artifacts or may suppress true somatic variants that coincide with PON-represented positions.

The pipeline does not validate PON suitability, composition, or vintage at any stage; this verification is an analyst and laboratory director's responsibility per SOP section 5 (mandatory pre-analysis verification) and SOP section 14 (deviation management).

## 4. Dependence on Population Allele-Frequency Databases
The gnomAD germline resource (`config["mutect2"]["germline_resource"]`, `resources/reference/af-only-gnomad.hg38.vcf.gz`) is used both by `mutect2` (`--germline-resource`) and by `pileup_summaries` (feeding `calculate_contamination`). Population allele-frequency databases of this kind are assembled predominantly from adult cohorts with uneven ancestral representation; because neuroblastoma is a pediatric malignancy, rare germline variants segregating in pediatric or population-specific contexts may be underrepresented. gnomAD allele frequencies also reflect the database version used at the time of resource preparation rather than the most current release at the time of analysis. 

Variants underrepresented in gnomAD for ancestry- or pediatric-cohort-related reasons may be incorrectly retained as candidate somatic variants when they are, in fact, rare germline polymorphisms, and this same underrepresentation can affect the precision of the contamination estimate produced by `calculate_contamination`.

## 5. Potential Germline Contamination of Somatic Calls
As a direct consequence of Sections 2-4, variants surviving `filter_mutect_calls` and `pass_variants` (`results/variants/{sample}.PASS.vcf.gz`) and the normalized derivative `results/variants/{sample}.normalized.vcf.gz` may contain residual germline variants not fully suppressed by PON- and gnomAD-based filtering. This is an expected and well-characterized property of tumor-only somatic calling rather than a defect unique to this implementation, but it is of particular clinical relevance to the genes named in the SOP's Mandatory Neuroblastoma Gene Review (SOP section 8.2): 

* **Primary drivers:** `ALK`, `TP53`, `ATRX`
* **Mismatch-repair genes:** `MLH1`, `MSH2`, `MSH6`, `PMS2`
* **HRR-pathway genes:** `BRCA1`, `BRCA2`, `ATM`, `PALB2`, `RAD51`, `CHEK1`, `CHEK2`

A variant of true germline origin-for example, a rare inherited cancer-predisposition allele-could be retained through tumor-only filtering and superficially resemble a somatic finding. Establishing true somatic status for any clinically actionable variant requires orthogonal evidence (Section 20) outside the scope of this computational workflow.

## 6. Limitations of Short-Read Whole Exome Sequencing
The workflow uses short-read (Illumina paired-end) sequencing aligned with BWA-MEM (rule `bwa_mem`) and captures only the genomic territory defined by the validated capture design (`config["capture"]["bed"]`, `resources/targets/[relevant company capture].bed`; Agilent SureSelectXT Human All Exon V8). This carries well-established technical limitations independent of any pipeline-specific implementation detail:

* Reduced sensitivity for structural rearrangements, large insertions/deletions, and complex genomic rearrangements relative to long-read or whole-genome approaches; no structural-variant caller is implemented in this workflow.
* Reduced mapping confidence and variant-calling sensitivity in repetitive, low-complexity, homopolymer, or paralogous genomic regions.
* Variants outside the captured territory-including most non-coding regulatory regions and deep intronic sequences-are not assessed.
* Coverage uniformity across the capture territory is inherently variable due to GC-content bias, probe efficiency variation, and hybridization kinetics inherent to exome capture chemistry.

These are general properties of the assay and analytical approach, consistent with the SOP's framing of the validated assay as targeting "Somatic SNV/INDEL detection" (SOP section 1), rather than defects specific to this implementation, but they bound the scope of variants that this pipeline can detect regardless of correct execution.

## 7. Tumor Purity Effects
SOP section 4.3 specifies a recommended minimum tumor cellularity of ≥30% (preferred ≥50%) and notes that lower purity reduces sensitivity for low-VAF somatic variants, CNV detection, and TMB estimation. No rule in the implemented workflow estimates, reports, or adjusts variant-calling behavior based on tumor purity; purity assessment is a pathology/histology input that occurs upstream of, and independently from, this pipeline, and the Mutect2 invocation and filtering thresholds are applied uniformly regardless of specimen purity. 

Consequently, in low-purity specimens, the absence of a clinically relevant variant in `results/annotation/{sample}.vep.vcf.gz` cannot be interpreted as a true negative without explicit consideration of purity, and negative findings from low-purity samples should be interpreted with caution rather than treated as a high-confidence absence of pathogenic variants (SOP section 4.3).

## 8. Coverage Limitations
The `coverage_metrics` rule (GATK CollectHsMetrics, run against the same interval list used for variant calling, `config["mutect2"]["intervals"]`) produces `results/coverage/{sample}.HsMetrics.txt`, containing the data needed to evaluate the SOP section 4.4 and section 11 coverage acceptance criteria. The workflow does not programmatically compare these values against the SOP's thresholds, nor does it halt, flag, or branch execution if a sample's coverage falls below the minimum acceptance criteria; evaluation of `HsMetrics.txt` against these thresholds is a manual analyst step.

Regions of low or uneven coverage-whether due to GC bias, capture probe inefficiency, or specimen quality (e.g., degraded FFPE-derived DNA)-directly reduce variant-calling sensitivity in the affected regions, independent of any other pipeline parameter, and this cannot be fully mitigated by downstream filtering or annotation steps.

## 9. Need for Downstream Variant Filtering Beyond PASS Status
The `pass_variants` rule applies a single filtering operation, `bcftools view -f PASS`, retaining only variants flagged PASS by FilterMutectCalls. SOP section 7.2 describes a broader project-specific filtering step intended to additionally apply a depth threshold, a variant allele frequency (VAF) threshold, population-frequency filtering, and generic quality filtering, with thresholds to be "predefined and documented." 

None of these four additional criteria are implemented as automated, configurable thresholds in `config.yaml` or in any rule. Consequently, `results/variants/{sample}.PASS.vcf.gz`, its normalized derivative, and the final annotated VCF may retain PASS-flagged variants that a fully implemented project-specific filtering policy would exclude. Application of these SOP-defined filtering criteria is, at present, a downstream manual analytical step.

## 10. Need for Interpretation of Annotation Content
The `annotate_variants` rule invokes Ensembl VEP (version 116) utilizing the comprehensive `--everything` flag against the local offline cache. While this successfully automates the capture of gene symbols, HGVS nomenclature, and basic cache-derived allele frequencies, the workflow still lacks dedicated `--plugin` or `--custom` hooks for ClinVar significance, high-resolution multi-ancestry gnomAD reference VCFs, or explicit `--mane` transcript prioritization flags. 

Cross-referencing ClinVar and frequency databases and selecting a MANE Select transcript for reporting are presently manual steps performed by the analyst on the VEP output. Functional annotation does not itself constitute clinical interpretation, and the pipeline does not integrate literature evidence or context-dependent biological reasoning (SOP section 8.1).

## 11. No Automated Clinical Variant Prioritization
SOP section 8.1 defines a clinical prioritization scheme giving priority to missense, frameshift, nonsense, and splice variants, and to HIGH/MODERATE impact consequences, integrating gene function, population frequency, literature evidence, and clinical databases. No rule, script, or configuration in the repository implements this logic, and no automated tiering or clinical-actionability assessment is performed. The terminal automated output is the annotated VCF; all clinical prioritization is a downstream manual analytical procedure performed by qualified personnel.

## 12. No Automated ACMG/AMP Classification
No tool, rule, or script implementing ACMG/AMP germline classification criteria, or an equivalent somatic variant tiering framework, is present anywhere in the `Snakefile` or `workflow/rules/`. Where used by the laboratory, such classification is performed entirely as a manual downstream process by qualified personnel using the annotated filtered VCF as a starting input.

## 13. No Copy Number Variation (CNV) Automation
SOP section 9.1 specifies CNVkit and mandates review of *MYCN* amplification, 1p deletion, 11q deletion, 17q gain, and broader Segmental Chromosomal Alterations (SCAs). CNV analysis, including the SOP-mandated neuroblastoma-specific copy-number review, is entirely outside the automated workflow and must be performed as a separate manual downstream procedure.

## 14. No Microsatellite Instability (MSI) Automation
SOP section 9.2 specifies MSIsensor2 with defined interpretive thresholds (MSS, MSI-Low, MSI-High). MSI status is not automated and must be determined through a separate manual downstream procedure.

## 15. No Tumor Mutational Burden (TMB) Automation
SOP section 9.3 defines TMB as the count of coding, non-synonymous, PASS-filtered variants divided by the validated callable territory in megabases. The `variant_stats` rule (`bcftools stats` against `results/variants/{sample}.normalized.vcf.gz`) produces general variant-count statistics in `results/variants/{sample}.stats.txt`, but it does not restrict its counts to coding, non-synonymous, PASS-only variants, nor does it divide by callable territory-it does not implement the SOP-defined TMB formula. TMB calculation, as specified by the SOP, is a manual downstream computation using the workflow's annotated filtered variant and coverage outputs as inputs.

## 16. No Homologous Recombination Deficiency (HRD) Automation
SOP section 9.4 explicitly states that the workflow it describes does not generate a validated genomic-scar HRD score, framing the deliverable instead as "HRR Gene Review with LOH Assessment." Consistent with this scope, no rule in the current repository performs segment-level loss-of-heterozygosity (LOH) analysis or targeted extraction/review of the HRR-pathway genes listed in SOP section 8.2. This entire analytical category-both the HRR gene review and the LOH assessment-is presently manual and downstream in its entirety; no partial automation exists.

## 17. No Automated Clinical Report Generation
SOP section 10 specifies the content of a clinical report: sample and assay information, QC and coverage summaries, somatic SNV/INDEL findings, CNV findings, MSI status, TMB score, HRR gene review, neuroblastoma-specific biomarkers, clinical interpretation, investigational findings, and limitations. No report-generation rule, script, or template exists in the repository. Compilation of a clinical report is a manual, downstream activity drawing on the workflow's outputs (the annotated VCF, `HsMetrics.txt`, `stats.txt`, duplication metrics, and the contamination table) together with the results of the manual procedures described in Sections 11-16.

## 18. Need for Manual Review at Defined Checkpoints
No rule in the Snakemake DAG programmatically evaluates pipeline-generated metrics against the SOP section 11 acceptance-criteria table, and no rule raises a distinct, named error corresponding to the specific failure conditions enumerated in SOP section 13. Workflow termination on rule failure is provided generically by Snakemake's standard execution model and by each underlying tool's own error handling, rather than by SOP-specific validation logic. 

Manual review of QC and metric outputs against the SOP section 11 table, and manual judgment regarding the SOP section 13 failure conditions, remain required, non-automated steps at every stage boundary-review of sequencing/alignment QC metrics, contamination and orientation bias estimates, the PASS variant list for genuinely absent expected findings (triggering investigation per SOP section 7.2), and all annotated variants in the context of the mandatory neuroblastoma gene panel (SOP section 8.2).

## 19. Need for Laboratory Validation
This pipeline, as implemented, has not been independently characterized in this document for analytical sensitivity, specificity, accuracy, precision, or reportable range. Per SOP section 2, any modification of software, reference resources, capture design, workflow components, or analytical thresholds requires documented validation before production use. The pipeline as delivered is a computational framework consistent with the SOP's described methodology where implemented; it does not substitute for the laboratory's own analytical validation obligations.

## 20. Need for Orthogonal Confirmation
Variants of clinical significance identified through this pipeline, particularly those informing treatment decisions, should be confirmed using an orthogonal method (for example, Sanger sequencing, an independent targeted assay, or an independent NGS-based assay), in accordance with standard clinical laboratory practice for high-stakes variant calls-particularly given the tumor-only calling limitations described in Sections 2-5.

## 21. Designed for Research and Workflow Standardization
The repository, as implemented, provides a standardized, version-controlled computational workflow for preprocessing, alignment, duplicate marking, BQSR, tumor-only somatic variant calling, variant filtering, normalization, coverage assessment, and variant annotation, terminating in an annotated VCF together with supporting QC and variant-statistics outputs. It is designed to produce reproducible analytical intermediates for use within a broader clinical laboratory process, consistent with the SOP's own emphasis on standardization, documentation, and deviation management (SOP sections 12-14). It is not, in its current form and without the downstream manual analyses, validation, and clinical interpretation described throughout this document, intended to independently generate clinical conclusions.

## 22. Not a Diagnostic Medical Device
This pipeline is not a Food and Drug Administration (FDA)-cleared or otherwise regulatory-approved diagnostic medical device. Its outputs-an annotated VCF, coverage metrics, and variant statistics-are analytical intermediates and are not intended for direct clinical decision-making without the manual interpretation, downstream biomarker analyses, laboratory validation, and qualified clinical review described throughout this document and the accompanying SOP.

---
> This limitations document should be included, in summary or by reference, in the "Limitations" section of any clinical report generated using outputs from this pipeline, consistent with SOP section 10.
