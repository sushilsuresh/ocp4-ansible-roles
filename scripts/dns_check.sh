#!/bin/bash

display_usage() {
  echo -e "\nUsage:\n./dns_check.sh <cluster-id>.<cluster-base-domain>"
  echo -e "eg:\n./dns_check.sh ocp4.example.com\n"
}

forward_lookup() {
  dns=$(dig ${1}.${DOMAIN} +short)
  if [ "${dns}" != "" ]
  then
    echo "${i}.${DOMAIN} => ${dns}"
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


echo
echo "Checking master/infra/worker dns records (forward)"
echo "##################################################"
for i in {master,infra,worker}{00..02}
do
  forward_lookup ${i}
done

echo
echo "Checking master/infra/worker dns records (reverse)"
echo "###################################################"
for i in {master,infra,worker}{00..02}
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
  echo "etcd SRV record => ${dns}"
fi

echo
echo "Checking bootstrap dns record"
echo "###############################"
for i in bootstrap0
do
  forward_lookup $i
done


echo
echo "Checking api endpint dns record"
echo "###############################"
for i in api api-int
do
  forward_lookup ${i}
done

echo
echo "Checking wildcard app endpint dns record"
echo "########################################"
for i in foo bar
do
  forward_lookup ${i}.apps
done
echo
