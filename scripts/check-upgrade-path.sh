#!/bin/bash

# NOTE: The following script has been gathered from the below resources.
#       https://access.redhat.com/solutions/4583231

# NOTE: OpenShift has 3 x channels
#       - candidate
#       - fast
#       - stable
#
# For OpenShift 4.2 the possible channels are listed below.
# - candidate-4.2
# - fast-4.2
# - stable-4.2
#
# For more detailed explanation please check the below alrticle
# https://access.redhat.com/articles/4495171

set -euf -o pipefail

VERSION=""
CHANNEL=""
SCRIPT_NAME=$(basename ${0})

usage()
{
    echo
    echo -e "\t usage: ${SCRIPT_NAME} [--ocp-version <version> --channel <channel>] | [-h]\n"
    echo -e "\t eg: ./${SCRIPT_NAME} --ocp-version 4.3.0 --channel stable-4.3\n"
}

if [ "$#" == 0 ]
then
  usage
  exit 1
fi

while (($#)) ; do
  case $1 in
    --ocp-version )  shift
                     VERSION=${1}
                     ;;
    --channel )      shift
                     CHANNEL=${1}
                     ;;
    -h | --help )    usage
                     exit
                     ;;
    * )              usage
                     exit 1
    esac
    shift
done

if [ -z "${VERSION}" ]
then
  usage
  exit 1
fi

if [ -z "${CHANNEL}" ]
then
  usage
  exit 1
fi

curl -sH 'Accept:application/json' "https://api.openshift.com/api/upgrades_info/v1/graph?channel=${CHANNEL}" | jq -r --arg CURRENT_VERSION "${VERSION}" '. as $graph | $graph.nodes | map(.version=='\"${VERSION}\"') | index(true) as $orig | $graph.edges | map(select(.[0] == $orig)[1]) | map($graph.nodes[.].version) | sort_by(.)'
