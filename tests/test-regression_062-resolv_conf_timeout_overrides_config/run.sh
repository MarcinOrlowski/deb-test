# This test creates a resolv.conf file to set the nameserver and total timeout
# to a known value.  It then starts spamdyke with the dns-timeout-secs parameter
# to see which one takes precedence -- the spamdyke parameter should win.

export TCPREMOTEIP=11.22.33.44
export NAMESERVER_IP=127.0.0.1:52
export RESOLV_CONF_TIMEOUT=27
export CONFIG_TIMEOUT=3

cat resolv_conf.txt | sed -e "s/NAMESERVER_IP/${NAMESERVER_IP}/g" -e "s/TIMEOUT/${RESOLV_CONF_TIMEOUT}/g" > ${TMPDIR}/${TEST_NUM}-resolv.conf

cp input.txt ${TMPDIR}/${TEST_NUM}-input.txt
echo "time ${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} -lexcessive --log-target stderr --dns-resolv-conf ${TMPDIR}/${TEST_NUM}-resolv.conf --dns-timeout-secs ${CONFIG_TIMEOUT} ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1"
start_time=`date +%s`
time ${SENDRECV_PATH} -t 30 -r 221 -- ${SPAMDYKE_PATH} -lexcessive --log-target stderr --dns-resolv-conf ${TMPDIR}/${TEST_NUM}-resolv.conf --dns-timeout-secs ${CONFIG_TIMEOUT} ${QMAIL_CMDLINE} < ${TMPDIR}/${TEST_NUM}-input.txt > ${TMPDIR}/${TEST_NUM}-output.txt 2>&1
end_time=`date +%s`

overtime=true
if [ "$[${end_time}-${start_time}]" = "${CONFIG_TIMEOUT}" ]
then
  overtime=false
elif [ "$[${end_time}-${start_time}]" = "$[${CONFIG_TIMEOUT}+1]" ]
then
  overtime=false
fi

if [ "${overtime}" == "false" ]
then
  output=`grep "for 44.33.22.11.in-addr.arpa(PTR) to DNS server ${NAMESERVER_IP} (attempt 3)" ${TMPDIR}/${TEST_NUM}-output.txt`
  if [ ! -z "${output}" ]
  then
    outcome="success"
  else
    echo Total time was $[${end_time}-${start_time}], should have been ${CONFIG_TIMEOUT}
    echo CONTENTS OF ${TMPDIR}/${TEST_NUM}-resolv.conf:
    cat ${TMPDIR}/${TEST_NUM}-resolv.conf
    echo OUTPUT IN tmp/${TEST_NUM}-output.txt:
    cat ${TMPDIR}/${TEST_NUM}-output.txt

    outcome="failure"
  fi
else
  echo Total time was $[${end_time}-${start_time}], should have been ${CONFIG_TIMEOUT}
  echo CONTENTS OF /etc/resolv.conf:
  cat /etc/resolv.conf
  echo OUTPUT IN tmp/${TEST_NUM}-output.txt:
  cat ${TMPDIR}/${TEST_NUM}-output.txt

  outcome="failure"
fi
