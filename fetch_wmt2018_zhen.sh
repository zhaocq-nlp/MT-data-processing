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
#tar -zxvf ${OUTPUT_DIR_DATA}/test.tgz -C "${OUTPUT_DIR_DATA}/"

mkdir ${OUTPUT_DIR}/dev
cp ${OUTPUT_DIR_DATA}/dev/newsdev2017-zhen* ${OUTPUT_DIR}/dev/
cp ${OUTPUT_DIR_DATA}/dev/newsdev2017-enzh* ${OUTPUT_DIR}/dev/
cp ${OUTPUT_DIR_DATA}/dev/newstest2017-zhen* ${OUTPUT_DIR}/dev/
cp ${OUTPUT_DIR_DATA}/dev/newstest2017-enzh* ${OUTPUT_DIR}/dev/

cp ${REPO_DIR}/programs/SplitChineseFile.class .
java SplitChineseFile ${OUTPUT_DIR_DATA}/corpus ${OUTPUT_DIR_DATA}/corpus.zh ${OUTPUT_DIR_DATA}/corpus.en
rm ./SplitChineseFile.class

# recover special fields
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/corpus.en > ${OUTPUT_DIR}/train.tok.tc.en
sed 's/& amp ;/\&/g' ${OUTPUT_DIR}/train.tok.tc.en > ${OUTPUT_DIR}/train.tok.tc.en.tmp
sed 's/& lt ;/\</g' ${OUTPUT_DIR}/train.tok.tc.en.tmp > ${OUTPUT_DIR}/train.tok.tc.en.tmptmp
mv ${OUTPUT_DIR}/train.tok.tc.en.tmptmp ${OUTPUT_DIR}/train.tok.tc.en.tmp
sed 's/& gt ;/\>/g' ${OUTPUT_DIR}/train.tok.tc.en.tmp > ${OUTPUT_DIR}/train.tok.tc.en.tmptmp
mv ${OUTPUT_DIR}/train.tok.tc.en.tmptmp ${OUTPUT_DIR}/train.tok.tc.en.tmp
sed 's/& quot ;/\"/g' ${OUTPUT_DIR}/train.tok.tc.en.tmp > ${OUTPUT_DIR}/train.tok.tc.en.tmptmp
mv ${OUTPUT_DIR}/train.tok.tc.en.tmptmp ${OUTPUT_DIR}/train.tok.tc.en.tmp
sed "s/& apos ; s /\'s /g" ${OUTPUT_DIR}/train.tok.tc.en.tmp > ${OUTPUT_DIR}/train.tok.tc.en.tmptmp
mv ${OUTPUT_DIR}/train.tok.tc.en.tmptmp ${OUTPUT_DIR}/train.tok.tc.en.tmp
sed "s/& apos ;/\'/g" ${OUTPUT_DIR}/train.tok.tc.en.tmp > ${OUTPUT_DIR}/train.tok.tc.en.tmptmp
mv ${OUTPUT_DIR}/train.tok.tc.en.tmptmp ${OUTPUT_DIR}/train.tok.tc.en.tmp
sed 's/& amp ;/\&/g' ${OUTPUT_DIR}/train.tok.tc.en.tmp > ${OUTPUT_DIR}/train.tok.tc.en
rm ${OUTPUT_DIR}/train.tok.tc.en.tmp

# use newsdev2017 as dev set
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/dev/newsdev2017.tc.en > ${OUTPUT_DIR}/newsdev2017.tok.tc.en
perl ${REPO_DIR}/scripts/deescape-special-chars.perl < ${OUTPUT_DIR_DATA}/dev/newstest2017.tc.en > ${OUTPUT_DIR}/newstest2017.tok.tc.en

cp ${REPO_DIR}/programs/CleanChineseFile.class .
java CleanChineseFile ${OUTPUT_DIR_DATA}/corpus.zh ${OUTPUT_DIR}/train.tok.zh
java CleanChineseFile ${OUTPUT_DIR_DATA}/dev/newsdev2017.tc.zh ${OUTPUT_DIR}/newsdev2017.tok.zh
java CleanChineseFile ${OUTPUT_DIR_DATA}/dev/newstest2017.tc.zh ${OUTPUT_DIR}/newstest2017.tok.zh
rm ./CleanChineseFile.class

rm ${OUTPUT_DIR_DATA}/corpus*
python ${REPO_DIR}/scripts/tokenizeChinese.py ${OUTPUT_DIR}/train.tok.zh ${OUTPUT_DIR}/train.tok.zh.char

echo "Removing special sentences..."
cp ${REPO_DIR}/programs/ChineseSpecialRemover.class .
java ChineseSpecialRemover ${OUTPUT_DIR}/train.tok.zh ${OUTPUT_DIR}/train.tok.zh.char ${OUTPUT_DIR}/train.tok.tc.en 3.0 0.7 ${OUTPUT_DIR}/train.tok.zh.rm ${OUTPUT_DIR}/train.tok.tc.en.rm ${OUTPUT_DIR_DATA}/train.special.removed
rm ./ChineseSpecialRemover.class ${OUTPUT_DIR}/train.tok.zh.char
mv ${OUTPUT_DIR}/train.tok.zh ${OUTPUT_DIR_DATA}/train.tok.zh
mv ${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR_DATA}/train.tok.tc.en
mv ${OUTPUT_DIR}/train.tok.zh.rm ${OUTPUT_DIR}/train.tok.zh
mv ${OUTPUT_DIR}/train.tok.tc.en.rm ${OUTPUT_DIR}/train.tok.tc.en

# merge
cp ${REPO_DIR}/programs/MergeAndSplit.class ./
java MergeAndSplit merge ${OUTPUT_DIR}/train.tok.zh ${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR}/merged
echo "Sorting and removing duplicated sentences..."
sort -u ${OUTPUT_DIR}/merged > ${OUTPUT_DIR}/merged.sort

java MergeAndSplit split ${OUTPUT_DIR}/train.tok.zh ${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR}/merged.sort
rm ${OUTPUT_DIR}/merged.sort ./MergeAndSplit.class ${OUTPUT_DIR}/merged

# the files are already cleaned, we only need to learn BPE
echo "Learning BPE with merge_ops=${MERGE_OPS}. This may take a while..."
${REPO_DIR}/bpe/learn_joint_bpe_and_vocab.py -i ${OUTPUT_DIR}/train.tok.zh \
    --write-vocabulary ${OUTPUT_DIR}/vocab.zh -s ${MERGE_OPS} -o ${OUTPUT_DIR}/bpe.${MERGE_OPS}.zh
${REPO_DIR}/bpe/learn_joint_bpe_and_vocab.py -i ${OUTPUT_DIR}/train.tok.tc.en \
    --write-vocabulary ${OUTPUT_DIR}/vocab.en -s ${MERGE_OPS} -o ${OUTPUT_DIR}/bpe.${MERGE_OPS}.en

echo "Apply bpe..."
python ${REPO_DIR}/bpe/apply_bpe.py -c ${OUTPUT_DIR}/bpe.${MERGE_OPS}.en --vocabulary ${OUTPUT_DIR}/vocab.en --vocabulary-threshold ${BPE_THRESHOLD} \
    --input ${OUTPUT_DIR}/train.tok.tc.en --output ${OUTPUT_DIR}/train.tok.tc.bpe90k.en

python ${REPO_DIR}/bpe/apply_bpe.py -c ${OUTPUT_DIR}/bpe.${MERGE_OPS}.zh --vocabulary ${OUTPUT_DIR}/vocab.zh --vocabulary-threshold ${BPE_THRESHOLD} \
    --input ${OUTPUT_DIR}/train.tok.zh --output ${OUTPUT_DIR}/train.tok.bpe90k.zh

echo "Generate vocabulary..."
python ${REPO_DIR}/bpe/generate_vocab.py ${OUTPUT_DIR}/train.tok.bpe60k.zh > ${OUTPUT_DIR}/vocab.bpe60k.all.zh
python ${REPO_DIR}/bpe/generate_vocab.py ${OUTPUT_DIR}/train.tok.tc.bpe60k.en > ${OUTPUT_DIR}/vocab.bpe60k.all.en

echo "shuffling data..."
python ${REPO_DIR}/scripts/shuffle.py ${OUTPUT_DIR}/train.tok.zh,${OUTPUT_DIR}/train.tok.tc.en ${OUTPUT_DIR}/train.tok.zh.shuf,${OUTPUT_DIR}/train.tok.tc.en.shuf

rm -r ${OUTPUT_DIR_DATA}

echo "All done."