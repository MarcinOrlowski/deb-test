# This test does not allow spamdyke to query for CNAME records when trying to
# find IP addresses, so trying to resolve the rDNS name should fail.

export TCPREMOTEIP=11.22.33.44

echo "44.33.22.11.in-addr.arpa PTR NORMAL 0 foo.example.com" > ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "foo.example.com CNAME NORMAL 0 bar.example.com" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "bar.example.com A NORMAL 0 11.22.33.44" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt

export NAMESERVER_IP=127.0.0.1:`${DNSDUMMY_PATH} -t 30 -f ${TMPDIR}/${TEST_NUM}-dns_config.txt`

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

echo "dns-query-type-a=a" > ${TMPDIR}/${TEST_NUM}-config.txt

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} --dns-server-ip ${NAMESERVER_IP} -f ${TMPDIR}/${TEST_NUM}-config.txt -R ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} --dns-server-ip ${NAMESERVER_IP} -f ${TMPDIR}/${TEST_NUM}-config.txt -R ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep "421 Refused. Your reverse DNS entry does not resolve." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
