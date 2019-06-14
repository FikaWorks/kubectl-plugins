#!/usr/bin/env bash
# Delete unused secrets by checking references from env, envFrom, volumes and
# imagePullSecrets.

set -e

namespace_arg=""
while test $# -gt 0
do
  case "$1" in
    -n|--namespace)
      shift
      namespace_arg="--namespace=$1"
      shift
      ;;
    -h|--help)
      echo "Delete secrets that are not being used in a given namespace. It "
      echo "checks against all resources from mounted volumes, env, envFrom and"
      echo "imagePullSecrets."
      echo ""
      echo "Usage:"
      echo "    kubectl prune-secrets [options]"
      echo ""
      echo "Options:"
      echo "    -n, --namespace='': If present, the namespace scope for this CLI request"
      echo "    -h, --help='': Deplay this help"
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

declare -a pod_field_list=(
  "containers[*].envFrom[*].secretRef.name"
  "containers[*].env[*].valueFrom.secretKeyRef.name"
  "imagePullSecrets[*].name"
  "initContainers[*].envFrom[*].secretRef.name"
  "initContainers[*].env[*].valueFrom.secretKeyRef.name"
  "volumes[*].secret.secretName"
)

for field in ${pod_field_list[@]}
do
  cronjob_resources=$(kubectl get cronjobs $namespace_arg \
      -o jsonpath='{.items[*].spec.jobTemplate.spec.template.spec.'${field}'}')
  deploy_resources=$(kubectl get deploy $namespace_arg \
      -o jsonpath='{.items[*].spec.template.spec.'${field}'}')
  job_resources=$(kubectl get jobs $namespace_arg \
      -o jsonpath='{.items[*].spec.template.spec.'${field}'}')
  pod_resources=$(kubectl get pods $namespace_arg \
      -o jsonpath='{.items[*].spec.'${field}'}')
  rs_resources=$(kubectl get rs $namespace_arg \
      -o jsonpath='{.items[*].spec.template.spec.'${field}'}')
  rc_resources=$(kubectl get rc $namespace_arg \
      -o jsonpath='{.items[*].spec.template.spec.'${field}'}')
  sts_resources=$(kubectl get sts $namespace_arg \
      -o jsonpath='{.items[*].spec.template.spec.'${field}'}')

  resources=$(echo "
    ${cronjob_resources}
    ${deploy_resources}
    ${job_resources}
    ${pod_resources}
    ${rc_resources}
    ${rs_resources}
    ${sts_resources}
  " | xargs -n1 | uniq)

  used_resources="${used_resources} ${resources}"
done

# get all secrets
available_resources=$(kubectl get secrets $namespace_arg \
  -o jsonpath='{.items[*].metadata.name}' | xargs -n1 | uniq)

# only keep unused secrets
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
  echo "No resource found."
  exit 0
fi

echo "About to delete the following secrets: ${resource_name_list}"

# confirmation prompt
read -p "Delete listed resources? (yes/no): " -r
if [[ $REPLY =~ ^[Yy]es$ ]]
then
  for resource_name in $resource_name_list
  do
    kubectl delete secret $resource_name $namespace_arg
  done
fi
