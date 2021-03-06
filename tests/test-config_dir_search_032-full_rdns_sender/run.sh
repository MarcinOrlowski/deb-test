# This test looks for a rejection because the incoming rDNS name doesn't
# resolve..  The option to check the rDNS name should come from a config-dir
# that matches the full rDNS name and the full sender address.

export TCPREMOTEIP=${TESTSD_UNRESOLVABLE_RDNS_IP}

FROM_USERNAME=test-${TEST_NUM}.${RANDOM}.${RANDOM}
FROM_ADDRESS=${FROM_USERNAME}@example.com

rdns_path=""
for segment in `${DNSPTR_PATH} ${TESTSD_UNRESOLVABLE_RDNS_IP} | sed -e "s/\./ /g"`
do
  if [ "${rdns_path}" == "" ]
  then
    rdns_path=${segment}
  else
    rdns_path=${segment}/${rdns_path}
  fi
done

rdns_dir=`echo ${rdns_path} | sed -e "s/\/[^/]*$//g"`

mkdir -p ${TMPDIR}/${TEST_NUM}-config.d/_rdns_/${rdns_path}/_sender_/com/example/_at_

echo policy-url=fred > ${TMPDIR}/${TEST_NUM}-config.d/_rdns_/${rdns_dir}/fred
echo policy-url=barney > ${TMPDIR}/${TEST_NUM}-config.d/_rdns_/${rdns_dir}/barney
echo policy-url=wilma > ${TMPDIR}/${TEST_NUM}-config.d/_rdns_/${rdns_dir}/wilma
echo policy-url=dino > ${TMPDIR}/${TEST_NUM}-config.d/_rdns_/${rdns_path}/_sender_/com/example/_at_/dino
echo policy-url=pebbles > ${TMPDIR}/${TEST_NUM}-config.d/_rdns_/${rdns_path}/_sender_/com/example/_at_/pebbles
echo policy-url=bambam > ${TMPDIR}/${TEST_NUM}-config.d/_rdns_/${rdns_path}/_sender_/com/example/_at_/bambam
echo reject-unresolvable-rdns > ${TMPDIR}/${TEST_NUM}-config.d/_rdns_/${rdns_path}/_sender_/com/example/_at_/${FROM_USERNAME}

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
