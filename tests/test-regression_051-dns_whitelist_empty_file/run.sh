# This test tries to use an empty DNS RWL file and looks for a segfault.

export TCPREMOTEIP=11.22.33.44

cp input.txt ${TMPDIR}/${TEST_NUM}-input.txt
touch ${TMPDIR}/${TEST_NUM}-dns_whitelist.txt

echo "${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --dns-whitelist-file ${TMPDIR}/${TEST_NUM}-dns_whitelist.txt --log-target stderr ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --dns-whitelist-file ${TMPDIR}/${TEST_NUM}-dns_whitelist.txt --log-target stderr ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "221" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
