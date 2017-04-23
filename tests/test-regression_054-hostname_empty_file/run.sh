# This test tries to use an empty hostname file and looks for a segfault.

export TCPREMOTEIP=11.22.33.44

cp input.txt ${TMPDIR}/${TEST_NUM}-input.txt
touch ${TMPDIR}/${TEST_NUM}-hostname.txt

echo "${SENDRECV_PATH} -t 30 -r 221 -u $2 -p $3 -- ${SPAMDYKE_PATH} --hostname-file ${TMPDIR}/${TEST_NUM}-hostname.txt --smtp-auth-level always-encrypted --smtp-auth-command ${SMTPAUTH_CRAMMD5_PATH} --log-target stderr ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -r 221 -u $2 -p $3 -- ${SPAMDYKE_PATH} --hostname-file ${TMPDIR}/${TEST_NUM}-hostname.txt --smtp-auth-level always-encrypted --smtp-auth-command ${SMTPAUTH_CRAMMD5_PATH} --log-target stderr ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "221" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
