#!/bin/bash

#define parameters which are passed in.
NAME=$1
PORT=$2

#define the template.
cat  << EOF
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "370"
  name: $NAME-$PORT-route
  namespace: $NAME
spec:
  to:
    kind: Service
    name: $NAME-service
    weight: 100
  port:
    targetPort: $NAME-$PORT
  tls:
    termination: passthrough
  wildcardPolicy: None
EOF
