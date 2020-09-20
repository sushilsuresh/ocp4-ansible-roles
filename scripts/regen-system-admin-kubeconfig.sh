#!/bin/bash

# THe script has been inspired by the medium article below
# https://medium.com/better-programming/k8s-tips-give-access-to-your-clusterwith-a-client-certificate-dfb3b71a76fe
# The script has only been tested again OpenShift 4.x

DEBUG=0
SCRIPT_NAME=$(basename ${0})

trap 'cleanup' EXIT

cleanup() {
    if [ "${DEBUG}" == 1 ]
    then
        echo "Leaving temporary files undeleted."
    else
        # Delete all temporary files.
        echo "Deleting temporary files."
        rm system-admin-csr.conf \
           system-admin.key \
           system-admin.csr \
           system-admin.crt \
           ocp-ca.crt \
           CertificateSigningRequest.yaml \
           2>/dev/null
    fi
}

usage()
{
    echo
    echo -e "\t usage: ${SCRIPT_NAME} | [--help] | [--debug]\n"
    echo -e "\t eg: ${SCRIPT_NAME}\n"
    echo -e "\t eg: ${SCRIPT_NAME} --help\n"
    echo -e "\t eg: ${SCRIPT_NAME} --debug\n"
}

# Bail out if user had provided more than one argument.
if [ "$#" -gt 1 ]
then
    usage
    exit 1
fi

# Check if the argument passed is either --debug or --help
if [ "$#" == 1 ]
then
    case $1 in
      --debug ) DEBUG=1
                ;;
      --help  ) usage
                exit
                ;;
      * )       usage
                exit 1
    esac
fi


# Generarte config file to with details such as CN and OU to create a new CSR
echo "Generating openssl config file to create a new cert key and csr"
cat <<EOF >system-admin-csr.conf
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[ dn ]
CN = system:admin
O = system:masters

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
EOF

# NOTE: The "v3_ext" section is important and must have "clientAuth"


# Generate a new CSR
echo "Generating new certifcate key and csr for system:admin user"
openssl req -config system-admin-csr.conf -new -keyout system-admin.key -nodes -out system-admin.csr

BASE64_CSR=$(cat system-admin.csr | base64 -w0)

# Create a CertificateSigningRequest yaml definition.
echo "Creating a CertificateSigningRequest yaml file"
cat <<EOF >CertificateSigningRequest.yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: system-admin-csr
spec:
  groups:
  - system:authenticated
  request: ${BASE64_CSR}
  usages:
  - digital signature
  - key encipherment
  - server auth
  - client auth
EOF

# create a new CSR request for sytem:admin user
echo "Create a new CertificateSigningRequest object for system:admin user"
oc apply -f CertificateSigningRequest.yaml

count=0
# Wait for the cetificate to be created.
while true
do
    count=$((count+1))
    oc get csr system-admin-csr 2>&1>/dev/null
    if [ $? -eq 0 ]
    then
        break
    fi
    if [ $count -eq 10 ]
    then
        echo "Waited too long for the new csr"
        exit 1
    fi
    sleep 1
done

echo "Approve the newly requested certificate for system:admin user"
oc adm certificate approve system-admin-csr

echo "Extract the newly signed certificate for system:admin user"
oc get csr system-admin-csr -o jsonpath='{.status.certificate}' | base64 --decode > system-admin.crt

# Prepare variables to build our kubeconfig file

CLUSTER_NAME=$(oc config view --minify -o jsonpath={.clusters[0].name})

CLIENT_CERTIFICATE_DATA=$(oc get csr system-admin-csr -o jsonpath='{.status.certificate}')
# We do not need the approved csr object any more.
echo "Deleting the approved csr request"
oc delete csr system-admin-csr

CLUSTER_ENDPOINT=$(oc config view --minify -o jsonpath={.clusters[0].cluster.server})

CLIENT_KEY_DATA=$(cat system-admin.key | base64 -w0)

# Extract the 3 x CA certs being used by the cluster.
echo "Extracing CA certs from the cluster"
oc -n openshift-kube-apiserver-operator extract cm/localhost-serving-ca --keys=ca-bundle.crt --to=- 2>/dev/null > ocp-ca.crt
oc -n openshift-kube-apiserver-operator extract cm/service-network-serving-ca --keys=ca-bundle.crt --to=- 2>/dev/null >> ocp-ca.crt
oc -n openshift-kube-apiserver-operator extract cm/loadbalancer-serving-ca --keys=ca-bundle.crt --to=- 2>/dev/null >> ocp-ca.crt

CLUSTER_CA=$(cat ocp-ca.crt | base64 -w0)

# Generate a new kubeconfig for system:admin user
echo "Generate a new kubeconfig for system:admin user"

cat <<EOF >system-admin-kubeconfig
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    certificate-authority-data: ${CLUSTER_CA}
    server: ${CLUSTER_ENDPOINT}
users:
- name: system:admin/${CLUSTER_NAME}
  user:
    client-certificate-data: ${CLIENT_CERTIFICATE_DATA}
    client-key-data: ${CLIENT_KEY_DATA}
contexts:
- name: default/${CLUSTER_NAME}/system:admin
  context:
    cluster: ${CLUSTER_NAME}
    user: system:admin/${CLUSTER_NAME}
    namespace: default
current-context: default/${CLUSTER_NAME}/system:admin
EOF

echo -e '\n\tNewly created kubeconfig file is save as - "system-admin-kubeconfig"\n'
