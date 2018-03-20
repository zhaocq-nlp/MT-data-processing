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
mkdir ${OUTPUT_DIR}/dev
mkdir ${OUTPUT_DIR}/test

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

echo "Downloading truecase model..."
curl -o ${OUTPUT_DIR_DATA}/true.tgz \
    http://data.statmt.org/wmt17/translation-task/preprocessed/de-en/true.tgz

echo "Extracting all files..."
gzip -d ${OUTPUT_DIR_DATA}/corpus.tc.de.gz
gzip -d ${OUTPUT_DIR_DATA}/corpus.tc.en.gz
mkdir -p "${OUTPUT_DIR_DATA}/dev"
tar -zxvf ${OUTPUT_DIR_DATA}/dev.tgz -C "${OUTPUT_DIR_DATA}/dev"
tar -zxvf ${OUTPUT_DIR_DATA}/test.tgz -C "${OUTPUT_DIR_DATA}/"
tar -zxvf ${OUTPUT_DIR_DATA}/true.tgz -C "${OUTPUT_DIR_DATA}/"

# recover special fields
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/corpus.tc.de > ${OUTPUT_DIR}/train.tok.tc.de
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/corpus.tc.en > ${OUTPUT_DIR}/train.tok.tc.en

# use newstest2016 as dev set
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/dev/newstest2016.tc.en > ${OUTPUT_DIR}/dev.tok.tc.en
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/dev/newstest2016.tc.de > ${OUTPUT_DIR}/dev.tok.tc.de

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

cp ${OUTPUT_DIR_DATA}/dev/newstest2016-deen* ${OUTPUT_DIR}/dev/
cp ${OUTPUT_DIR_DATA}/dev/newstest2016-ende* ${OUTPUT_DIR}/dev/
cp ${OUTPUT_DIR_DATA}/test/newstest2017-deen* ${OUTPUT_DIR}/test/
cp ${OUTPUT_DIR_DATA}/test/newstest2017-ende* ${OUTPUT_DIR}/test/

# tokenize
echo "Tokenize..."
cat ${OUTPUT_DIR_DATA}/test/newstest2017.deen.de | \
   ${REPO_DIR}/scripts/normalize-punctuation.perl -l de | \
   ${REPO_DIR}/scripts/tokenizer.perl -a -q -l de -no-escape | \
   ${REPO_DIR}/scripts/truecase.perl -model ${OUTPUT_DIR_DATA}/truecase-model.de > ${OUTPUT_DIR}/newstest2017.deen.tok.tc.de

cat ${OUTPUT_DIR_DATA}/test/newstest2017.deen.en | \
   ${REPO_DIR}/scripts/normalize-punctuation.perl -l en | \
   ${REPO_DIR}/scripts/tokenizer.perl -a -q -l en -no-escape | \
   ${REPO_DIR}/scripts/truecase.perl -model ${OUTPUT_DIR_DATA}/truecase-model.en > ${OUTPUT_DIR}/newstest2017.deen.tok.tc.en

cat ${OUTPUT_DIR_DATA}/test/newstest2017.ende.de | \
   ${REPO_DIR}/scripts/normalize-punctuation.perl -l de | \
   ${REPO_DIR}/scripts/tokenizer.perl -a -q -l de -no-escape | \
   ${REPO_DIR}/scripts/truecase.perl -model ${OUTPUT_DIR_DATA}/truecase-model.de > ${OUTPUT_DIR}/newstest2017.ende.tok.tc.de

cat ${OUTPUT_DIR_DATA}/test/newstest2017.ende.en | \
   ${REPO_DIR}/scripts/normalize-punctuation.perl -l en | \
   ${REPO_DIR}/scripts/tokenizer.perl -a -q -l en -no-escape | \
   ${REPO_DIR}/scripts/truecase.perl -model ${OUTPUT_DIR_DATA}/truecase-model.en > ${OUTPUT_DIR}/newstest2017.ende.tok.tc.en

# filter by length ratio
echo "Filtering by sentence length ratio..."
cp ${REPO_DIR}/programs/LenRatioRemover.class .
java LenRatioRemover ${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR}/train.tok.tc.de 2.0 0.4 ${OUTPUT_DIR}/train.tok.tc.en.rm ${OUTPUT_DIR}/train.tok.tc.de.rm ${OUTPUT_DIR_DATA}/train.lenratio.removed
mv ${OUTPUT_DIR}/train.tok.tc.de ${OUTPUT_DIR_DATA}/train.tok.tc.de
mv ${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR_DATA}/train.tok.tc.en
mv ${OUTPUT_DIR}/train.tok.tc.de.rm ${OUTPUT_DIR}/train.tok.tc.de
mv ${OUTPUT_DIR}/train.tok.tc.en.rm ${OUTPUT_DIR}/train.tok.tc.en
rm ./LenRatioRemover.class

# filter ugly sentences
echo "Filtering ugly sentences..."
cp ${REPO_DIR}/programs/SpecialSentRemoverENDE.class .
java SpecialSentRemoverENDE ${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR}/train.tok.tc.de ${OUTPUT_DIR}/train.tok.tc.en.rm ${OUTPUT_DIR}/train.tok.tc.de.rm ${OUTPUT_DIR_DATA}/train.special.removed
mv ${OUTPUT_DIR}/train.tok.tc.de ${OUTPUT_DIR_DATA}/train.tok.tc.de.lenrm
mv ${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR_DATA}/train.tok.tc.en.lenrm
mv ${OUTPUT_DIR}/train.tok.tc.de.rm ${OUTPUT_DIR}/train.tok.tc.de
mv ${OUTPUT_DIR}/train.tok.tc.en.rm ${OUTPUT_DIR}/train.tok.tc.en
rm ./SpecialSentRemoverENDE.class

cp ${REPO_DIR}/programs/MergeAndSplit.class ./
java MergeAndSplit merge ${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR}/train.tok.tc.de ${OUTPUT_DIR}/merged
mv ${OUTPUT_DIR}/train.tok.tc.de ${OUTPUT_DIR_DATA}/train.tok.tc.de.sprm
mv ${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR_DATA}/train.tok.tc.en.sprm
echo "Sorting and removing duplicated sentences..."
sort -u ${OUTPUT_DIR}/merged > ${OUTPUT_DIR}/merged.sort

java MergeAndSplit split ${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR}/train.tok.tc.de ${OUTPUT_DIR}/merged.sort
rm ${OUTPUT_DIR}/merged.sort ./MergeAndSplit.class ${OUTPUT_DIR}/merged

# the files are already cleaned, we only need to learn BPE
echo "Learning BPE with merge_ops=${MERGE_OPS}. This may take a while..."
${REPO_DIR}/bpe/learn_joint_bpe_and_vocab.py -i ${OUTPUT_DIR}/train.tok.tc.de ${OUTPUT_DIR}/train.tok.tc.en \
    --write-vocabulary ${OUTPUT_DIR}/vocab.de ${OUTPUT_DIR}/vocab.en -s ${MERGE_OPS} -o ${OUTPUT_DIR}/bpe.${MERGE_OPS}

echo "Apply bpe..."
python ${REPO_DIR}/bpe/apply_bpe.py -c ${OUTPUT_DIR}/bpe.${MERGE_OPS} --vocabulary ${OUTPUT_DIR}/vocab.de --vocabulary-threshold ${BPE_THRESHOLD} \
    --input ${OUTPUT_DIR}/train.tok.tc.de --output ${OUTPUT_DIR}/train.tok.tc.bpe90k.de

python ${REPO_DIR}/bpe/apply_bpe.py -c ${OUTPUT_DIR}/bpe.${MERGE_OPS} --vocabulary ${OUTPUT_DIR}/vocab.en --vocabulary-threshold ${BPE_THRESHOLD} \
    --input ${OUTPUT_DIR}/train.tok.tc.en --output ${OUTPUT_DIR}/train.tok.tc.bpe90k.en

echo "Generate vocabulary..."
python ${REPO_DIR}/bpe/generate_vocab.py ${OUTPUT_DIR}/train.tok.tc.bpe90k.de > ${OUTPUT_DIR}/vocab.bpe90k.all.de
python ${REPO_DIR}/bpe/generate_vocab.py ${OUTPUT_DIR}/train.tok.tc.bpe90k.en > ${OUTPUT_DIR}/vocab.bpe90k.all.en

echo "shuffling data..."
python ${REPO_DIR}/scripts/shuffle.py ${OUTPUT_DIR}/train.tok.tc.de,${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR}/train.tok.tc.de.shuf,${OUTPUT_DIR}/train.tok.tc.en.shuf

rm -r ${OUTPUT_DIR_DATA}

echo "All done."