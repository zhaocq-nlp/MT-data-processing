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

OUTPUT_DIR="${1:-wmt18_zh_en}"

MERGE_OPS=60000
BPE_THRESHOLD=50

echo "Writing to ${OUTPUT_DIR}. To change this, set the OUTPUT_DIR environment variable."

OUTPUT_DIR_DATA="${OUTPUT_DIR}/data"
mkdir -p $OUTPUT_DIR_DATA

echo "Downloading preprocessed data. This may take a while..."
curl -o ${OUTPUT_DIR_DATA}/corpus.gz \
    http://data.statmt.org/wmt18/translation-task/preprocessed/zh-en/corpus.gz

echo "Downloading preprocessed dev data..."
curl -o ${OUTPUT_DIR_DATA}/dev.tgz \
    http://data.statmt.org/wmt18/translation-task/preprocessed/zh-en/dev.tgz

echo "Downloading test data..."
# curl -o ${OUTPUT_DIR_DATA}/test.tgz \
#    http://data.statmt.org/wmt18/translation-task/test.tgz

echo "Extracting all files..."
gzip -d ${OUTPUT_DIR_DATA}/corpus.tc.de.gz
gzip -d ${OUTPUT_DIR_DATA}/corpus.tc.en.gz
mkdir -p "${OUTPUT_DIR_DATA}/dev"
tar -zxvf ${OUTPUT_DIR_DATA}/dev.tgz -C "${OUTPUT_DIR_DATA}/dev"
tar -zxvf ${OUTPUT_DIR_DATA}/test.tgz -C "${OUTPUT_DIR_DATA}/"

# recover special fields
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/corpus > ${OUTPUT_DIR}/train.tok

# use newsdev2017 as dev set
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/dev/newsdev2017.tc.en > ${OUTPUT_DIR}/dev.tok.en
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/dev/newsdev2017.tc.zh > ${OUTPUT_DIR}/dev.tok.zh
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/dev/newstest2017.tc.en > ${OUTPUT_DIR}/newstest2017.tok.en
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/dev/newstest2017.tc.zh > ${OUTPUT_DIR}/newstest2017.tok.zh


cp ${REPO_DIR}/programs/SplitChineseFile.class .
java SplitChineseFile ${OUTPUT_DIR}/train.tok ${OUTPUT_DIR}/train.tok.zh ${OUTPUT_DIR}/train.tok.en
rm ./SplitChineseFile.class ${OUTPUT_DIR}/train.tok

exit



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
cp ${REPO_DIR}/programs/SpecialSentRemover.class .
java SpecialSentRemover ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR}/train.tok.en.rm ${OUTPUT_DIR}/train.tok.de.rm ${OUTPUT_DIR_DATA}/train.special.removed
mv ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR_DATA}/train.tok.de.lenrm
mv ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR_DATA}/train.tok.en.lenrm
mv ${OUTPUT_DIR}/train.tok.de.rm ${OUTPUT_DIR}/train.tok.de
mv ${OUTPUT_DIR}/train.tok.en.rm ${OUTPUT_DIR}/train.tok.en
rm ./SpecialSentRemover.class

cp ${REPO_DIR}/programs/MergeAndSplit.class ./
java MergeAndSplit merge ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR}/merged
mv ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR_DATA}/train.tok.de.sprm
mv ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR_DATA}/train.tok.en.sprm
echo "Sorting and removing duplicated sentences..."
sort -u ${OUTPUT_DIR}/merged > ${OUTPUT_DIR}/merged.sort

java MergeAndSplit split ${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR}/train.tok.de ${OUTPUT_DIR}/merged.sort
rm ${OUTPUT_DIR}/merged.sort ./MergeAndSplit.class ${OUTPUT_DIR}/merge

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
python ${REPO_DIR}/bpe/generate_vocab.py ${OUTPUT_DIR}/train.tok.bpe90k.de --min_frequency ${BPE_THRESHOLD} > ${OUTPUT_DIR}/vocab.bpe90k.de
python ${REPO_DIR}/bpe/generate_vocab.py ${OUTPUT_DIR}/train.tok.bpe90k.en --min_frequency ${BPE_THRESHOLD} > ${OUTPUT_DIR}/vocab.bpe90k.en

echo "shuffling data..."
python ${REPO_DIR}/scripts/shuffle.py ${OUTPUT_DIR}/train.tok.de,${OUTPUT_DIR}/train.tok.en ${OUTPUT_DIR}/train.tok.de.shuf,${OUTPUT_DIR}/train.tok.en.shuf

rm -r ${OUTPUT_DIR_DATA}

echo "All done."