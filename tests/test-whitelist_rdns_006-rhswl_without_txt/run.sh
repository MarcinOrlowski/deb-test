# This test looks for a rejection because the incoming rDNS name is listed in a
# RHSWL that uses A records.

export TCPREMOTEIP=11.22.33.44

echo "44.33.22.11.in-addr.arpa PTR NORMAL 0 foo.example.com" > ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "example.com.a.rhswl A NORMAL 0 127.0.0.1" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt

NAMESERVER_IP=127.0.0.1:`${DNSDUMMY_PATH} -t 30 -f ${TMPDIR}/${TEST_NUM}-dns_config.txt`

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@foo.bar

cat input.txt | sed -e "s/TEST_NUM/${TEST_NUM}/g" -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 221 -d 0 -- ${SPAMDYKE_PATH} -e 10 --dns-server-ip ${NAMESERVER_IP} --rhs-whitelist-entry a.rhswl ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 221 -d 0 -- ${SPAMDYKE_PATH} -e 10 --dns-server-ip ${NAMESERVER_IP} --rhs-whitelist-entry a.rhswl ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep -E "250 ok [0-9]* qp [0-9]*" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
