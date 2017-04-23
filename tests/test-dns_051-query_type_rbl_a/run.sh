# This test does not allow spamdyke to query for CNAME or TXT records when trying
# to lookup a DNS RBL, so trying to find the whitelist entry should fail.

export TCPREMOTEIP=11.22.33.44

echo "44.33.22.11.test.rwl TXT NORMAL 0 Some text." > ${TMPDIR}/${TEST_NUM}-dns_config.txt

export NAMESERVER_IP=127.0.0.1:`${DNSDUMMY_PATH} -t 30 -f ${TMPDIR}/${TEST_NUM}-dns_config.txt`

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 554 -- ${SPAMDYKE_PATH} --dns-server-ip ${NAMESERVER_IP} --dns-whitelist-entry test.rwl --ip-blacklist-entry ${TESTSD_MISSING_RDNS_IP}/0 --dns-query-type-rbl a ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 554 -- ${SPAMDYKE_PATH} --dns-server-ip ${NAMESERVER_IP} --dns-whitelist-entry test.rwl --ip-blacklist-entry ${TESTSD_MISSING_RDNS_IP}/0 --dns-query-type-rbl a ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep "554 Refused. Your IP address is blacklisted." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
