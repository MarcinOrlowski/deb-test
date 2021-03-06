# This test looks for success when the blacklisted domain name does
# not quite match the sender's domain name.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

echo @notexample.com > ${TMPDIR}/${TEST_NUM}-sender_blacklist.txt

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} -s ${TMPDIR}/${TEST_NUM}-sender_blacklist.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} -s ${TMPDIR}/${TEST_NUM}-sender_blacklist.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep -E "554 Refused. Your sender address has been blacklisted." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
