# This test runs spamdyke's config-test when the path given to config-dir
# contains an _ip_/_recipient_ structure with data directories.

mkdir -p ${TMPDIR}/${TEST_NUM}-config.d/_ip_/_recipient_/com/example

echo "${SENDRECV_PATH} -t 30 -- ${SPAMDYKE_PATH} --config-dir ${TMPDIR}/${TEST_NUM}-config.d --config-test ${QMAIL_CMDLINE} > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -- ${SPAMDYKE_PATH} --config-dir ${TMPDIR}/${TEST_NUM}-config.d --config-test ${QMAIL_CMDLINE} > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "ERROR(config-dir): Found a \"_recipient_\" directory as an immediate decendent of a \"_ip_\" directory. This directory structure is invalid and will be ignored. Full path: ${TMPDIR}/${TEST_NUM}-config.d/_ip_/_recipient_" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
