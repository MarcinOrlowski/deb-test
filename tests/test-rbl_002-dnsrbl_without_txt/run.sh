# This test looks for a rejection because the incoming IP address is on a
# DNS RBL that uses A records (not TXT). It checks the client response text
# and the reason code.

export TCPREMOTEIP=11.22.33.44

echo "44.33.22.11.a.dnsrbl A NORMAL 0 127.0.0.1" > ${TMPDIR}/${TEST_NUM}-dns_config.txt

export NAMESERVER_IP=127.0.0.1:`${DNSDUMMY_PATH} -t 30 -f ${TMPDIR}/${TEST_NUM}-dns_config.txt`

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 554 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --dns-server-ip ${NAMESERVER_IP} -x a.dnsrbl ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -r 554 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --dns-server-ip ${NAMESERVER_IP} -x a.dnsrbl ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "554 Refused. Your IP address is listed in the RBL at a.dnsrbl" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  output=`grep "reason: a.dnsrbl" ${TMPDIR}/${TEST_NUM}-output.txt`
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
