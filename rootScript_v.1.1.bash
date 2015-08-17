#! /bin/bash

### script to create variables that hold paths to reference data sets and tools used in the pipeline

pathDir="/data/common/" # LOKI path
#pathDir="/Volumes/my_data/hg19/researchBundle/"

refFile=$pathDir"refData/dataDistro_r01_d01/b37/genomic/gatkBundle_2.5/human_g1k_v37_decoy.fasta"
millIndel=$pathDir"refData/dataDistro_r01_d01/b37/genomic/gatkBundle_2.5/Mills_and_1000G_gold_standard.indels.b37.vcf"
kgIndel=$pathDir"refData/dataDistro_r01_d01/b37/genomic/gatkBundle_2.5/1000G_phase1.indels.b37.vcf"
dbsnpFile=$pathDir"/data/common/refData/dataDistro_r01_d01/b37/genomic/gatkBundle_2.5/dbsnp_137.b37.vc"

hapmap=$pathDir"refData/dataDistro_r01_d01/b37/genomic/gatkBundle_2.5/hapmap_3.3.b37.vcf"
omni=$pathDir"refData/dataDistro_r01_d01/b37/genomic/gatkBundle_2.5/1000G_omni2.5.b37.vcf"
kgSNP=$pathDir"refData/dataDistro_r01_d01/b37/genomic/gatkBundle_2.5/1000G_phase1.snps.high_confidence.b37.vcf"
dbsnpFile=$pathDir"refData/dataDistro_r01_d01/b37/genomic/gatkBundle_2.5/dbsnp_137.b37.vcf"
annovarRef=$pathDir"refData/annovar/annovar_2013Aug23/humandb"
###LOKI PATH
gatk="/data/common/tools/GATK/GenomeAnalysisTK-3.1-1/GenomeAnalysisTK.jar"
picardDir="/data/common/tools/picard/picard-tools-1.112"
#gatk="/data/projects/pubuduss/GenomeAnalysisTK-2.8-1-g932cd3a/GenomeAnalysisTK.jar"

#gatk="/Users/pubudu/Downloads/BiSoft/GenomeAnalysisTK-2.8-1-g932cd3a/GenomeAnalysisTK.jar"
#picardDir="/Users/pubudu/Downloads/BiSoft/picard-tools-1/picard-tools-1.88"


picard_FixMateInformation(){
#Step 0: Picard FixMateInformation

local samFile="$1"
local bamFile="$2"

java -Xmx2g -jar $picardDir/FixMateInformation.jar INPUT=$samFile \
OUTPUT=$bamFile \
SORT_ORDER=coordinate \
VALIDATION_STRINGENCY=SILENT \
CREATE_INDEX=true \
VERBOSITY=INFO \
QUIET=false \
MAX_RECORDS_IN_RAM=500000 \
CREATE_MD5_FILE=false \
TMP_DIR=/data/projects/pubuduss/tmp4_java 2>010_alignment/errFixMateInformation

}

gatk_RealignerTargetCreator(){
#Step 1: creating intervals ...

local bamFile="$1"
local intervalFile="$2"

java -Xmx2g -jar $gatk -T RealignerTargetCreator \
-R $refFile \
-o $intervalFile \
-I $bamFile \
--known $millIndel \
--known $kgIndel \
-nt 3 2>020_refineAlignment/010_realignGATK/errRealignerTargetCreator > 020_refineAlignment/010_realignGATK/realignerTargetCreatorInfo.txt

}

gatk_IndelRealigner(){
#Step 2: realigning ...

local bamFile="$1"
local intervalFile="$2"
local realignBam="$3"

java -Xmx4g -jar $gatk -T IndelRealigner \
-I $bamFile \
-R $refFile \
-targetIntervals $intervalFile \
-o $realignBam \
-known $millIndel \
-known $kgIndel \
-compress 0 2>020_refineAlignment/010_realignGATK/errIndelRealigner > 020_refineAlignment/010_realignGATK/indelRealignerInfo.txt

}

picard_MarkDuplicates(){
#Marking duplicates:

local realignBam="$1"
local markDupBam="$2"
local metricsFile="$3"

java -Xmx2g -jar $picardDir/MarkDuplicates.jar INPUT=$realignBam \
OUTPUT=$markDupBam \
METRICS_FILE=$3 \
CREATE_INDEX=TRUE \
VALIDATION_STRINGENCY=STRICT \
TMP_DIR=/data/projects/pubuduss/tmp4_java 2>020_refineAlignment/020_markDupPicard/errMarkDup

}

gatk_BaseRecalibrator(){
#Step 3.1: generating recal_data.grp for calibration ...

local markDupBam="$1"
local intervalFile="$2"
local grpFile="$3"

java -Xmx4g -jar $gatk -T BaseRecalibrator \
-I $markDupBam \
-R $refFile \
-knownSites $dbsnpFile \
-knownSites $millIndel \
-knownSites $kgIndel \
-L $intervalFile \
-o $grpFile \
-nct 3 2>020_refineAlignment/030_BQRecalGATK/errBaseRecalibratorPre > 020_refineAlignment/030_BQRecalGATK/baseRecalibratorPreInfo.txt

}

gatk_BaseRecalibrator_Post(){
# Step 3.2: generating post_recal_data.grp for ploting improvements ...

local markDupBam="$1"
local intervalFile="$2"
local grpFile="$3"
local postgrpFile="$4"

java -Xmx4g -jar $gatk -T BaseRecalibrator \
-I $markDupBam \
-R $refFile \
-knownSites $dbsnpFile \
-knownSites $millIndel \
-knownSites $kgIndel \
-L $intervalFile \
-o $postgrpFile \
-BQSR $grpFile \
-nct 3 2>020_refineAlignment/030_BQRecalGATK/errBaseRecalibratorPost > 020_refineAlignment/030_BQRecalGATK/baseRecalibratorPostInfo.txt

}

gatk_AnalyzeCovariates(){
# Step 2.3.3: generating plot showing improvements ...
# generates a plot report to assess the quality of a recalibration

local intervalFile="$1"
local grpFile="$2"
local postgrpFile="$3"
local plotFile="$4"

java -Xmx4g -jar $gatk -T AnalyzeCovariates \
-R $refFile \
-L $intervalFile \
-before $grpFile \
-after $postgrpFile \
-plots $plotFile 2>020_refineAlignment/030_BQRecalGATK/errAnalyzeCovariates > 020_refineAlignment/030_BQRecalGATK/analyzeCovariatesInfo.txt

}

gatk_PrintReads(){
#Step 4: generating results with original quality scores ...
#-EOQ is implemented to Emit the OQ tag with the original base qualities

local markDupBam="$1"
local grpFile="$2"
local intervalFile="$3"
local recalBam="$4"

java -Xmx1g -jar $gatk -T PrintReads \
-R $refFile \
-I $markDupBam \
-BQSR $grpFile \
-L $intervalFile \
-EOQ -o $recalBam \
-nct 3 2>020_refineAlignment/030_BQRecalGATK/errPrintReads > 020_refineAlignment/030_BQRecalGATK/printReadsInfo.txt

}

gatk_UnifiedGenotyper(){
### Step 4: Calling variants
# -stand_call_conf: The minimum phred-scaled confidence threshold at which variants should be called
# -stand_emit_conf: The minimum phred-scaled confidence threshold at which variants should be emitted (and filtered with LowQual if less than the calling threshold)

local bamFile="$1"
local callConf=$2
local emitConf=$3
local intervalFile="$4"
local allRawOut="$5"

java -Xmx4g -jar $gatk -R $refFile -T UnifiedGenotyper \
-I $bamFile \
--dbsnp $dbsnpFile \
-L $intervalFile \
-o $allRawOut \
-stand_call_conf $callConf \
-stand_emit_conf $emitConf \
-nt $nt \
-glm BOTH \
-dcov 200 2>040_variantCalling/gatk/errUnifiedGenotyper > 040_variantCalling/gatk/unifiedGenotyperInfo.txt

}

gatk_SelectVariants_snp(){
###Extract SNP calls

local allRawOut="$1"
local nt=$2
local snpRawOut="$3"

java -Xmx2g -jar $gatk -R $refFile -T SelectVariants \
--variant $allRawOut \
-o $snpRawOut \
-selectType SNP \
-nt $nt 2>040_variantCalling/gatk/errSelectVariantsSNP > 040_variantCalling/gatk/selectVariantsSNPInfo.txt

}

gatk_SelectVariants_indel(){
###Extract INDEL calls

local allRawOut="$1"
local nt=$2
local indelRawOut="$3"

java -Xmx2g -jar $gatk -R $refFile -T SelectVariants \
--variant $allRawOut \
-o $indelRawOut \
-selectType INDEL \
-nt $nt 2>040_variantCalling/gatk/errSelectVariantsIndel > 040_variantCalling/gatk/selectVariantsIndelInfo.txt

}

gatk_VariantRecalibrator(){
#SNP Variant Quality Score Recalibration:

local snpRawOut="$1"
local recalFile="$2"
local tranchFile="$3"
local rscriptFile="$4"

java -Xmx4g -jar $gatk -T VariantRecalibrator \
-R $refFile \
-input $snpRawOut \
-resource:hapmap,known=false,training=true,truth=true,prior=15.0 $hapmap \
-resource:omni,known=false,training=true,truth=false,prior=12.0 $omni \
-resource:1000G,known=false,training=true,truth=false,prior=10.0 $kgSNP \
-resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $dbsnpFile \
-an QD \
-an MQRankSum \
-an ReadPosRankSum \
-an FS \
-recalFile $recalFile \
-tranchesFile $tranchFile \
-rscriptFile $rscriptFile \
--maxGaussians 4 \
-mode SNP 2>050_postVarCalProcess/gatk/010_qualityFiltration/errVariantRecalibratorSNP > 050_postVarCalProcess/gatk/010_qualityFiltration/variantRecalibratorSNPInfo.txt

}

gatk_ApplyRecalibration(){
### Step 5.2: Doing ApplyRecalibration

local snpRawOut="$1"
local tsFilterLevel=$2
local tranchFile="$3"
local recalFile="$4"
local snpRecalFiltVcf="$5"

java -Xmx3g -jar $gatk -T ApplyRecalibration \
-R $refFile \
-input $snpRawOut \
-mode SNP \
--ts_filter_level $tsFilterLevel \
-tranchesFile $tranchFile \
-recalFile $recalFile \
-o $snpRecalFiltVcf 2>050_postVarCalProcess/gatk/010_qualityFiltration/errApplyRecalibrationSNP > 050_postVarCalProcess/gatk/010_qualityFiltration/applyRecalibrationSNPInfo.txt

}

gatk_VariantFiltration(){
### Step 5.3: INDEL hard filtration

local indelRawOut="$1"
local indel_hardFileVcf="$2"

java -Xmx2g -jar $gatk -R $refFile -T VariantFiltration \
-o $indel_hardFileVcf \
--variant $indelRawOut \
--filterExpression "QD < 2.0" \
--filterExpression "ReadPosRankSum < -20.0" \
--filterExpression "FS > 200.0" \
--filterName QDFilter \
--filterName ReadPosFilter \
--filterName FSFilter 2>050_postVarCalProcess/gatk/010_qualityFiltration/errVariantFiltrationIndel >050_postVarCalProcess/gatk/010_qualityFiltration/variantFiltrationIndelInfo.txt

}

gatk_CombineVariants(){
### Step 5.4: Merge SNP and Indel filtration vcf files

local snpRecalFiltVcf="$1"
local indel_hardFileVcf="$2"
local allFiltVcf="$3"

java -Xmx2g -jar $gatk -R $refFile -T CombineVariants \
--variant $snpRecalFiltVcf \
--variant $indel_hardFileVcf \
-o $allFiltVcf 2>050_postVarCalProcess/gatk/010_qualityFiltration/errCombineVariants > 050_postVarCalProcess/gatk/010_qualityFiltration/combineVariantsInfo.txt

}

annovarAnnotate(){
### Step 6.1: Annovar Annotate 1; Convert vcf to aviinput
echo -e "\tStep 6.1: Annovar Annotate 1; Convert vcf to aviinput"

local allFiltVcf="$1"
local aviFile="$2"

perl /data/common/tools/annovar/annovar/convert2annovar.pl --format vcf4old --includeinfo --chrmt MT --withzyg $allFiltVcf > $aviFile 2>050_postVarCalProcess/020_annovarAnnotation/errConvert2annovarAll

### Step 6.1: Annovar Annotate 2; Annotation of aviinput
echo -e "\tStep 6.1: Annovar Annotate 2; Annotation of aviinput"

perl /data/common/tools/annovar/annovar/table_annovar.pl $aviFile $annovarRef --buildver hg19 --outfile 050_postVarCalProcess/020_annovarAnnotation/allAnnotation --otherinfo --nastring NA --gff3dbfile repeatMasker_hg19_all.gff3 -protocol 'gff3,refGene,phastConsElements46way,genomicSuperDups,esp6500si_all,1000g2012apr_all,snp137,avsift,ljb2_all' --operation 'r,g,r,r,f,f,f,f,f' 2>050_postVarCalProcess/020_annovarAnnotation/errTableAnnovarAll

}
