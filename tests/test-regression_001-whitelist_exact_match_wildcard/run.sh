# This test looks for a rejection when the incoming rDNS name is in
# whitelist_rdns.txt with a wildcard.

export TCPREMOTEIP=${TESTSD_UNRESOLVABLE_RDNS_IP}

echo .`${DNSPTR_PATH} ${TESTSD_UNRESOLVABLE_RDNS_IP}` > ${TMPDIR}/${TEST_NUM}-whitelist_rdns.txt

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input.txt | sed -e "s/TEST_NUM/${TEST_NUM}/" -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} -R -w ${TMPDIR}/${TEST_NUM}-whitelist_rdns.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} -R -w ${TMPDIR}/${TEST_NUM}-whitelist_rdns.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep -E "250 ok [0-9]* qp [0-9]*" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
