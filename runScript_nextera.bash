#! /bin/bash


sampleId=$(echo $1 | cut -d . -f1)
export sampleId
samFile=$1
bamFile='010_alignment/'$1'.posiSrt.bam'

source ~/lokiScripts/configScript_v.1.1_nextera.bash 
#source ~/lokiScripts/configScript.bash
#source ~/lokiScripts/rootScript.bash
source ~/lokiScripts/rootScript_v.1.1.bash
source ~/lokiScripts/checkScript.bash


########################################################################################################
####                                     Picard FixmateInformation                                  ####
########################################################################################################

[[ -d 010_alignment ]] && echo -e "\n020_refineAlignment: exists" || mkdir 010_alignment

#Step 0: Picard FixMateInformation ...
echo -e "\nStep 0: Picard FixMateInformation ..."
date

if [ -f "010_alignment/errFixMateInformation" ]
then
    exit_if_found 010_alignment/errFixMateInformation 0
    echo -e "\tPrevious Picard FixMateInformation run shows no exceptions"
else
#picard_MarkDuplicates <realign.bam> <markDup.bam> <metricsFile>
    picard_FixMateInformation $samFile $bamFile
fi

exit_if_found 010_alignment/errFixMateInformation 001


########################################################################################################
####                                          Refine alignemnt                                      ####
########################################################################################################


[[ -d 020_refineAlignment ]] && echo -e "\n020_refineAlignment: exists" || mkdir 020_refineAlignment
[[ -d 020_refineAlignment/010_realignGATK ]] && echo -e "020_refineAlignment/010_realignGATK: exists" || mkdir 020_refineAlignment/010_realignGATK
[[ -d 020_refineAlignment/020_markDupPicard ]] && echo -e "020_refineAlignment/020_markDupPicard: exists" || mkdir 020_refineAlignment/020_markDupPicard

#Step 1: creating intervals ...
echo -e "\nStep 1: creating intervals ..."
date

if [ -f "020_refineAlignment/010_realignGATK/errRealignerTargetCreator" ] && [ -f "020_refineAlignment/010_realignGATK/realignerTargetCreatorInfo.txt" ]
then
    exit_if_notEmpty "020_refineAlignment/010_realignGATK/errRealignerTargetCreator" 0
    exit_if_notFound "020_refineAlignment/010_realignGATK/realignerTargetCreatorInfo.txt" 0
    echo -e "\tPrevious GATK RealignerTargetCreator run shows no exceptions"
else
#gatk_RealignerTargetCreator <BAM.file> <realignerIntervalFile>
    gatk_RealignerTargetCreator $bamFile $realignerIntervalFile
fi

exit_if_notEmpty "020_refineAlignment/010_realignGATK/errRealignerTargetCreator" 101
exit_if_notFound "020_refineAlignment/010_realignGATK/realignerTargetCreatorInfo.txt" 102

#Step 2: realigning ...
echo -e "\nStep 2.1: realigning..."
date

if [ -f "020_refineAlignment/010_realignGATK/errIndelRealigner" ] && [ -f "020_refineAlignment/010_realignGATK/indelRealignerInfo.txt" ]
then
	exit_if_notEmpty "020_refineAlignment/010_realignGATK/errIndelRealigner" 0
	exit_if_notFound "020_refineAlignment/010_realignGATK/indelRealignerInfo.txt" 0
    echo -e "\tPrevious GATK IndelRealigner run shows no exceptions"
else
#gatk_IndelRealigner <BAM.file> <realignerIntervalFile> <realign.bam>
    gatk_IndelRealigner $bamFile $realignerIntervalFile $bamRealigned
fi

exit_if_notEmpty 020_refineAlignment/010_realignGATK/errIndelRealigner 211
exit_if_notFound 020_refineAlignment/010_realignGATK/indelRealignerInfo.txt 212

#Marking duplicates:
echo -e "\nStep 2.2: Marking duplicates ..."
date

if [ -f "020_refineAlignment/020_markDupPicard/errMarkDup" ]
then
	exit_if_found 020_refineAlignment/020_markDupPicard/errMarkDup 0
    echo -e "\tPrevious Picard MarkDuplicates run shows no exceptions"
else
#picard_MarkDuplicates <realign.bam> <markDup.bam> <metricsFile>
    picard_MarkDuplicates $bamRealigned $bamMarkDup $metricsFile
fi

exit_if_found 020_refineAlignment/020_markDupPicard/errMarkDup 221

########################################################################################################
####                               Base quality score recalibration                                 ####
########################################################################################################

[[ -d 020_refineAlignment/030_BQRecalGATK ]] && echo -e "\n020_refineAlignment/030_BQRecalGATK: exists" || mkdir 020_refineAlignment/030_BQRecalGATK

### Step 2.3: Doing Base Quality Score Recalibration:
echo -e "\nStep 2.3: Base Quality Score Recalibration..."

### Step 2.3.1: generating recal_data.grp for calibration ...
echo -e "\nStep 2.3.1: generating recal_data.grp for calibration..."
date
if [ -f "020_refineAlignment/030_BQRecalGATK/errBaseRecalibratorPre" ] && [ -f "020_refineAlignment/030_BQRecalGATK/baseRecalibratorPreInfo.txt" ]
then
    exit_if_notEmpty "020_refineAlignment/030_BQRecalGATK/errBaseRecalibratorPre" 0
    exit_if_notFound "020_refineAlignment/030_BQRecalGATK/baseRecalibratorPreInfo.txt" 0
    echo -e "\tPrevious GATK BaseRecalibrator run shows no exceptions"
else
#gatk_BaseRecalibrator <markDup.bam> <interval.file> <grp.file>
    gatk_BaseRecalibrator $bamMarkDup $intervalFile $grpFile
fi

exit_if_notEmpty "020_refineAlignment/030_BQRecalGATK/errBaseRecalibratorPre" 2311
exit_if_notFound "020_refineAlignment/030_BQRecalGATK/baseRecalibratorPreInfo.txt" 3112

### Step 2.3.2: generating post_recal_data.grp for ploting improvements ...
echo -e "Step 2.3.2: generating post_recal_data.grp for ploting improvements ..."
date
if [ -f "020_refineAlignment/030_BQRecalGATK/errBaseRecalibratorPost" ] && [ -f "020_refineAlignment/030_BQRecalGATK/baseRecalibratorPostInfo.txt" ]
then
    exit_if_notEmpty "020_refineAlignment/030_BQRecalGATK/errBaseRecalibratorPost" 0
    exit_if_notFound "020_refineAlignment/030_BQRecalGATK/baseRecalibratorPostInfo.txt" 0
    echo -e "\tPrevious GATK BaseRecalibrator run shows no exceptions"
else
#gatk_BaseRecalibrator_Post <markDup.bam> <interval.file> <grp.file> <postgrpFile>
    gatk_BaseRecalibrator_Post $bamMarkDup $intervalFile $grpFile $postGrpFile
fi

exit_if_notEmpty "020_refineAlignment/030_BQRecalGATK/errBaseRecalibratorPost" 2321
exit_if_notFound "020_refineAlignment/030_BQRecalGATK/baseRecalibratorPostInfo.txt" 2322


### Step 2.3.3: generating plot showing improvements ...
#echo -e "Step 2.3.3: generating plot showing improvements ..."
#date
#if [ -f "020_refineAlignment/030_BQRecalGATK/errAnalyzeCovariates" ] && [ -f "020_refineAlignment/030_BQRecalGATK/analyzeCovariatesInfo.txt" ]
#then
#    exit_if_notEmpty "020_refineAlignment/030_BQRecalGATK/errAnalyzeCovariates" 0
#    exit_if_notFound "020_refineAlignment/030_BQRecalGATK/analyzeCovariatesInfo.txt" 0
#    echo -e "\tPrevious GATK AnalyzeCovariates run shows no exceptions"
#else
#gatk_AnalyzeCovariates <interval.file> <grp.file> <plot.file> <postgrp.file>
#    gatk_AnalyzeCovariates $intervalFile $grpFile $postGrpFile $plotFile
#fi

#exit_if_notEmpty "020_refineAlignment/030_BQRecalGATK/errAnalyzeCovariates" 2331
#exit_if_notFound "020_refineAlignment/030_BQRecalGATK/analyzeCovariatesInfo.txt" 2332

[[ -d 060_delivery ]] && echo -e "\n060_delivery: exists" || mkdir 060_delivery

### Step 2.3.4: generating results with original quality scores ...
echo -e "\nStep 2.3.4: generating results with original quality score for calibration ..."
date
if [ -f "020_refineAlignment/030_BQRecalGATK/errPrintReads" ] && [ -f "020_refineAlignment/030_BQRecalGATK/printReadsInfo.txt" ]
then
    exit_if_notEmpty "020_refineAlignment/030_BQRecalGATK/errPrintReads" 0
    exit_if_notFound "020_refineAlignment/030_BQRecalGATK/printReadsInfo.txt" 0
    echo -e "\tPrevious GATK PrintReads run shows no exceptions"
else
#gatk_PrintReads <markDupBam> <grp.file> <intervalFile> <recalBam=060_delivery/all.realigned.markDup.baseQreCali.bam>
    gatk_PrintReads $bamMarkDup $grpFile $intervalFile $bamRecal
fi

exit_if_notEmpty "020_refineAlignment/030_BQRecalGATK/errPrintReads" 2341
exit_if_notFound "020_refineAlignment/030_BQRecalGATK/printReadsInfo.txt" 2342


########################################################################################################
####                                        Variant Calling                                         ####
########################################################################################################


[[ -d 040_variantCalling ]] && echo -e "\n040_variantCalling: exists" || mkdir 040_variantCalling
[[ -d 040_variantCalling/gatk ]] && echo -e "040_variantCalling/gatk: exists" || mkdir 040_variantCalling/gatk

### Step 4.1: Calling variants
echo -e "\nStep 4.1: Calling variants"
date
if [ -f "040_variantCalling/gatk/errUnifiedGenotyper" ] && [ -f "040_variantCalling/gatk/unifiedGenotyperInfo.txt" ]
then
    exit_if_notEmpty "040_variantCalling/gatk/errUnifiedGenotyper" 0
    exit_if_notFound "040_variantCalling/gatk/unifiedGenotyperInfo.txt" 0
    echo -e "\tPrevious GATK UnifiedGenotyper run shows no exceptions"
else
#gatk_UnifiedGenotyper <bam.file> <callConf> <emitConf> <interval.file> <allRawOut=gatk/all.raw.vcf>
    gatk_UnifiedGenotyper $bamRecal $callConf $emitConf $intervalFile $allRawOut
fi

exit_if_notEmpty "040_variantCalling/gatk/errUnifiedGenotyper" 411
exit_if_notFound "040_variantCalling/gatk/unifiedGenotyperInfo.txt" 412

### Step 4.2: Extract SNP calls
echo -e "\nStep 4.2: Extract SNP calls"
date
if [ -f "040_variantCalling/gatk/errSelectVariantsSNP" ] && [ -f "040_variantCalling/gatk/selectVariantsSNPInfo.txt" ]
then
    exit_if_notEmpty "040_variantCalling/gatk/errSelectVariantsSNP" 0
    exit_if_notFound "040_variantCalling/gatk/selectVariantsSNPInfo.txt" 0
    echo -e "\tPrevious GATK SelectVariants_snp run shows no exceptions"
else
#gatk_SelectVariants_snp <allRawOut=gatk/all.raw.vcf> <nt> <snpRawOut=gatk/snp.raw.vcf>
    gatk_SelectVariants_snp $allRawOut $nt $snpRawOut
fi

exit_if_notEmpty "040_variantCalling/gatk/errSelectVariantsSNP" 421
exit_if_notFound "040_variantCalling/gatk/selectVariantsSNPInfo.txt" 422

###Extract INDEL calls
echo -e "\nStep 4.3: Extract INDEL calls"
date
if [ -f "040_variantCalling/gatk/errSelectVariantsIndel" ] && [ -f "040_variantCalling/gatk/selectVariantsIndelInfo.txt" ]
then
    exit_if_notEmpty "040_variantCalling/gatk/errSelectVariantsIndel" 0
    exit_if_notFound "040_variantCalling/gatk/selectVariantsIndelInfo.txt" 0
    echo -e "\tPrevious GATK SelectVariants_indel run shows no exceptions"
else
#gatk_SelectVariants_indel <allRawOut=gatk/all.raw.vcf> <nt> <indelRawOut=gatk/snp.raw.vcf>
    gatk_SelectVariants_indel $allRawOut $nt $indelRawOut
fi

exit_if_notEmpty "040_variantCalling/gatk/errSelectVariantsIndel" 431
exit_if_notFound "040_variantCalling/gatk/selectVariantsIndelInfo.txt" 432

[[ -d 050_postVarCalProcess ]] && echo -e "\n050_postVarCalProcess: exists" || mkdir 050_postVarCalProcess
[[ -d 050_postVarCalProcess/gatk ]] && echo -e "050_postVarCalProcess/gatk: exists" || mkdir 050_postVarCalProcess/gatk
[[ -d 050_postVarCalProcess/gatk/010_qualityFiltration ]] && echo -e "050_postVarCalProcess/gatk/010_qualityFiltration: exists" || mkdir 050_postVarCalProcess/gatk/010_qualityFiltration
[[ -d 050_postVarCalProcess/020_annovarAnnotation ]] && echo -e "050_postVarCalProcess/020_annovarAnnotation: exists" || mkdir 050_postVarCalProcess/020_annovarAnnotation

### SNP Variant Quality Score Recalibration:
echo -e "\nStep 5.1: VariantRecalibrator"
date
if [ -f "050_postVarCalProcess/gatk/010_qualityFiltration/errVariantRecalibratorSNP" ] && [ -f "050_postVarCalProcess/gatk/010_qualityFiltration/variantRecalibratorSNPInfo.txt" ]
then
    exit_if_notEmpty "050_postVarCalProcess/gatk/010_qualityFiltration/errVariantRecalibratorSNP" 0
    exit_if_notFound "050_postVarCalProcess/gatk/010_qualityFiltration/variantRecalibratorSNPInfo.txt" 0
    echo -e "\tPrevious GATK VariantRecalibrator run shows no exceptions"
else
#gatk_VariantRecalibrator <snpRawOut> <recalFile = fDir/snp.vqsr.output.recal> <tranchesFile = fDir/snp.vqsr.output.tranches> <rscriptFile = fDir/snp.vqsr.output.plots.R>
    gatk_VariantRecalibrator $snpRawOut $recalFile $tranchesFile $rscriptFile
fi

exit_if_notEmpty "050_postVarCalProcess/gatk/010_qualityFiltration/errVariantRecalibratorSNP" 511
exit_if_notFound "050_postVarCalProcess/gatk/010_qualityFiltration/variantRecalibratorSNPInfo.txt" 512

### Step 5.2: Doing ApplyRecalibration
echo -e "\nStep 5.2: Doing ApplyRecalibration"
date
if [ -f "050_postVarCalProcess/gatk/010_qualityFiltration/applyRecalibrationSNPInfo.txt" ]
then
    exit_if_notFound "050_postVarCalProcess/gatk/010_qualityFiltration/applyRecalibrationSNPInfo.txt" 0
    echo -e "\tPrevious GATK ApplyRecalibration run shows no exceptions"
else
#gatk_ApplyRecalibration <snpRawOut> <tsFilterLevel = 99> <tranchFile = fDir/snp.vqsr.output.tranches> <recalFile = fDir/snp.vqsr.output.recal> <snpRecalFiltVcf=fDir/snp.recalibrated.filtered.vcf>
    gatk_ApplyRecalibration $snpRawOut $tsFilterLevel $tranchesFile $recalFile $snpRecalFiltVcf
fi

exit_if_notFound "050_postVarCalProcess/gatk/010_qualityFiltration/applyRecalibrationSNPInfo.txt" 522

### Step 5.3: INDEL hard filtration
echo -e "\nStep 5.3: INDEL hard filtration:"
date
if [ -f "050_postVarCalProcess/gatk/010_qualityFiltration/errVariantFiltrationIndel" ] && [ -f "050_postVarCalProcess/gatk/010_qualityFiltration/variantFiltrationIndelInfo.txt" ]
then
    exit_if_notEmpty "050_postVarCalProcess/gatk/010_qualityFiltration/errVariantFiltrationIndel" 0
    exit_if_notFound "050_postVarCalProcess/gatk/010_qualityFiltration/variantFiltrationIndelInfo.txt" 0
    echo -e "\tPrevious GATK VariantFiltration run shows no exceptions"
else
#gatk_VariantFiltration <indelRawOut=gatk/snp.raw.vcf> <indel_hardFileVcf = fDir/indel.hardFiltered.vcf>
    gatk_VariantFiltration $indelRawOut $indel_hardFileVcf
fi

exit_if_notEmpty "050_postVarCalProcess/gatk/010_qualityFiltration/errVariantFiltrationIndel" 531
exit_if_notFound "050_postVarCalProcess/gatk/010_qualityFiltration/variantFiltrationIndelInfo.txt" 532

### Step 5.4: Merge SNP and Indel filtration vcf files
echo -e "\nStep 5.4: Merge SNP and Indel filtration vcf files:"
date
if [ -f "050_postVarCalProcess/gatk/010_qualityFiltration/errCombineVariants" ] && [ -f "050_postVarCalProcess/gatk/010_qualityFiltration/combineVariantsInfo.txt" ]
then
    exit_if_notEmpty "050_postVarCalProcess/gatk/010_qualityFiltration/errCombineVariants" 0
    exit_if_notFound "050_postVarCalProcess/gatk/010_qualityFiltration/combineVariantsInfo.txt" 0
    echo -e "\tPrevious GATK CombineVariants run shows no exceptions"
else
#gatk_CombineVariants <snpRecalFiltVcf> <indel_hardFileVcf> <allFiltVcf>
    gatk_CombineVariants $snpRecalFiltVcf $indel_hardFileVcf $allFiltVcf
fi

exit_if_notEmpty "050_postVarCalProcess/gatk/010_qualityFiltration/errCombineVariants" 541
exit_if_notFound "050_postVarCalProcess/gatk/010_qualityFiltration/combineVariantsInfo.txt" 542

########################################################################################################
####                                      Annovar Annotate                                          ####
########################################################################################################

echo "Step 6: HGMD and Annovar annotation"
[[ -d 050_postVarCalProcess/030_HGMDAnnotation ]] && echo -e "050_postVarCalProcess/030_HGMDAnnotation: exists" || mkdir 050_postVarCalProcess/030_HGMDAnnotation
perl ~/script/vcResearch/script/variantCalling/steps/annotationAnnovar_loki.pl $allFiltVcf ~/script/sample.conf
mv 060_delivery/allAnnotation.hg19_multianno.hgmd.reformat.txt '060_delivery/'$sampleId'_allAnnotation.hg19_multianno.hgmd.reformat.txt'
#echo "Step 6: Annovar annotation"
#annovarAnnotate $allFiltVcf $aviFile


########################################################################################################
####                                      unset ENV.Variables                                       ####
########################################################################################################

unset sampleId
