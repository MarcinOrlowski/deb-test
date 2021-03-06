# This test looks for a startup error because the configuration file can't be
# read after the user has been changed.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

mkdir -p ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com
echo reject-empty-rdns=yes >> ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example
echo run-as-user=$4 >> ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example
echo ip-whitelist-file=${TMPDIR}/${TEST_NUM}-whitelist_ip.txt >> ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example
echo log-target=stderr >> ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example

echo ${TESTSD_MISSING_RDNS_IP} > ${TMPDIR}/${TEST_NUM}-whitelist_ip.txt
chmod 600 ${TMPDIR}/${TEST_NUM}-whitelist_ip.txt

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} --config-dir ${TMPDIR}/${TEST_NUM}-config.d --log-target stderr ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} --config-dir ${TMPDIR}/${TEST_NUM}-config.d --log-target stderr ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "ERROR: Option not allowed in configuration file, found in file ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example on line 2: run-as-user" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
