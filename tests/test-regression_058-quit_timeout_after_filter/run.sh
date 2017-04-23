# This test triggers a post-RCPT filter, then quits and looks for a hang and
# timeout message.

export TCPREMOTEIP=${TESTSD_UNRESOLVABLE_RDNS_IP}

cp input.txt ${TMPDIR}/${TEST_NUM}-input.txt

echo "${SENDRECV_PATH} -t 30 -- ${SPAMDYKE_PATH} -T 10 --log-target stderr -R --local-domains-entry foo.com --recipient-whitelist-entry user@foo.com ${SMTPDUMMY_PATH} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -- ${SPAMDYKE_PATH} -T 10 --log-target stderr -R --local-domains-entry foo.com --recipient-whitelist-entry user@foo.com ${SMTPDUMMY_PATH} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "421 Timeout. Talk faster next time." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ -z "${output}" ]
then
  outcome="success"
else
  echo OUTPUT IN tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
