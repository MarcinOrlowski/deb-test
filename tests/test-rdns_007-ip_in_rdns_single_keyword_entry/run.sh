# This test looks for a rejection because the incoming IP address' rDNS name
# contains the IP address and a banned keyword and checks the reason is correct.

export TCPREMOTEIP=$TESTSD_IP_IN_RDNS_KEYWORD_IP

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com
CONVERTED_KEYWORD=`echo ${TESTSD_IP_IN_RDNS_KEYWORD} | sed -e "s/ /_/g"`

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --ip-in-rdns-keyword-blacklist-entry "${TESTSD_IP_IN_RDNS_KEYWORD}" ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --ip-in-rdns-keyword-blacklist-entry "${TESTSD_IP_IN_RDNS_KEYWORD}" ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "554 Refused. Your reverse DNS entry contains your IP address and a banned keyword." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  output=`grep "reason: ${CONVERTED_KEYWORD}" ${TMPDIR}/${TEST_NUM}-output.txt`
  if [ ! -z "${output}" ]
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
