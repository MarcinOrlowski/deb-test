# This test delivers a small test message while both the header
# blacklist filter and configuration directories are in use, then looks
# for a crash.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

mkdir -p ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com
touch ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example

cat input.txt | sed -e "s/TEST_NUM/${TEST_NUM}/g" -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -r 221 -t 30 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --header-blacklist-entry \"foo: bar\" --config-dir ${TMPDIR}/${TEST_NUM}-config.d ${SMTPDUMMY_PATH} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -r 221 -t 30 -- ${SPAMDYKE_PATH} -linfo --log-target stderr --header-blacklist-entry "foo: bar" --config-dir ${TMPDIR}/${TEST_NUM}-config.d ${SMTPDUMMY_PATH} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "221 QUIT received" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo OUTPUT IN tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
