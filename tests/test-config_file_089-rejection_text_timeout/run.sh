# This test looks for a rejection when the remote client takes too long to
# deliver the entire message (absolute timeout).

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

echo rejection-text-timeout=Foo Bar Baz >> ${TMPDIR}/${TEST_NUM}-config.txt
echo idle-timeout-secs=5 >> ${TMPDIR}/${TEST_NUM}-config.txt

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 120 -r 421 -w 10 -- ${SPAMDYKE_PATH} -f ${TMPDIR}/${TEST_NUM}-config.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 120 -r 421 -w 10 -- ${SPAMDYKE_PATH} -f ${TMPDIR}/${TEST_NUM}-config.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep "421 Foo Bar Baz" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  output=`grep "421 Timeout. Talk faster next time." ${TMPDIR}/${TEST_NUM}-output.txt`
  if [ -z "${output}" ] 
  then
    outcome="success"
  else
    echo Filter failure - tmp/${TEST_NUM}-output.txt:
    cat ${TMPDIR}/${TEST_NUM}-output.txt

    outcome="failure"
  fi
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
