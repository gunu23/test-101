  #!/bin/bash
    
#Install operator
  oc apply -f ibm-catalog-source.yaml

#Install DataPower Operator - TBD

#create new project
  oc project sce-test

#create an IBM Entitlement Key - TBD
  oc create secret docker-registry ibm-entitlement-key -n sce-test \
  --docker-username=cp \
  --docker-password="eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cGxhY2UiLCJpYXQiOjE2MzMwMjk0NjgsImp0aSI6Ijk1MWMyNjk2OGI2NjQ0ZTk5ZGU3YjBiOTg3YjdhNjkzIn0.oEvOsmZ5luC7GnBk-arxGCgqriPCxRpG6DwluQwUGH4" \
  --docker-server=cp.icr.io

#Create Admin User credential secret - TBD
  oc create secret generic datapower-user --from-literal=password=admin

#create a folder project
  mkdir ./datapower

#create sub dirs inside the project folder
  mkdir ./datapower/local ./datapower/config ./datapower/certs

#change permission
  chmod 1777 ./datapower/local ./datapower/config ./datapower/certs

#pull docker image
  docker pull icr.io/integration/datapower/datapower-limited:10.0.4.0

#create pem files
  cd ./datapower

  docker run -it --name datapower \
  -v $(pwd)/config:/opt/ibm/datapower/drouter/config:z \
  -v $(pwd)/local:/opt/ibm/datapower/drouter/local:z \
  -v $(pwd)/certs:/opt/ibm/datapower/root/secure/usrcerts:z \
  -e DATAPOWER_ACCEPT_LICENSE="true" \
  -e DATAPOWER_INTERACTIVE="true" \
  -p 9090:9090 \
  -p 8001:8001 \
  icr.io/integration/datapower/datapower-limited:10.0.4.0

#create secrets for keys and certs - TBD
  oc create secret generic default-cert --from-file=/path/to/cert --from-file=/path/to/key -n sce-test

#Passing the namespace into migrate-backup.sh - TBD

#Creating DataPower Gateway Operator
