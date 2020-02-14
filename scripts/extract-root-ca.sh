#!/bin/bash

display_usage() {
  echo "This scirpt must be run with atleast one argument"
  echo "The LDAPS <endpoint>:<port> should be passed in as argument"
  echo -e "\nEg: ./extract-root-ca.sh www.google.com:443\n"

}

# if less than two arguments supplied, display usage
if [ $# -lt 1 ]
then
  display_usage
  exit 1
fi

SECURE_ENDPOINT="${1}"

ROOT_CA_CRT_URI=$(echo | openssl s_client -connect ${SECURE_ENDPOINT} 2>&1 \
                       | openssl x509 -noout -text \
                       | grep 'CA Issuers' \
                       | grep -o http.*)

wget -q ${ROOT_CA_CRT_URI=} -O - \
      | openssl x509 -inform der
