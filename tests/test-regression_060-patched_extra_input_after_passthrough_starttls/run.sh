# This test sends more than one command in a single packet with STARTTLS, then
# checks if spamdyke passed through the second command as though it were sent
# after TLS was started.

cp input.txt ${TMPDIR}/${TEST_NUM}-input.txt

echo "${SENDRECV_PATH} -r 221 -t 60 -- ${SPAMDYKE_PATH} --log-target stderr --tls-level smtp ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -r 221 -t 60 -- ${SPAMDYKE_PATH} --log-target stderr --tls-level smtp ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "250 flushed" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ -z "${output}" ]
then
  output=`grep -E "^221 " ${TMPDIR}/${TEST_NUM}-output.txt`
  if [ ! -z "${output}" ]
  then
    outcome="success"
  else
    echo OUTPUT IN tmp/${TEST_NUM}-output.txt:
    cat ${TMPDIR}/${TEST_NUM}-output.txt

    outcome="failure"
  fi
else
  echo OUTPUT IN tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
