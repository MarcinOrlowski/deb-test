# This test sends more than one command in a single packet with STARTTLS, then
# checks if spamdyke used the second command as though it were sent after TLS
# was started.

cp input.txt ${TMPDIR}/${TEST_NUM}-input.txt

echo "${SENDRECV_PATH} -r 221 -t 30 -- ${SPAMDYKE_PATH} --log-target stderr --tls-level smtp --tls-certificate-file ${CERTDIR}/combined_no_passphrase/server.pem ${SMTPDUMMY_PATH} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -r 221 -t 30 -- ${SPAMDYKE_PATH} --log-target stderr --tls-level smtp --tls-certificate-file ${CERTDIR}/combined_no_passphrase/server.pem ${SMTPDUMMY_PATH} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "250 RSET received" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ -z "${output}" ]
then
  outcome="success"
else
  echo OUTPUT IN tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
