# This test sets the policy URL, then tries to unset it to check that mismatches
# have no effect.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

echo policy-url=foobarbazqux >> ${TMPDIR}/${TEST_NUM}-config.txt
echo policy-url=!foobar >> ${TMPDIR}/${TEST_NUM}-config.txt
echo reject-empty-rdns >> ${TMPDIR}/${TEST_NUM}-config.txt

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} -f ${TMPDIR}/${TEST_NUM}-config.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} -f ${TMPDIR}/${TEST_NUM}-config.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep "421 Refused. You have no reverse DNS entry. See: foobarbazqux#DENIED_RDNS_MISSING" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
