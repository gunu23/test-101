#!/bin/bash
########################################################################
# must-gather.sh
#
# Gather any and all materials that will be useful in debugging problems
# with the DataPower Operator.
########################################################################


print_help() {
cat <<EOF
must-gather.sh

Collect logs, describes, and yamls of all resources in a namespace which are
related to a particular DataPowerService instance.

Optional parameters:
    -d, --datapowerservice          The name of the DataPowerService instance that should be gathered.
                                    If not specified, only the DataPower Operator resources will be gathered.
    -n, --namespace                 The namespace to gather from. If no value is provided, the namespace 
                                    set in kubeconfig will be used.
    -o, --output                    The output directory in which the tar.gz result is stored.
                                    If no directory is specified, the current directory will be used.
    --skip-compress                 Skip compression of output directory and retain raw output.
    -h, --help                      Print this help message.
EOF
}


# Verify that kubectl is installed
if ! which kubectl > /dev/null; then
    echo "kubectl not found, exiting"
    exit 1
fi

# Param init
serviceName=""
namespace=""
outDir=""
skipCompress=""

# Argument parsing
while [ $# -gt 0 ]; do
    case $1 in
        -o | --output)
            outDir="$2"
            shift 2
            ;;
        -h | --help)
            print_help
            exit 0
            ;;
        -n | --namespace)
            namespace="$2"
            shift 2
            ;;
        -d | --datapowerservice)
            serviceName="$2"
            shift 2
            ;;
        --skip-compress)
            skipCompress="true"
            shift
            ;;
        *)
            echo "Unrecognized parameter: $1"
            print_help
            exit 1
            ;;
    esac
done


# Verify arguments

if [ -z "$namespace" ]; then
    namespace="$(kubectl config get-contexts | grep $(kubectl config current-context) | tr -s [:space:] | cut -d' ' -f 5)"

    if [ -z "$namespace" ]; then
        namespace="default"
    fi
fi
echo "Using namespace: $namespace"

if [ -z "$outDir" ]; then
    outDir="$(pwd)"
fi


# Set directory structure
if [ -z "$serviceName" ]; then
    tarName="datapower-operator-must-gather"
else
    tarName="datapower-operator-${serviceName}-must-gather"
fi
topDir="$outDir/$tarName"
operandDir="$topDir/operand"
operatorDir="$topDir/operator"
operandLogs="$operandDir/logs"
operatorLogs="$operatorDir/logs"
operandDescribes="$operandDir/describes"
operatorDescribes="$operatorDir/describes"
operandYamls="$operandDir/yamls"
operatorYamls="$operatorDir/yamls"


for dir in $operandLogs $operatorLogs \
           $operandDescribes $operatorDescribes \
           $operandYamls $operatorYamls; do

    mkdir -p $dir

done

# Get CR related resources if a service was specified
if [ ! -z "$serviceName" ]; then

    # Get replica count from DataPowerService object
    replicas=$(kubectl -n $namespace get datapowerservice $serviceName -o=jsonpath={.spec.replicas})
    
    # Iterate over related DataPower pods
    for i in $(seq 0 $((replicas - 1))); do
    
        podName="$serviceName-$i"
    
        kubectl -n $namespace describe pod $podName > $operandDescribes/${podName}.desc
        kubectl -n $namespace logs $podName > $operandLogs/${podName}.log
        kubectl -n $namespace logs --previous $podName > $operandLogs/${podName}_prev.log
        kubectl -n $namespace get pod $podName -o yaml > $operandYamls/${podName}.yaml
    
    done

    # Get statefulset info
    kubectl -n $namespace get statefulset $serviceName -o yaml > $operandYamls/StatefulSet.yaml
    kubectl -n $namespace describe statefulset $serviceName > $operandDescribes/StatefulSet.desc
    
    # Get CRDs
    kubectl get crds datapowerservices.datapower.ibm.com -o yaml > $operatorYamls/DataPowerService_CRD.yaml
    kubectl get crds datapowermonitors.datapower.ibm.com -o yaml > $operatorYamls/DataPowerMonitor_CRD.yaml
    
    # Get CRs
    kubectl -n $namespace get datapowerservice $serviceName -o yaml > $operatorYamls/DataPowerService_CR.yaml
    kubectl -n $namespace get datapowermonitor $serviceName -o yaml > $operatorYamls/DataPowerMonitor_CR.yaml
    kubectl -n $namespace describe datapowerservice $serviceName > $operatorDescribes/DataPowerService_CR.desc
    kubectl -n $namespace describe datapowermonitor $serviceName > $operatorDescribes/DataPowerMonitor_CR.desc
fi

# Get Operator resources
while IFS= read -r line; do
    podName="$(echo "$line" | tr -s [:space:] | cut -d ' ' -f 1)"
    podSuffix="$(echo $podName | sed 's|datapower-operator-||g')"
    kubectl -n $namespace logs $podName > $operatorLogs/DataPowerOperatorPod_${podSuffix}.log
    kubectl -n $namespace logs --previous $podName > $operatorLogs/DataPowerOperatorPod_${podSuffix}_prev.log
    kubectl -n $namespace get pod $podName -o yaml > $operatorYamls/DataPowerOperatorPod_${podSuffix}.yaml
    kubectl -n $namespace describe pod $podName > $operatorDescribes/DataPowerOperatorPod_${podSuffix}.desc
done <<< "$(kubectl -n $namespace get pods | grep 'datapower-operator' | grep -v 'datapower-operator-conversion-webhook')"

kubectl -n $namespace get deployment datapower-operator -o yaml > $operatorYamls/DataPowerOperatorDeployment.yaml
kubectl -n $namespace describe deployment datapower-operator > $operatorDescribes/DataPowerOperatorDeployment.desc

# Get webhook configurations
kubectl get mutatingwebhookconfigurations ${namespace}.datapowerservices.defaulter.datapower.ibm.com -o yaml > $operatorYamls/DefaultingWebhookConfiguration_DataPowerService.yaml
kubectl get validatingwebhookconfigurations ${namespace}.datapowerservices.validator.datapower.ibm.com -o yaml > $operatorYamls/ValidatingWebhookConfiguration_DataPowerService.yaml
kubectl get mutatingwebhookconfigurations ${namespace}.datapowermonitors.defaulter.datapower.ibm.com -o yaml > $operatorYamls/DefaultingWebhookConfiguration_DataPowerMonitor.yaml
kubectl get validatingwebhookconfigurations ${namespace}.datapowermonitors.validator.datapower.ibm.com -o yaml > $operatorYamls/validatingWebhookConfiguration_DataPowerMonitor.yaml
kubectl describe mutatingwebhookconfigurations ${namespace}.datapowerservices.defaulter.datapower.ibm.com > $operatorDescribes/DefaultingWebhookConfiguration_DataPowerService.desc
kubectl describe validatingwebhookconfigurations ${namespace}.datapowerservices.validator.datapower.ibm.com > $operatorDescribes/ValidatingWebhookConfiguration_DataPowerService.desc
kubectl describe mutatingwebhookconfigurations ${namespace}.datapowermonitors.defaulter.datapower.ibm.com > $operatorDescribes/DefaultingWebhookConfiguration_DataPowerMonitor.desc
kubectl describe validatingwebhookconfigurations ${namespace}.datapowermonitors.validator.datapower.ibm.com > $operatorDescribes/ValidatingWebhookConfiguration_DataPowerMonitor.desc

# Get conversion webhook
# Find where the conversion webhook lives
convNamespace=""
for ns in $(kubectl get namespace -o=jsonpath={.items[*].metadata.name}); do
    if kubectl -n $ns get deployment datapower-operator-conversion-webhook >/dev/null 2>&1; then
        convNamespace=$ns
        break
    fi
done

if [ ! -z "$convNamespace" ]; then
    kubectl -n $convNamespace get deployment datapower-operator-conversion-webhook -o yaml > $operatorYamls/DataPowerOperatorConversionDeployment.yaml
    kubectl -n $convNamespace describe deployment datapower-operator-conversion-webhook > $operatorDescribes/DataPowerOperatorConversionDeployment.desc

    convPodName="$(kubectl -n $convNamespace get pod | grep 'datapower-operator-conversion-webhook' | cut -d ' ' -f 1)"
    kubectl -n $convNamespace get pod $convPodName -o yaml > $operatorYamls/DataPowerOperatorConversionPod.yaml
    kubectl -n $convNamespace describe pod $convPodName > $operatorDescribes/DataPowerOperatorConversionPod.desc
    kubectl -n $convNamespace logs $convPodName > $operatorLogs/DataPowerOperatorConversionPod.log
    kubectl -n $convNamespace logs --previous $convPodName > $operatorLogs/DataPowerOperatorConversionPod_prev.log
fi

# Get OLM materials
# Check for subscription in namespace

if kubectl -n $namespace get subscription | grep datapower-operator; then
    # Operator was deployed via OLM
    subName="$(kubectl -n $namespace get subscription | grep datapower-operator | tr -s [:space:] | cut -d' ' -f 1)"
    kubectl -n $namespace get subscription $subName -o yaml > $operatorYamls/DataPowerOperatorSubscription.yaml
    kubectl -n $namespace describe subscription $subName > $operatorDescribes/DataPowerOperatorSubscription.desc

    catName="$(kubectl -n openshift-marketplace get catalogsource | grep datapower-operator | tr -s [:space:] | cut -d' ' -f 1)"
    kubectl -n openshift-marketplace get catalogsource $catName -o yaml > $operatorYamls/DataPowerOperatorCatalog.yaml
    kubectl -n openshift-marketplace describe catalogsource $catName > $operatorDescribes/DataPowerOperatorCatalog.desc

    while IFS= read -r line; do
        planName="$(echo $line | tr -s [:space:] | cut -d ' ' -f 1)"
        planSuffix="$(echo $planName | sed 's|install-||g')"
        kubectl -n $namespace get installplan $planName -o yaml > $operatorYamls/DataPowerInstallPlan_${planSuffix}.yaml
        kubectl -n $namespace describe installplan $planName > $operatorDescribes/DataPowerInstallPlan_${planSuffix}.desc
    done <<< "$(kubectl get installplan | grep 'datapower-operator')"

    while IFS= read -r line; do
        csvName="$(echo $line | tr -s [:space:] | cut -d ' ' -f 1)"
        csvSuffix="$(echo $csvName | sed 's|datapower-operator\.||g')"
        kubectl -n $namespace get csv $csvName -o yaml > $operatorYamls/DataPowerOperatorCSV_${csvSuffix}.yaml
        kubectl -n $namespace describe csv $csvName > $operatorDescribes/DataPowerOperatorCSV_${csvSuffix}.desc
    done <<< "$(kubectl get csv | grep 'datapower-operator')"

    opgroupName="$(kubectl -n $namespace get operatorgroup | grep 'datapower-operator' | tr -s [:space:] | cut -d ' ' -f 1)"
    kubectl -n $namespace get operatorgroup $opgroupName -o yaml > $operatorYamls/DataPowerOperatorGroup.yaml
    kubectl -n $namespace describe operatorgroup $opgroupName > $operatorDescribes/DataPowerOperatorGroup.desc
fi

if [[ "$skipCompress" != "true" ]]; then
    tar -C $outDir -czf ${tarName}.tar.gz $tarName
    rm -rf ${outDir}/${tarName}
fi
