#!/bin/bash

#adapted from http://eradman.com/posts/ut-shell-scripts.html

typeset -i tests_run=0

function try { this="$1"; }

trap 'printf "$0: exit code $? on line $LINENO\nFAIL: $this\n"; exit 1' ERR

#check returned value is what is expected
function assert {
        let tests_run+=1
        [ "$1" = "$2" ] && { echo -n "."; return; }
        printf "\nFAIL: $this\n'$1' != '$2'\n"; exit 1
}

#check the script fails as expected
function assert_fail {
        let tests_run+=1
        [ "${1//$2}" != "${1}" ] && { echo -n "."; return; }
        printf "\nFAIL: $this\n '$1' exit code = 0\n"; exit 1
}

#check we are in an empty directory to avoid deleting files
if [ "`ls`" != "" ]
  then
    echo "ERROR: Run this script in an empty directory!!!!!"
    exit 1;
fi

try "reference_in and index_archive are mutually exclusive"
assert_fail "`reference_in=filename1 index_archive=filename2 ../wrapper.sh 2>&1 >/dev/null`" "only one between Index archive and reference file(s) is expected, please choose one"

try "mates read are required in pairs 1"
assert_fail "`m1=filename ../wrapper.sh 2>&1 >/dev/null`" "both mates are required. Please give the missing input file(s)"

try "mates read are required in pairs 2"
assert_fail "`m2=filename ../wrapper.sh 2>&1 >/dev/null`" "both mates are required. Please give the missing input file(s)"

try "paired and unpaired mutually exclusive"
assert_fail "`m1=filename m2=secondpair r_file=filename2 ../wrapper.sh 2>&1 >/dev/null`" "paired read file(s) and unpaired are mutually exclusive. Please choose one."

try "an input file with reads is required"
assert_fail "`../wrapper.sh 2>&1 >/dev/null`" "file(s) to align are required: please provide paired or unpaired reads"

try "only one input format allowed 1"
assert_fail "`r_file=filename fasta_input='-f' qseq='--qseq' ../wrapper.sh 2>&1 >/dev/null`" "inputs should all be FASTQ, FASTA, qseq or raw files"

try "only one input format allowed 2"
assert_fail "`r_file=filename fasta_input=-f raw_input=-r ../wrapper.sh 2>&1 >/dev/null`" "inputs should all be FASTQ, FASTA, qseq or raw files"

try "only one input format allowed 3"
assert_fail "`r_file=filename raw_input='-r' qseq='--seq' ../wrapper.sh 2>&1 >/dev/null`" "inputs should all be FASTQ, FASTA, qseq or raw files"

echo; echo "PASS: $tests_run tests run"
