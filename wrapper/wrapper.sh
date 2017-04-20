#!/bin/bash

function debug {
  echo "creating debugging directory"
mkdir .debug
for word in ${rmthis}
  do
    if [[ "${word}" == *.sh ]] || [[ "${word}" == lib ]]
      then
        mv "${word}" .debug;
      fi
  done
}

rmthis=`ls`
echo ${rmthis}

ARGSU=" ${reference_in} ${m1} ${m2} ${r_file} ${index_archive} ${b2_index_base} ${fasta_input} ${qseq} ${raw_input} ${trim5} ${trim3} ${phred64} ${intquals} ${preset} ${N_opt} ${L_opt} ${i_opt} ${n-ceil} ${dpad} ${gbar} ${ignore-quals} ${nofw} ${norc} ${no1mm} ${alignment} ${ma_opt} ${mp_opt} ${np_opt} ${rdg_opt} ${rfg_opt} ${score-min} ${report_int} ${report_all} ${D_opt} ${R_opt} ${minins} ${maxins} ${pe-alignment} ${no-mixed} ${no-discordant} ${no-dovetail} ${no-contain} ${no-overlap} ${ungz} ${algz} ${unconcgz} ${alconcgz} ${met} ${qc-filter}"
REFERENCEU=`echo ${reference_in} | sed -e 's/ /, /g'`
REFECMD=`echo ${reference_in} | sed -e 's/ /,/g'`
M1U=`echo ${m1} | sed -e 's/ /, /g'`
M1CMD=`echo ${m1} | sed -e 's/ /,/g'`
M2U=`echo ${m2} | sed -e 's/ /, /g'`
M2CMD=`echo ${m2} | sed -e 's/ /,/g'`
RFILEU=`echo ${r_file} | sed -e 's/ /, /g'`
RFILECMD=`echo ${r_file} | sed -e 's/ /,/g'`
INDEXARCHIVEU="${index_archive}"
INPUTSU="${REFERENCEU}, ${M1U}, ${M2U}, ${RFILEU}, ${INDEXARCHIVEU}"
echo "reference file(s) are " "${REFERENCEU}"
echo "mate #1 file(s) are ""${M1U}"
echo "mate #2 file(s) are ""${M2U}"
echo "unpaired read file(s) are ""${RFILEU}"
echo "archive with index is ""${INDEXARCHIVEU}"
echo "input file(s) are ""${INPUTSU}"
echo "arguments are ""${ARGSU}"

#####add checks for mutally inclusive/exclusive args
####check if there is need to build an index -OK
#####for preset add -local if alignement is local -OK
#####generate command
#####add arguments per input files

CMDLINEARGS=""

###################build index step of bowtie2########################
if [ -n "${reference_in}" ]
  then
    if [ -n "${index_archive}" ]
      then
        >&2 echo "only one between Index archive and reference file(s) is expected, please choose one"
        debug
        exit 1;
    else
      if [ -n "${b2_index_base}" ]
        then
          CMDLINEARGS+="bowtie2-build ${REFECMD} ${b2_index_base}; "
        else
          echo "Index base was not given, the default cyverse_index will be used"
          CMDLINEARGS+="bowtie2-build ${REFECMD} cyverse_index; "
      fi
    fi
fi
#if archive is given have to be unzipped now for next steps to happen
if [ -n "${index_archive}" ]
  then
    CMDLINEARGS+="tar -xzvf ${index_archive}; "
    UNZIP=`echo ${index_archive} | sed -e 's/.gz$//g; s/.tar$//g'` ####check this is the one used if it's given in json, possibly change the varibale name and use shell to use this if it exist, the one given by agave if otherwise, or cyverse_index at last
fi

#####################map step of bowtie2#############################
#check inputs first
if [ -n "${m1}" -a -z "${m2}" ] || [ -z "${m1}" -a -n "${m2}" ]
  then
    >&2 echo "both mates are required. Please give the missing input file(s)"
    debug
    exit 1;
fi
if [ -n "${m1}" ] && [ -n "${r_file}" ]
  then
    >&2 echo "paired read file(s) and unpaired are mutually exclusive. Please choose one."
    debug
    exit 1;
fi
if [ -z "${m1}" ] && [ -z "${r_file}" ]
  then
    >&2 echo "file(s) to align are required: please provide paired or unpaired reads"
    debug
    exit 1;
fi

#check parameters and options
CMDLINEARGS+="bowtie2 "
#choose input format -this *may* potentially work with multiple formats, but the app would be very user unfriendly andit would have to specify to ignore qualities anyway so we keep it like this for cyverse
if [ -n "${fasta_input}" ]
  then
    if [ -n "${qseq}" -o -n "${raw_input}" ]
      then
        >&2 echo "inputs should all be FASTQ, FASTA, qseq or raw files"
        debug
        exit 1;
  else
    if [ -n "${qseq}" -a -n "${raw_input}" ]
      then
        >&2 echo "inputs should all be FASTQ, FASTA, qseq or raw files"
        debug
        exit 1;
    fi
  fi
fi
CMDLINEARGS+="${fasta_input} ${qseq} ${raw_input} ${trim5} ${trim3} ${phred64} ${intquals} "
if [ "${alignment}" = "--end-to-end " ]
  then
    CMDLINEARGS+="${alignment} ${preset} "
  else
    localpreset=`echo ${preset} | sed -e 's/ $/-local /g'`
    CMDLINEARGS+="${alignment} ${localpreset} "
fi
if [ -n "${preset}" ]
  then
    echo "WARNING: you used a preset, every other -D -R -N -L -i option specified will be ignored: "
    echo "${N_opt} ${L_opt} ${i_opt} ${R_opt} ${D_opt} will be ignored."
  else
    CMDLINEARGS+="${N_opt} ${L_opt} ${i_opt} ${R_opt} ${D_opt} "
fi
CMDLINEARGS+="${n-ceil} ${dpad} ${gbar} ${ignore-quals} ${nofw} ${norc} ${no1mm} ${ma_opt} ${mp_opt} ${np_opt} ${rdg_opt} ${rfg_opt} ${score-min} "
if [ -n "${report_int}" -a -n "${report_all}" ]
  then
    echo "WARNING: you selected both -k and --all. -k option is running, --all will be ignored"
    CMDLINEARGS+="${report_int} "
  else
    CMDLINEARGS+="${report_int} ${report_all} "
fi
CMDLINEARGS+="${minins} ${maxins} ${pe-alignment} ${no-mixed} ${no-discordant} ${no-dovetail} ${no-contain} ${no-overlap} "
if [ -n "${ungz}" ]
  then
    CMDLINEARGS+="${ungz} unaligned_unpaired "
fi
if [ -n "${algz}" ]
  then
    CMDLINEARGS+="${algz} aligned_unpaired "
fi
if [ -n "${unconcgz}" ]
  then
    CMDLINEARGS+="${unconcgz} unconcordant_pairs "
fi
if [ -n "${alconcgz}" ]
  then
    CMDLINEARGS+="${alconcgz} concordant_pairs "
fi
if [ -n "${met}" ]
  then
    CMDLINEARGS+="${met} metrics "
fi
CMDLINEARGS+="${qc-filter} "

#add file(s) -x -1 -2 -U condireing they have to be comma separated with no spaces in between
if [ -n "${UNZIP}" ]
  then
    CMDLINEARGS+="-x ${UNZIP} "
  else
    if [ -n "${b2_index_base}" ]
      then
        CMDLINEARGS+="-x ${b2_index_base} "
      else
        CMDLINEARGS+="-x cyverse_index "
    fi
fi
if [ -n "${m1}" ]
  then
    CMDLINEARGS+="-1 ${M1CMD} -2 ${M2CMD} "
  else
    CMDLINEARGS+="-U ${RFILECMD} "
fi
CMDLINEARGS+="-S output"

echo ${CMDLINEARGS}
chmod +x launch.sh

exit 0;

echo  universe                = docker >> lib/condorSubmitEdit.htc
echo docker_image            =  cyverseuk/bowtie2:v2.2.6 >> lib/condorSubmitEdit.htc
echo executable               = ./launch.sh >> lib/condorSubmitEdit.htc ###
echo transfer_input_files               = ${INPUTSU}, launch.sh >> lib/condorSubmitEdit.htc ####add permissions to launch.sh
echo arguments                          = ${CMDLINEARGS} >> lib/condorSubmitEdit.htc
cat /mnt/data/apps/ncbi_sra_import/lib/condorSubmit.htc >> lib/condorSubmitEdit.htc

less lib/condorSubmitEdit.htc

jobid=`condor_submit -batch-name ${PWD##*/} lib/condorSubmitEdit.htc`
jobid=`echo $jobid | sed -e 's/Sub.*uster //'`
jobid=`echo $jobid | sed -e 's/\.//'`

#echo $jobid

#echo going to monitor job $jobid
condor_tail -f $jobid

debug

exit 0
