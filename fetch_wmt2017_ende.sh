#!/usr/bin/env bash
# Copyright 2017 Natural Language Processing Group, Nanjing University, zhaocq.nlp@gmail.com.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

REPO_DIR=.

OUTPUT_DIR="${1:-wmt17_de_en}"

MERGE_OPS=90000
BPE_THRESHOLD=50

echo "Writing to ${OUTPUT_DIR}. To change this, set the OUTPUT_DIR environment variable."

OUTPUT_DIR_DATA="${OUTPUT_DIR}/data"
mkdir -p $OUTPUT_DIR_DATA

echo "Downloading preprocessed data. This may take a while..."

curl -o ${OUTPUT_DIR_DATA}/corpus.tc.de.gz \
    http://data.statmt.org/wmt17/translation-task/preprocessed/de-en/corpus.tc.de.gz

curl -o ${OUTPUT_DIR_DATA}/corpus.tc.en.gz \
    http://data.statmt.org/wmt17/translation-task/preprocessed/de-en/corpus.tc.en.gz

echo "Downloading preprocessed dev data..."
curl -o ${OUTPUT_DIR_DATA}/dev.tgz \
    http://data.statmt.org/wmt17/translation-task/preprocessed/de-en/dev.tgz

echo "Downloading test data..."
curl -o ${OUTPUT_DIR_DATA}/test.tgz \
    http://data.statmt.org/wmt17/translation-task/test.tgz

echo "Extracting all files..."
gzip -d ${OUTPUT_DIR_DATA}/corpus.tc.de.gz
gzip -d ${OUTPUT_DIR_DATA}/corpus.tc.en.gz
mkdir -p "${OUTPUT_DIR_DATA}/dev"
tar -zxvf ${OUTPUT_DIR_DATA}/dev.tgz -C "${OUTPUT_DIR_DATA}/dev"
tar -zxvf ${OUTPUT_DIR_DATA}/test.tgz -C "${OUTPUT_DIR_DATA}/"

# recover special fields
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/corpus.tc.de > ${OUTPUT_DIR}/train.tok.de
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/corpus.tc.en > ${OUTPUT_DIR}/train.tok.en

# use newstest2016 as dev set
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/dev/newstest2016.tc.en > ${OUTPUT_DIR}/dev.tok.en
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/dev/newstest2016.tc.de > ${OUTPUT_DIR}/dev.tok.de

# Convert newstest2017 data into raw text format
${REPO_DIR}/scripts/input-from-sgm.perl \
  < ${OUTPUT_DIR_DATA}/test/newstest2017-deen-src.de.sgm \
  > ${OUTPUT_DIR_DATA}/test/newstest2017.deen.de
${REPO_DIR}/scripts/input-from-sgm.perl \
  < ${OUTPUT_DIR_DATA}/test/newstest2017-deen-ref.en.sgm \
  > ${OUTPUT_DIR_DATA}/test/newstest2017.deen.en
${REPO_DIR}/scripts/input-from-sgm.perl \
  < ${OUTPUT_DIR_DATA}/test/newstest2017-ende-src.en.sgm \
  > ${OUTPUT_DIR_DATA}/test/newstest2017.ende.en
${REPO_DIR}/scripts/input-from-sgm.perl \
  < ${OUTPUT_DIR_DATA}/test/newstest2017-ende-ref.de.sgm \
  > ${OUTPUT_DIR_DATA}/test/newstest2017.ende.de


# tokenize
echo "Tokenize..."
cat ${OUTPUT_DIR_DATA}/test/newstest2017.deen.de | \
   ${REPO_DIR}/scripts/normalize-punctuation.perl -l de | \
   ${REPO_DIR}/scripts/tokenizer.perl -a -q -l de -no-escape > ${OUTPUT_DIR}/newstest2017.deen.tok.de

cat ${OUTPUT_DIR_DATA}/test/newstest2017.deen.en | \
   ${REPO_DIR}/scripts/normalize-punctuation.perl -l en | \
   ${REPO_DIR}/scripts/tokenizer.perl -a -q -l en -no-escape > ${OUTPUT_DIR}/newstest2017.deen.tok.en

cat ${OUTPUT_DIR_DATA}/test/newstest2017.ende.de | \
   ${REPO_DIR}/scripts/normalize-punctuation.perl -l de | \
   ${REPO_DIR}/scripts/tokenizer.perl -a -q -l de -no-escape > ${OUTPUT_DIR}/newstest2017.ende.tok.de

cat ${OUTPUT_DIR_DATA}/test/newstest2017.ende.en | \
   ${REPO_DIR}/scripts/normalize-punctuation.perl -l en | \
   ${REPO_DIR}/scripts/tokenizer.perl -a -q -l en -no-escape > ${OUTPUT_DIR}/newstest2017.ende.tok.en


# filter by length ratio
echo "Filtering by sentence length ratio..."
cp ${REPO_DIR}/programs/LenRatioRemover.class .
java LenRatioRemover ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR}/train.tok.de 2.0 0.4 ${OUTPUT_DIR}/train.tok.en.rm ${OUTPUT_DIR}/train.tok.de.rm ${OUTPUT_DIR_DATA}/train.lenratio.removed
mv ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR_DATA}/train.tok.de
mv ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR_DATA}/train.tok.en
mv ${OUTPUT_DIR}/train.tok.de.rm ${OUTPUT_DIR}/train.tok.de
mv ${OUTPUT_DIR}/train.tok.en.rm ${OUTPUT_DIR}/train.tok.en
rm ./LenRatioRemover.class

# filter ugly sentences
echo "Filtering ugly sentences..."
cp ${REPO_DIR}/programs/SpecialSentRemoverENDE.class .
java SpecialSentRemoverENDE ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR}/train.tok.en.rm ${OUTPUT_DIR}/train.tok.de.rm ${OUTPUT_DIR_DATA}/train.special.removed
mv ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR_DATA}/train.tok.de.lenrm
mv ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR_DATA}/train.tok.en.lenrm
mv ${OUTPUT_DIR}/train.tok.de.rm ${OUTPUT_DIR}/train.tok.de
mv ${OUTPUT_DIR}/train.tok.en.rm ${OUTPUT_DIR}/train.tok.en
rm ./SpecialSentRemoverENDE.class

cp ${REPO_DIR}/programs/MergeAndSplit.class ./
java MergeAndSplit merge ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR}/merged
mv ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR_DATA}/train.tok.de.sprm
mv ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR_DATA}/train.tok.en.sprm
echo "Sorting and removing duplicated sentences..."
sort -u ${OUTPUT_DIR}/merged > ${OUTPUT_DIR}/merged.sort

java MergeAndSplit split ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR}/merged.sort
rm ${OUTPUT_DIR}/merged.sort ./MergeAndSplit.class ${OUTPUT_DIR}/merged

# the files are already cleaned, we only need to learn BPE
echo "Learning BPE with merge_ops=${MERGE_OPS}. This may take a while..."
${REPO_DIR}/bpe/learn_joint_bpe_and_vocab.py -i ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR}/train.tok.en \
    --write-vocabulary ${OUTPUT_DIR}/vocab.de ${OUTPUT_DIR}/vocab.en -s ${MERGE_OPS} -o ${OUTPUT_DIR}/bpe.${MERGE_OPS}

echo "Apply bpe..."
python ${REPO_DIR}/bpe/apply_bpe.py -c ${OUTPUT_DIR}/bpe.${MERGE_OPS} --vocabulary ${OUTPUT_DIR}/vocab.de --vocabulary-threshold ${BPE_THRESHOLD} \
    --input ${OUTPUT_DIR}/train.tok.de --output ${OUTPUT_DIR}/train.tok.bpe90k.de

python ${REPO_DIR}/bpe/apply_bpe.py -c ${OUTPUT_DIR}/bpe.${MERGE_OPS} --vocabulary ${OUTPUT_DIR}/vocab.en --vocabulary-threshold ${BPE_THRESHOLD} \
    --input ${OUTPUT_DIR}/train.tok.en --output ${OUTPUT_DIR}/train.tok.bpe90k.en

echo "Generate vocabulary..."
python ${REPO_DIR}/bpe/generate_vocab.py ${OUTPUT_DIR}/train.tok.bpe90k.de > ${OUTPUT_DIR}/vocab.bpe90k.all.de
python ${REPO_DIR}/bpe/generate_vocab.py ${OUTPUT_DIR}/train.tok.bpe90k.en > ${OUTPUT_DIR}/vocab.bpe90k.all.en

echo "shuffling data..."
python ${REPO_DIR}/scripts/shuffle.py ${OUTPUT_DIR}/train.tok.de,${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR}/train.tok.de.shuf,${OUTPUT_DIR}/train.tok.en.shuf

rm -r ${OUTPUT_DIR_DATA}

echo "All done."