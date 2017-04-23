# This test delivers a small test message by bursting the data when
# qmail is slow to respond to the "DATA" command and the header
# blacklist is enabled.  The message should go through without generating
# a DENIED_OTHER message.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input.txt | sed -e "s/TEST_NUM/${TEST_NUM}/g" -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -b 12000 -r 221 -t 30 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --header-blacklist-entry \"foo: bar\" ${SMTPDUMMY_PATH} -d 5 < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -b 12000 -r 221 -t 30 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --header-blacklist-entry "foo: bar" ${SMTPDUMMY_PATH} -d 5 < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep -i "ALLOWED from: ${FROM_ADDRESS} to: $1" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  output=`grep -i "DENIED_OTHER from: ${FROM_ADDRESS} to: $1" ${TMPDIR}/${TEST_NUM}-output.txt`
  if [ -z "${output}" ]
  then
    outcome="success"
  else
    echo OUTPUT IN tmp/${TEST_NUM}-output.txt:
    cat ${TMPDIR}/${TEST_NUM}-output.txt

    outcome="failure"
  fi
else
  echo OUTPUT IN tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
