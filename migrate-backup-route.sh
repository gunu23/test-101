#!/bin/bash

#define parameters which are passed in.
NAME=$1
NAMESPACE=$2
TLSBOOL=$3
PORT=$4

TLSENABLED=$(
    if [ "$TLSBOOL" = "https" ]; then
        echo "  tls:"
        echo "    termination: passthrough"
        echo "  wildcardPolicy: None"
    fi
)

#define the template.
cat  << EOF
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "370"
  name: $NAME-$PORT-route
  namespace: $NAMESPACE
spec:
  to:
    kind: Service
    name: $NAME-service
    weight: 100
  port:
    targetPort: $NAME-$PORT
$TLSENABLED
EOF
