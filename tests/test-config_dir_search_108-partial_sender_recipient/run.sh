# This test looks for a rejection because the incoming rDNS name doesn't
# resolve..  The option to check the rDNS name should come from a config-dir
# that matches the partial sender address and the partial recipient address.

export TCPREMOTEIP=${TESTSD_UNRESOLVABLE_RDNS_IP}

FROM_USERNAME=test-${TEST_NUM}.${RANDOM}.${RANDOM}
FROM_ADDRESS=${FROM_USERNAME}@example.com

recipient_dir=""
for segment in `echo $1 | awk '{ print tolower($1) }' | sed -e "s/[^@]*@//" -e "s/\./ /g"`
do
  if [ "${recipient_dir}" == "" ]
  then
    recipient_dir=${segment}
  else
    recipient_dir=${segment}/${recipient_dir}
  fi
done

recipient_path=${recipient_dir}
recipient_dir=`echo ${recipient_dir} | sed -e "s/\/[^/]*$//"`

mkdir -p ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example/_recipient_/${recipient_dir}

echo policy-url=fred > ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/fred
echo policy-url=barney > ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/barney
echo policy-url=wilma > ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/wilma
echo policy-url=dino > ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example/_recipient_/${recipient_dir}/dino
echo policy-url=pebbles > ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example/_recipient_/${recipient_dir}/pebbles
echo policy-url=bambam > ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example/_recipient_/${recipient_dir}/bambam
echo reject-unresolvable-rdns > ${TMPDIR}/${TEST_NUM}-config.d/_sender_/com/example/_recipient_/${recipient_path}

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} --config-dir ${TMPDIR}/${TEST_NUM}-config.d ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} --config-dir ${TMPDIR}/${TEST_NUM}-config.d ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep "421 Refused. Your reverse DNS entry does not resolve." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  output=`grep "See: " ${TMPDIR}/${TEST_NUM}-output.txt`
  if [ -z "${output}" ]
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
