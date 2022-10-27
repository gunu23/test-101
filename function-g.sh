#!/bin/bash

### Create namespace
function create_namespace() {
    namespace=$1

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
}

### Create pull secret
function create_pull_secret() {
  secret_name=$1
  namespace=$2
  docker_registry=$3
  docker_registry_username=$4
  docker_registry_password=$5
  docker_registry_user_email=$6

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
}

function wait_for () {
  OBJ_NAME=${1}
  OBJ_TYPE=${2}
  OBJ_NAMESPACE=${3}
  OBJ_READY_STATUS=$4

  echo "Waiting for [${OBJ_NAME}] of type [${OBJ_TYPE}] in namespace [${OBJ_NAMESPACE}] to be in [${OBJ_READY_STATUS}] status"

  SLEEP_TIME="30"
  RUN_LIMIT=200
  i=0
  MAX_RETRY=5

  while true; do

    if ! STATUS=$(oc get ${OBJ_TYPE} -n ${OBJ_NAMESPACE} ${OBJ_NAME} -ojson | jq -c -r '.status.phase'); then
      echo 'Error getting status'
      exit 1
    fi
    echo "Installation status: $STATUS"
    if [ "$STATUS" == ${OBJ_READY_STATUS} ]; then
      break
    fi
    
    if [ "$STATUS" == "Failed" ]; then
        echo '=== Installation has failed ==='
      if [ "$i" -gt "$MAX_RETRY" ]; then
        echo '=== Max retry reached ==='
        exit 1
      else
        echo '=== Retry again ==='
      fi
    fi
    
    echo "Sleeping $SLEEP_TIME seconds..."
    sleep $SLEEP_TIME
    
    (( i++ ))
    if [ "$i" -eq "$RUN_LIMIT" ]; then
      echo 'Timed out'
      exit 1
    fi
  done
}
