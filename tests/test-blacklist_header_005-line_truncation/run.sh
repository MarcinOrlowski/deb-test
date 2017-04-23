# This test creates a message with a header line longer than 16K characters.
# Even though the line matches the blacklist, no rejection should be seen
# because the line should be truncated at 16K before the comparison is made.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input_1.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt

echo "Subject: 0123456789" >> ${TMPDIR}/${TEST_NUM}-input.txt
i=0
while [ ${i} -lt 10000 ]
do
  echo "    0123456789-${i}" >> ${TMPDIR}/${TEST_NUM}-input.txt
  i=$[${i}+1]
done
echo "    foobar" >> ${TMPDIR}/${TEST_NUM}-input.txt

cat input_2.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" >> ${TMPDIR}/${TEST_NUM}-input.txt

echo "${SENDRECV_PATH} -t 30 -r 554 -b 4000 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --header-blacklist-entry \"Subject:*foobar\" ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -r 554 -b 4000 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --header-blacklist-entry "Subject:*foobar" ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "554 Refused. Your message has been blocked due to its content." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ -z "${output}" ]
then
  output=`grep -E "250 ok [0-9]* qp [0-9]*" ${TMPDIR}/${TEST_NUM}-output.txt`
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
