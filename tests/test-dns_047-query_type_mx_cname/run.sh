# This test does not allow spamdyke to query for A or MX records when trying
# to find an MX, so attempting to find a mail exchanger should fail and a
# rejection should be given.

export TCPREMOTEIP=11.22.33.44

echo "example.com CNAME NORMAL 0 mail.example.com" > ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "mail.example.com A NORMAL 0 11.22.33.44" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt

export NAMESERVER_IP=127.0.0.1:`${DNSDUMMY_PATH} -t 30 -f ${TMPDIR}/${TEST_NUM}-dns_config.txt`

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --dns-server-ip ${NAMESERVER_IP} --dns-query-type-mx cname --local-domains-entry foo.com --reject-missing-sender-mx ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} --dns-server-ip ${NAMESERVER_IP} --dns-query-type-mx cname --local-domains-entry foo.com --reject-missing-sender-mx ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep "421 Refused. The domain of your sender address has no mail exchanger (MX)." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
