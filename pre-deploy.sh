  #!/bin/bash
    
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