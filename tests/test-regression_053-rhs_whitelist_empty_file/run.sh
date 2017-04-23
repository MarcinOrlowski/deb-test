# This test tries to use an empty RHS RWL file and looks for a segfault.

export TCPREMOTEIP=${TESTSD_RDNS_IP}

cp input.txt ${TMPDIR}/${TEST_NUM}-input.txt
touch ${TMPDIR}/${TEST_NUM}-rhs_whitelist.txt

echo "${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --rhs-whitelist-file ${TMPDIR}/${TEST_NUM}-rhs_whitelist.txt --log-target stderr ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --rhs-whitelist-file ${TMPDIR}/${TEST_NUM}-rhs_whitelist.txt --log-target stderr ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "221" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
