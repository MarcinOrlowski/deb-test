# This test authenticates using SMTP AUTH CRAM-MD5 and delivers a small message.
# The challenge should contain the local hostname read from a file.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

hostname > ${TMPDIR}/${TEST_NUM}-hostname.txt

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input.txt | sed -e "s/TEST_NUM/${TEST_NUM}/g" -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 221 -u $2 -p $3 -- ${SPAMDYKE_PATH} -r --smtp-auth-level always-encrypted --smtp-auth-command \"${AUTH_CMDLINE}\" --hostname-file ${TMPDIR}/${TEST_NUM}-hostname.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 221 -u $2 -p $3 -- ${SPAMDYKE_PATH} -r --smtp-auth-level always-encrypted --smtp-auth-command "${AUTH_CMDLINE}" --hostname-file ${TMPDIR}/${TEST_NUM}-hostname.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep -E "250 ok [0-9]* qp [0-9]*" ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo Delivery failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
