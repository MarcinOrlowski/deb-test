# This test looks for a success message because the incoming IP address is on a
# DNS RBL that uses A records but the records are chained with CNAMEs and
# exceed the lookup limit.

export TCPREMOTEIP=11.22.33.44

echo "44.33.22.11.chained.a CNAME NORMAL 0 1.44.33.22.11.chained.a" > ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "1.44.33.22.11.chained.a CNAME NORMAL 0 2.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "2.44.33.22.11.chained.a CNAME NORMAL 0 3.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "3.44.33.22.11.chained.a CNAME NORMAL 0 4.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "4.44.33.22.11.chained.a CNAME NORMAL 0 5.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "5.44.33.22.11.chained.a CNAME NORMAL 0 6.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "6.44.33.22.11.chained.a CNAME NORMAL 0 7.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "7.44.33.22.11.chained.a CNAME NORMAL 0 8.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "8.44.33.22.11.chained.a CNAME NORMAL 0 9.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "9.44.33.22.11.chained.a CNAME NORMAL 0 10.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "10.44.33.22.11.chained.a CNAME NORMAL 0 11.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "11.44.33.22.11.chained.a CNAME NORMAL 0 12.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "12.44.33.22.11.chained.a CNAME NORMAL 0 13.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "13.44.33.22.11.chained.a CNAME NORMAL 0 14.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "14.44.33.22.11.chained.a CNAME NORMAL 0 15.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "15.44.33.22.11.chained.a CNAME NORMAL 0 16.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "16.44.33.22.11.chained.a CNAME NORMAL 0 17.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "17.44.33.22.11.chained.a CNAME NORMAL 0 18.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "18.44.33.22.11.chained.a CNAME NORMAL 0 19.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "19.44.33.22.11.chained.a CNAME NORMAL 0 20.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "20.44.33.22.11.chained.a CNAME NORMAL 0 21.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "21.44.33.22.11.chained.a CNAME NORMAL 0 22.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "22.44.33.22.11.chained.a CNAME NORMAL 0 23.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "23.44.33.22.11.chained.a CNAME NORMAL 0 24.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "24.44.33.22.11.chained.a CNAME NORMAL 0 25.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "25.44.33.22.11.chained.a CNAME NORMAL 0 26.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "26.44.33.22.11.chained.a CNAME NORMAL 0 27.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "27.44.33.22.11.chained.a CNAME NORMAL 0 28.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "28.44.33.22.11.chained.a CNAME NORMAL 0 29.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "29.44.33.22.11.chained.a CNAME NORMAL 0 30.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "30.44.33.22.11.chained.a CNAME NORMAL 0 31.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "31.44.33.22.11.chained.a CNAME NORMAL 0 32.44.33.22.11.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "32.44.33.22.11.chained.a TXT NORMAL 0 Test RHSBL match" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt

NAMESERVER_IP=127.0.0.1:`${DNSDUMMY_PATH} -t 180 -f ${TMPDIR}/${TEST_NUM}-dns_config.txt`

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input.txt | sed -e "s/TEST_NUM/${TEST_NUM}/g" -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 180 -r 221 -- ${SPAMDYKE_PATH} --dns-server-ip ${NAMESERVER_IP} -x chained.a ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 180 -r 221 -- ${SPAMDYKE_PATH} --dns-server-ip ${NAMESERVER_IP} -x chained.a ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep -E "250 ok [0-9]* qp [0-9]*" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
