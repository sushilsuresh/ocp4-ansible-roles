#!/bin/bash

display_usage() {
  echo -e "\nUsage:\n./dns_check.sh <cluster-id>.<cluster-base-domain>"
  echo -e "eg:\n./dns_check.sh ocp4.example.com\n"
}

forward_lookup() {
  dns=$(dig ${1}.${DOMAIN} +short)
  if [ "${dns}" != "" ]
  then
    echo "${1}.${DOMAIN} => ${dns}"
  else
    EXIT_CODE=1
  fi
}

reverse_lookup() {
  master_ip=$(dig ${1}.${DOMAIN} +short)
  if [ "${master_ip}" != "" ]
  then
    dns=$(dig -x ${master_ip} +short)
    echo "${master_ip} => ${dns}"
  else
    EXIT_CODE=1
  fi
}


if [ $# -lt 1 ]
then
  display_usage
  exit 1
fi

if [[ ( $1 == "--help" ) || ( $1 == "-h" ) ]]
then
  display_usage
  exit 0
fi

DOMAIN=${1}

BOOTSTRAP_NODE="boostrap"
MASTER_NODES=$(echo master{00..02})
WORKER_NODES=$(echo worker{00..02})
INFRA_NODES=$(echo infra{00..02})
NODES="${MASTER_NODES} ${WORKER_NODES} ${INFRA_NODES}"

echo $NODES

echo
echo "Checking master/infra/worker dns records (forward)"
echo "##################################################"
for i in ${NODES}
do
  forward_lookup ${i}
done

echo
echo "Checking master/infra/worker dns records (reverse)"
echo "###################################################"
for i in ${NODES}
do
  reverse_lookup ${i}
done

echo
echo "Checking etcd dns record"
echo "########################"
for i in etcd-{0..2}
do
  forward_lookup ${i}
done

echo
echo "Checking etcd dns SRV record"
echo "############################"
dns=$(dig _etcd-server-ssl._tcp.${DOMAIN} SRV +short)
if [ "${dns}" != "" ]
then
  echo -e "etcd SRV record => \n${dns}"
fi

echo
echo "Checking bootstrap dns record"
echo "###############################"
for i in ${BOOTSTRAP_NODE}
do
  forward_lookup ${i}
done


echo
echo "Checking api endpoint dns record"
echo "################################"
for i in api api-int
do
  forward_lookup ${i}
done

echo
echo "Checking wildcard app endpoint dns record"
echo "#########################################"
for i in foo bar
do
  forward_lookup ${i}
done
echo
