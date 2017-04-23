# This test looks for a rejection because the incoming rDNS name is on a
# RHSBL that uses TXT records. It checks the client response text and the
# reason code.

export TCPREMOTEIP=11.22.33.44

echo "44.33.22.11.in-addr.arpa PTR NORMAL 0 foo.example.com" > ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "example.com.txt.rhsbl TXT NORMAL 0 Test RHSBL match" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt

NAMESERVER_IP=127.0.0.1:`${DNSDUMMY_PATH} -t 30 -f ${TMPDIR}/${TEST_NUM}-dns_config.txt`

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@foo.bar

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 554 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --dns-server-ip ${NAMESERVER_IP} -X txt.rhsbl ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -r 554 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --dns-server-ip ${NAMESERVER_IP} -X txt.rhsbl ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "554 Refused. Your domain name is listed in the RHSBL at txt.rhsbl: Test RHSBL match" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  output=`grep "reason: txt.rhsbl" ${TMPDIR}/${TEST_NUM}-output.txt`
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
