#!/bin/bash

#define parameters which are passed in.
NAME=$1; shift
DOMAINLIST=$@


INDVDOMAIN=$(
  for DOMAIN in {$DOMAINLIST}; do
    echo "    - name: $DOMAIN"
    echo "      certs:"
    echo "      - certType: usrcerts"
    echo "        secret: $DOMAIN-cert"
    echo "      dpApp:"
    echo "        config:"
    echo "        - $DOMAIN-cfg"
    echo "        local:"
    echo "        - $DOMAIN-local"
  done;
)

#define the template.
cat  << EOF
apiVersion: datapower.ibm.com/v1beta3
kind: DataPowerService
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "350"
  name: $NAME-instance
spec:
  replicas: 1
  version: 10.0-cd
  license:
    accept: true
    use: nonproduction
    license: L-RJON-CCCP46
  users:
  - name: admin
    accessLevel: privileged
    passwordSecret: datapower-user
  domains:
$INDVDOMAIN
EOF
