# This test looks for a rejection when the remote server is not allowed to
# connect.

export TCPREMOTEIP=10.64.128.255

echo "10.64.128.255:deny" > ${TMPDIR}/${TEST_NUM}-access.txt
echo ":allow" >> ${TMPDIR}/${TEST_NUM}-access.txt

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

touch ${TMPDIR}/${TEST_NUM}-local_domains.txt

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 554 -- ${SPAMDYKE_PATH} --rejection-text-access-denied \"Foo Bar Baz\" --access-file ${TMPDIR}/${TEST_NUM}-access.txt -d ${TMPDIR}/${TEST_NUM}-local_domains.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 554 -- ${SPAMDYKE_PATH} --rejection-text-access-denied "Foo Bar Baz" --access-file ${TMPDIR}/${TEST_NUM}-access.txt -d ${TMPDIR}/${TEST_NUM}-local_domains.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep "554 Foo Bar Baz" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  output=`grep "554 Refused. Access is denied." ${TMPDIR}/${TEST_NUM}-output.txt`
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
