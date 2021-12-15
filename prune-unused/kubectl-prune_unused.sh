#!/usr/bin/env bash
# Prune unused resources by checking references from env, envFrom, volumes and
# imagePullSecrets.

set -e

label_arg=""
context_arg=""
namespace_arg=""

function usage() {
  echo "Prune unused configmaps/secret resources from a given namespace. It"
  echo "checks against all resources from mounted volumes, env and envFrom and"
  echo "imagePullSecrets."
  echo ""
  echo "Usage:"
  echo "    kubectl prune-unused <configmaps|secrets> [options]"
  echo ""
  echo "Options:"
  echo "    -l, --selector='': Selector (label query) to filter on, supports '=', '==', and '!='.(e.g. -l key1=value1,key2=value2)"
  echo "    --context='': If present, the name of the kubeconfig context for this CLI request"
  echo "    -n, --namespace='': If present, the namespace scope for this CLI request"
  echo "    --dry-run: If true, only print the object that would be pruned, without deleting it."
  echo "    -h, --help: Display this help"
  exit 0
}

if [[ $# -lt 1 ]] || [[ "$1" == "-"* ]]
then
  usage
fi

resource=$1
dry_run="false"

while test $# -gt 1
do
  case "$2" in
    -l|--selector*)
      if [[ $2 == *"="* ]]
      then
        label_arg=${2#=*}
      else
        shift
        label_arg="--selector=${2}"
      fi
      shift
      ;;
    --context*)
      if [[ $2 == *"="* ]]
      then
        context_arg=${2#=*}
      else
        shift
        context_arg="--context=${2}"
      fi
      shift
      ;;
    -n|--namespace*)
      if [[ $2 == *"="* ]]
      then
        namespace_arg=${2#=*}
      else
        shift
        namespace_arg="--namespace=${2}"
      fi
      shift
      ;;
    --dry-run)
      dry_run="true"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      break
      ;;
  esac
done

case "$resource" in
  configmaps|cm|configmap)
    declare -a pod_field_list=(
      "containers[*].envFrom[*].configMapRef.name"
      "containers[*].env[*].valueFrom.configMapKeyRef.name"
      "initContainers[*].envFrom[*].configMapRef.name"
      "initContainers[*].env[*].valueFrom.configMapKeyRef.name"
      "volumes[*].configMap.name"
    )
    ;;
  secrets|secret)
    declare -a pod_field_list=(
      "containers[*].envFrom[*].secretRef.name"
      "containers[*].env[*].valueFrom.secretKeyRef.name"
      "imagePullSecrets[*].name"
      "initContainers[*].envFrom[*].secretRef.name"
      "initContainers[*].env[*].valueFrom.secretKeyRef.name"
      "volumes[*].secret.secretName"
    )
    ;;
  *)
    echo "Resource \"$resource\" is invalid"
    usage
    ;;
esac

for field in ${pod_field_list[@]}
do
  cronjob_resources=$(kubectl $context_arg get cronjobs $label_arg $namespace_arg \
      -o jsonpath='{.items[*].spec.jobTemplate.spec.template.spec.'${field}'}')
  deploy_resources=$(kubectl $context_arg get deploy $label_arg $namespace_arg \
      -o jsonpath='{.items[*].spec.template.spec.'${field}'}')
  ds_resources=$(kubectl $context_arg get ds $label_arg $namespace_arg \
      -o jsonpath='{.items[*].spec.template.spec.'${field}'}')
  job_resources=$(kubectl $context_arg get jobs $label_arg $namespace_arg \
      -o jsonpath='{.items[*].spec.template.spec.'${field}'}')
  pod_resources=$(kubectl $context_arg get pods $label_arg $namespace_arg \
      -o jsonpath='{.items[*].spec.'${field}'}')
  rs_resources=$(kubectl $context_arg get rs $label_arg $namespace_arg \
      -o jsonpath='{.items[*].spec.template.spec.'${field}'}')
  rc_resources=$(kubectl $context_arg get rc $label_arg $namespace_arg \
      -o jsonpath='{.items[*].spec.template.spec.'${field}'}')
  sts_resources=$(kubectl $context_arg get sts $label_arg $namespace_arg \
      -o jsonpath='{.items[*].spec.template.spec.'${field}'}')

  resources=$(echo "
    ${cronjob_resources}
    ${deploy_resources}
    ${ds_resources}
    ${job_resources}
    ${pod_resources}
    ${rc_resources}
    ${rs_resources}
    ${sts_resources}
  " | xargs -n1 | uniq)

  used_resources="${used_resources} ${resources}"
done

# get all resources
available_resources=$(kubectl $context_arg get $resource $label_arg $namespace_arg \
  -o jsonpath='{.items[*].metadata.name}' | xargs -n1 | uniq)

# only keep unused resources
resource_name_list=""
for available_name in $available_resources
do
  delete=true
  for resource_name in $used_resources
  do
    if [ "$available_name" == "$resource_name" ]
    then
      delete=false
      break
    fi
  done

  if [ "$delete" == "true" ]
  then
    resource_name_list="${available_name} ${resource_name_list}"
  fi
done

if [ "$resource_name_list" == "" ]
then
  echo "No unused resource(s) found."
  exit 0
fi

for resource_name in $resource_name_list
do
  if [ "$dry_run" == "true" ]
  then
    echo "${resource} ${resource_name} deleted (dry run)"
  else
    kubectl $context_arg delete $resource $resource_name $label_arg $namespace_arg
  fi
done
