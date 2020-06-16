#!/bin/bash

display_usage() {
  script_name=${0}
  echo -e "\nUsage:\n${script_name} <cluster-id>.<cluster-base-domain>\n"
  echo -e "\neg:\n${script_name} ocp4.example.com\n"
}

port_check() {
  port=${2}
  if [ "${1}" == "INTERNAL" ]
  then
    endpoint="api-int.${DOMAIN}"
  elif [ "${1}" == "EXTERNAL" ]
  then
    endpoint="api.${DOMAIN}"
  elif [ "${1}" == "APPS" ]
  then
    endpoint="foo.${APP_DOMAIN}"
  else
    echo "Something went horribly wrong !!!"
    exit 1
  fi
  nc -zv ${endpoint} ${port} 2>1 > /dev/null
  if [ $? -eq 1 ]
  then
    echo "${endpoint} ${port} => NOT working !!!"
  else
    echo "${endpoint} ${port} => working OK"
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
APP_DOMAIN="apps.${DOMAIN}"

echo
echo "External API endpoint port check"
echo "################################"
for port in 6443
do
  port_check "EXTERNAL" ${port}
done

echo
echo "Internal API endpoint port check"
echo "################################"
for port in 6443 22623
do
  port_check "INTERNAL" ${port}
done

echo
echo "External app endpoint port check"
echo "################################"
for port in 80 443
do
  port_check "APPS" ${port}
done
echo
