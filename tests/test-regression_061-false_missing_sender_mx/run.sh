# This test looks for a false positive from the sender MX filter when
# the sender's MX record has both an MX and an A record associated
# with it and the MX response is returned first.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@foo.example.com

echo "foo.example.com MX NORMAL 0 bar.example.com" > ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "bar.example.com MX NORMAL 0 bar.example.com" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "bar.example.com A NORMAL 1 11.22.33.44" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt

NAMESERVER_IP=127.0.0.1:`${DNSDUMMY_PATH} -t 30 -f ${TMPDIR}/${TEST_NUM}-dns_config.txt`

touch ${TMPDIR}/${TEST_NUM}-local_domains.txt

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} --reject-missing-sender-mx --local-domains-file ${TMPDIR}/${TEST_NUM}-local_domains.txt --dns-server-ip ${NAMESERVER_IP} ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} --reject-missing-sender-mx --local-domains-file ${TMPDIR}/${TEST_NUM}-local_domains.txt --dns-server-ip ${NAMESERVER_IP} ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep "421 Refused. The domain of your sender address has no mail exchanger (MX)." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
