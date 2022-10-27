  #!/bin/bash
    
#Install operator
  oc apply -f ibm-catalog-source.yaml

#Install DataPower Operator - TBD

#create new project
  #  oc project sce-test
### Create namespace
    namespace="sce-test2"
    if [ -z "${namespace}" ]; then
        echo "ERROR: missing namespace argument, make sure to pass namespace, ex: '-n mynamespace'"
        exit 1;
    fi

    status=$(oc get ns ${namespace} --ignore-not-found -ojson | jq -r .status.phase)
    if [[ ${status} != 'Active' ]]; then
    echo "Creating namespace ${namespace}"
    oc create namespace ${namespace}
    sleep 10
    else
    echo "Namespace ${namespace} found"
    fi
#create an IBM Entitlement Key - TBD
  ### Create pull secret
  secret_name="ibm-entitlement-key"
  docker_registry="cp.icr.io"
  docker_registry_username="cp"
  docker_registry_password="eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cGxhY2UiLCJpYXQiOjE2MzMwMjk0NjgsImp0aSI6Ijk1MWMyNjk2OGI2NjQ0ZTk5ZGU3YjBiOTg3YjdhNjkzIn0.oEvOsmZ5luC7GnBk-arxGCgqriPCxRpG6DwluQwUGH4"
  docker_registry_user_email="gunu.shrestha@ibm.com"

  echo "create_pull_secret $secret_name, $namespace, $docker_registry, $docker_registry_username, $docker_registry_password, $docker_registry_user_email"

  if [ -z "${secret_name}" ]; then
    echo "ERROR: missing secret_name"
    exit 1;
  fi
  if [ -z "${namespace}" ]; then
    echo "ERROR: missing namespace argument, make sure to pass namespace, ex: '-n mynamespace'"
    exit 1;
  fi
  if [ -z "${docker_registry}" ]; then
    echo "ERROR: missing docker_registry"
    exit 1;
  fi
  if [ -z "${docker_registry_username}" ]; then
    echo "ERROR: missing docker_registry_username"
    exit 1;
  fi
  if [ -z "${docker_registry_password}" ]; then
    echo "ERROR: missing docker_registry_password"
    exit 1;
  fi
  if [ -z "${docker_registry_user_email}" ]; then
    echo "ERROR: missing docker_registry_user_email"
    exit 1;
  fi

  found=$(oc get secret ${secret_name} -n ${namespace} --ignore-not-found -ojson | jq -r .metadata.name)
  if [[ ${found} != ${secret_name} ]]; then
    echo "Creating secret ${secret_name} on ${namespace} from entitlement key"
    # oc get secret ibm-entitlement-key -n ${namespace} --ignore-not-found
    oc create secret docker-registry ${secret_name} \
      --docker-server=${docker_registry} \
      --docker-username=${docker_registry_username} \
      --docker-password=${docker_registry_password} \
      --docker-email=${docker_registry_user_email} \
      --namespace=${namespace}
    sleep 10
  else
    echo "Secret ${secret_name} already created"
  fi

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
