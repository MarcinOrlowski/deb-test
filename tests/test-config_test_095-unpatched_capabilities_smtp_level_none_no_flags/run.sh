# This test looks for a message from the config-test when it finds the child
# process does not support SMTP AUTH and the smtp-auth-level option is "none".

child_cmd=`echo ${QMAIL_CMDLINE} | awk '{ print $1 }'`

echo "${SPAMDYKE_PATH} -lverbose --config-test --smtp-auth-level none ${QMAIL_CMDLINE} > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SPAMDYKE_PATH} -lverbose --config-test --smtp-auth-level none ${QMAIL_CMDLINE} > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "SUCCESS: ${child_cmd} does not appear to offer SMTP AUTH support. spamdyke will block authentication attempts." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
