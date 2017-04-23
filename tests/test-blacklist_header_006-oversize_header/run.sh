# This test creates a message with a header block containing more than 512K characters.
# Even though the subject matches the blacklist, no rejection should be seen
# because spamdyke should stop retaining header data at 512K.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com

cat input_1.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt

i=0
while [ ${i} -lt 50000 ]
do
  echo "X-Header-Field: 0123456789-${i}" >> ${TMPDIR}/${TEST_NUM}-message.txt
  i=$[${i}+1]
done

cat input_2.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" >> ${TMPDIR}/${TEST_NUM}-message.txt
cat ${TMPDIR}/${TEST_NUM}-message.txt >> ${TMPDIR}/${TEST_NUM}-input.txt
cat input_3.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" >> ${TMPDIR}/${TEST_NUM}-input.txt

echo "${SENDRECV_PATH} -t 30 -r 554 -b 4000 -- ${SPAMDYKE_PATH} -lverbose --log-target stderr --header-blacklist-entry \"Subject: foo!\" ${SMTPDUMMY_PATH} -o ${TMPDIR}/${TEST_NUM}-output_body.txt < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
${SENDRECV_PATH} -t 30 -r 554 -b 4000 -- ${SPAMDYKE_PATH} -lverbose --log-target stderr --header-blacklist-entry "Subject: foo!" ${SMTPDUMMY_PATH} -o ${TMPDIR}/${TEST_NUM}-output_body.txt < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1

output=`grep "554 Refused. Your message has been blocked due to its content." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ -z "${output}" ]
then
  output=`grep "250 DATA END received" ${TMPDIR}/${TEST_NUM}-output.txt`
  if [ ! -z "${output}" ]
  then
    output=`grep "ERROR: unable to continue buffering message data" ${TMPDIR}/${TEST_NUM}-output.txt`
    if [ ! -z "${output}" ]
    then
      output=`diff -b ${TMPDIR}/${TEST_NUM}-message.txt ${TMPDIR}/${TEST_NUM}-output_body.txt`
      if [ -z "${output}" ]
      then
        outcome="success"
      else
        echo Filter failure - tmp/${TEST_NUM}-output.txt:
        echo "${output}"

        outcome="failure"
      fi
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
else
  echo Filter failure - tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
