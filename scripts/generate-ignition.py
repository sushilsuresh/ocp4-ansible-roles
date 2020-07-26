#!/usr/bin/python3

import argparse
import base64
import json
import os


def create_ignition(host, domain, ign_file):

    with open(ign_file, 'r') as f:
        ignition = json.load(f)

    files = ignition['storage'].get('files', [])

    fqdn = '{0}.{1}\n'.format(host, domain)

    host_b64 =  base64.b64encode(fqdn.encode("utf-8")).decode('utf-8')
    files.append(
    {
        'path': '/etc/hostname',
        'mode': 420,
        'contents': {
            'source': 'data:text/plain;charset=utf-8;base64,' + host_b64,
            'verification': {}
        },
        'filesystem': 'root',
    })

    ignition['storage']['files'] = files;

    with open('{0}.ign'.format(host), 'w') as f:
        json.dump(ignition, f)

def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("--host",
                        help="Hostname of the node ( eg: worker01 )",
                        required=True)
    parser.add_argument("--domain",
                        help="Base Domain for the node ( eg: ocp4.example.com )",
                        required=True)
    parser.add_argument("--src-ign",
                        help="Source ignition file ( eg: worker.ign ) including path if not local",
                        required=True)
    args = parser.parse_args()

    create_ignition(args.host, args.domain, args.src_ign)

main()
