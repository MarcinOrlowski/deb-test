# This test looks for whitelisting because the incoming IP address' rDNS name
# contains the IP address and a whitelisted keyword

export TCPREMOTEIP=$TESTSD_IP_IN_RDNS_KEYWORD_IP
echo ${TESTSD_IP_IN_RDNS_KEYWORD} > ${TMPDIR}/${TEST_NUM}-rdns_keywords.txt

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" -e "s/TEST_NUM/${TEST_NUM}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 221 -w 0 -- ${SPAMDYKE_PATH} -e 10 --ip-in-rdns-keyword-whitelist-file ${TMPDIR}/${TEST_NUM}-rdns_keywords.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 221 -w 0 -- ${SPAMDYKE_PATH} -e 10 --ip-in-rdns-keyword-whitelist-file ${TMPDIR}/${TEST_NUM}-rdns_keywords.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep -E "250 ok [0-9]* qp [0-9]*" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
