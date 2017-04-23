# This test looks for a rejection because the subject line is
# blacklisted.  The multiple config-dir files should add their
# blacklist files so they are all checked.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com
TO_USER=recipient-${TEST_NUM}.${RANDOM}.${RANDOM}
TO_ADDRESS=${TO_USER}@example.com

mkdir -p ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com
echo "header-blacklist-file=${TMPDIR}/${TEST_NUM}-blacklist_1.txt" >> ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example
echo "Subject: bar" >> ${TMPDIR}/${TEST_NUM}-blacklist_1.txt
mkdir -p ${TMPDIR}/${TEST_NUM}-config.d/_recipient_/com/example/_at_
echo "header-blacklist-file= ${TMPDIR}/${TEST_NUM}-blacklist_2.txt" >> ${TMPDIR}/${TEST_NUM}-config.d/_recipient_/com/example/_at_/${TO_USER}
echo "Subject:      FOO!" >> ${TMPDIR}/${TEST_NUM}-blacklist_2.txt

cat input.txt | sed -e "s/TARGET_EMAIL_1/$1/g" -e "s/TARGET_EMAIL_2/${TO_ADDRESS}/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 554 -- ${SPAMDYKE_PATH} --config-dir ${TMPDIR}/${TEST_NUM}-config.d ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -r 554 -- ${SPAMDYKE_PATH} --config-dir ${TMPDIR}/${TEST_NUM}-config.d ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "554 Refused. Your message has been blocked due to its content." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
