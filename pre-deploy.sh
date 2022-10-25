  #!/bin/bash

  
    // Login into OCP Cluster
    //oc login --token=sha256~nt9DrIXaErquB8jbFD05z9nnWcoyQzeyBZ_hZAARyHA --server=https://c103-e.eu-de.containers.cloud.ibm.com:30360
    oc status
    
    //Install operator
    oc apply -f ibm-catalog-source.yaml

    //Install DataPower Operator - TBD

    //create new project
    oc new-project sce-test

    //create an IBM Entitlement Key - TBD
    oc create secret docker-registry ibm-entitlement-key -n tools \
    --docker-username=cp \
    --docker-password="$TOKEN" \
    --docker-server=cp.icr.io

    //Create Admin User credential secret - TBD

    //create secrets for keys and certs - TBD

    //Passing the namespace into migrate-backup.sh - TBD