#!/bin/bash

#define parameters which are passed in.
NAME=$1; shift
NAMESPACE=$1; shift
PORTS=$@

PORTLIST=$(
  local port_split
  for PORT in {$PORTS}; do
    IFS='-' read -ra port_split <<< "$PORT"

    echo "    - name: $NAME-${port_split[1]}";
    echo "      protocol: TCP";
    echo "      port: ${port_split[1]}";
    echo "      targetPort: ${port_split[1]}";
  done;
)

#define the template.
cat  << EOF
kind: Service
apiVersion: v1
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "360"
  name: $NAME-service
  namespace: $NAMESPACE
spec:
  selector:
    app.kubernetes.io/instance: $NAMESPACE-$NAME-instance
  ports:
$PORTLIST
EOF