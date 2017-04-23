# This test checks if spamdyke will skip graylisting for remote senders whose
# IPs are listed in the "graywhitelist" file.

export TCPREMOTEIP=11.22.33.44

echo 11.22.33.44 > ${TMPDIR}/${TEST_NUM}-graywhitelist_ip.txt

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

mkdir -p ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com
echo "graylist-dir=${TMPDIR}/${TEST_NUM}-graylist.d" > ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example
echo "graylist-exception-ip-file=${TMPDIR}/${TEST_NUM}-graywhitelist_ip.txt" >> ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example

mkdir -p ${TMPDIR}/${TEST_NUM}-graylist.d/`echo $1 | sed -e "s/[^@]*@//" | awk '{ print tolower($1) }'`

cat input.txt | sed -e "s/TEST_NUM/${TEST_NUM}/g" -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --config-dir ${TMPDIR}/${TEST_NUM}-config.d ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --config-dir ${TMPDIR}/${TEST_NUM}-config.d ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep -E "250 ok [0-9]* qp [0-9]*" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo OUTPUT IN tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
