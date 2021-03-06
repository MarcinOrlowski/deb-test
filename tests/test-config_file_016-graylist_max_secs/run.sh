# This test checks if spamdyke will graylist deliveries when an old graylist
# entry exists but the maximum age has passed.

export TCPREMOTEIP=${TESTSD_MISSING_RDNS_IP}

FROM_ADDRESS=test-${TEST_NUM}.${RANDOM}.${RANDOM}@example.com
CURRENT_TIME=`date "+%s"`

echo "graylist-dir=${TMPDIR}/${TEST_NUM}-graylist.d" > ${TMPDIR}/${TEST_NUM}-config.txt
echo "graylist-max-secs=600" >> ${TMPDIR}/${TEST_NUM}-config.txt
echo "graylist-level=always" >> ${TMPDIR}/${TEST_NUM}-config.txt

mkdir -p ${TMPDIR}/${TEST_NUM}-graylist.d/`echo $1 | sed -e "s/[^@]*@//" | awk '{ print tolower($1) }'`/`echo $1 | sed -e "s/@.*//" | awk '{ print tolower($1) }'`
touch -t "`${ADDSECS_PATH} -5000`" ${TMPDIR}/${TEST_NUM}-graylist.d/`echo $1 | sed -e "s/[^@]*@//" | awk '{ print tolower($1) }'`/`echo $1 | sed -e "s/@.*//" | awk '{ print tolower($1) }'`/${FROM_ADDRESS}

cat input.txt | sed -e "s/TARGET_EMAIL/$1/g" -e "s/FROM_ADDRESS/${FROM_ADDRESS}/g" > ${TMPDIR}/${TEST_NUM}-input.txt
echo "${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} -f ${TMPDIR}/${TEST_NUM}-config.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt"
${SENDRECV_PATH} -t 30 -r 421 -- ${SPAMDYKE_PATH} -f ${TMPDIR}/${TEST_NUM}-config.txt ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt

output=`grep "421 Your address has been graylisted. Try again later." ${TMPDIR}/${TEST_NUM}-output.txt`
if [ ! -z "${output}" ]
then
  outcome="success"
else
  echo OUTPUT IN tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
