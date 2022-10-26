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

#create secrets for keys and certs - TBD

#Passing the namespace into migrate-backup.sh - TBD

#Creating DataPower Gateway Operator
