# This test looks for a rejection because the remote server requests
# an unsupported authentication method.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --rejection-text-auth-unknown \"Foo Bar Baz\" --smtp-auth-level always --smtp-auth-command \"${EXITVALUE_PATH} 0\" ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --rejection-text-auth-unknown "Foo Bar Baz" --smtp-auth-level always --smtp-auth-command "${EXITVALUE_PATH} 0" ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep "504 Foo Bar Baz" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  output=`grep "504 Refused. Unknown authentication method." ${TMPDIR}/${TEST_NUM}-output.txt`
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
