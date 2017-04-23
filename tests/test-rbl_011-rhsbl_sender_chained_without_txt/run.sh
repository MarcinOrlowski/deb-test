# This test looks for a success message because the incoming sender address is
# on a RHSBL that uses A records but the records are chained with CNAMEs and
# exceed the lookup limit.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

echo "example.com.chained.a CNAME NORMAL 0 1.example.com.chained.a" > ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "1.example.com.chained.a CNAME NORMAL 0 2.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "2.example.com.chained.a CNAME NORMAL 0 3.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "3.example.com.chained.a CNAME NORMAL 0 4.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "4.example.com.chained.a CNAME NORMAL 0 5.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "5.example.com.chained.a CNAME NORMAL 0 6.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "6.example.com.chained.a CNAME NORMAL 0 7.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "7.example.com.chained.a CNAME NORMAL 0 8.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "8.example.com.chained.a CNAME NORMAL 0 9.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "9.example.com.chained.a CNAME NORMAL 0 10.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "10.example.com.chained.a CNAME NORMAL 0 11.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "11.example.com.chained.a CNAME NORMAL 0 12.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "12.example.com.chained.a CNAME NORMAL 0 13.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "13.example.com.chained.a CNAME NORMAL 0 14.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "14.example.com.chained.a CNAME NORMAL 0 15.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "15.example.com.chained.a CNAME NORMAL 0 16.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "16.example.com.chained.a CNAME NORMAL 0 17.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "17.example.com.chained.a CNAME NORMAL 0 18.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "18.example.com.chained.a CNAME NORMAL 0 19.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "19.example.com.chained.a CNAME NORMAL 0 20.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "20.example.com.chained.a CNAME NORMAL 0 21.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "21.example.com.chained.a CNAME NORMAL 0 22.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "22.example.com.chained.a CNAME NORMAL 0 23.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "23.example.com.chained.a CNAME NORMAL 0 24.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "24.example.com.chained.a CNAME NORMAL 0 25.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "25.example.com.chained.a CNAME NORMAL 0 26.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "26.example.com.chained.a CNAME NORMAL 0 27.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "27.example.com.chained.a CNAME NORMAL 0 28.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "28.example.com.chained.a CNAME NORMAL 0 29.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "29.example.com.chained.a CNAME NORMAL 0 30.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "30.example.com.chained.a CNAME NORMAL 0 31.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "31.example.com.chained.a CNAME NORMAL 0 32.example.com.chained.a" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt
echo "32.example.com.chained.a A NORMAL 0 127.0.0.1" >> ${TMPDIR}/${TEST_NUM}-dns_config.txt

NAMESERVER_IP=127.0.0.1:`${DNSDUMMY_PATH} -t 180 -f ${TMPDIR}/${TEST_NUM}-dns_config.txt`

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input.txt | sed -e "s/TEST_NUM/${TEST_NUM}/g" -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 180 -r 221 -- ${SPAMDYKE_PATH} --dns-server-ip ${NAMESERVER_IP} -X chained.a ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 180 -r 221 -- ${SPAMDYKE_PATH} --dns-server-ip ${NAMESERVER_IP} -X chained.a ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep -E "250 ok [0-9]* qp [0-9]*" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi