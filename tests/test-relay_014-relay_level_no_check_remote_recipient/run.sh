# This test attempts to deliver a message to a remote recipient when the
# "relay-level" option is "no-check".

export TCPREMOTEIP=11.22.33.44

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com
TO_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

echo $1 | sed -e "s/[^@]*@//" > ${TMPDIR}/${TEST_NUM}-local_domains.txt

cat input.txt | sed -e "s/TEST_NUM/${TEST_NUM}/g" -e "s/TARGET_EMAIL/${TO_ADDRESS}/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --relay-level no-check -d ${TMPDIR}/${TEST_NUM}-local_domains.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --relay-level no-check -d ${TMPDIR}/${TEST_NUM}-local_domains.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep "553 sorry, that domain isn't in my list of allowed rcpthosts (#5.7.1)" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
