#!/usr/bin/env bash
# Krew plugin which delete secrets or configmaps that are not being used in a
# given namespace. It checks from mounted volumes, env, envFrom and
# imagePullSecrets.
#
# Usage:
#   ./kubectl-prune.sh [RESOURCE (secrets|configmaps)] [NAMESPACE]
# Example:
#   ./kubectl-prune.sh secrets my-namespace

set -e

resource=$1
namespace=$2

case "$resource" in
"secrets" | "secret")
    # get all secrets
    available_resources=$(kubectl get secrets -n $namespace \
      -o jsonpath='{.items[*].metadata.name}' | xargs -n1 | uniq)

    # get secrets mounted as volume
    secrets_volumes_pods=$(kubectl get pods -n $namespace \
      -o jsonpath='{.items[*].spec.volumes[*].secret.secretName}')
    secrets_volumes_cronjobs=$(kubectl get cronjobs -n $namespace \
      -o jsonpath='{.items[*].spec.jobTemplate.spec.template.spec.volumes[*].secret.secretName}')

    # get secrets mounted as environment variable from env
    secrets_env_pods=$(kubectl get pods -n $namespace \
      -o jsonpath='{.items[*].spec.containers[*].env[*].valueFrom.secretKeyRef.name}')
    secrets_env_cronjobs=$(kubectl get cronjobs -n $namespace \
      -o jsonpath='{.items[*].spec.jobTemplate.spec.template.spec.containers[*].env.valueFrom.secretKeyRef.name}')

    # get secrets mounted as environment variable from envFrom
    secrets_envfrom_pods=$(kubectl get pods -n $namespace \
      -o jsonpath='{.items[*].spec.containers[*].envFrom[*].secretRef.name}')
    secrets_envfrom_cronjobs=$(kubectl get cronjobs -n $namespace \
      -o jsonpath='{.items[*].spec.jobTemplate.spec.template.spec.containers[*].envFrom[*].secretRef.name}')

    # get secrets from image pull secrets
    secrets_image_pull_secrets=$(kubectl get pods -n $namespace \
      -o jsonpath='{.items[*].spec.imagePullSecrets[*].name}')

    used_resource=$(echo "
      ${secrets_volumes_pods}
      ${secrets_volumes_cronjobs}
      ${secrets_env_pods}
      ${secrets_env_cronjobs}
      ${secrets_envfrom_pods}
      ${secrets_envfrom_cronjobs}
      ${secrets_image_pull_secrets}
    " | xargs -n1 | uniq)
    ;;
"configmaps" | "configmap" | "cm")
    # get all configmaps
    available_resources=$(kubectl get configmaps -n $namespace \
      -o jsonpath='{.items[*].metadata.name}' | xargs -n1 | uniq)

    # get configmaps mounted as volume
    configmaps_volumes_pods=$(kubectl get pods -n $namespace \
      -o jsonpath='{.items[*].spec.volumes[*].configMap.name}')
    configmaps_volumes_cronjobs=$(kubectl get cronjobs -n $namespace \
      -o jsonpath='{.items[*].spec.jobTemplate.spec.template.spec.volumes[*].configMap.name}')

    # get secrets mounted as environment variable from env
    configmaps_env_pods=$(kubectl get pods -n $namespace \
      -o jsonpath='{.items[*].spec.containers[*].env[*].valueFrom.configMapKeyRef.name}')
    configmaps_env_cronjobs=$(kubectl get cronjobs -n $namespace \
      -o jsonpath='{.items[*].spec.jobTemplate.spec.template.spec.containers[*].env.valueFrom.configMapKeyRef.name}')

    # get secrets mounted as environment variable from envFrom
    configmaps_envfrom_pods=$(kubectl get pods -n $namespace \
      -o jsonpath='{.items[*].spec.containers[*].envFrom[*].configMapRef.name}')
    configmaps_envfrom_cronjobs=$(kubectl get cronjobs -n $namespace \
      -o jsonpath='{.items[*].spec.jobTemplate.spec.template.spec.containers[*].envFrom[*].configMapRef.name}')

    used_resource=$(echo "
      ${configmaps_volumes_pods}
      ${configmaps_volumes_cronjobs}
      ${configmaps_env_pods}
      ${configmaps_env_cronjobs}
      ${configmaps_envfrom_pods}
      ${configmaps_envfrom_cronjobs}
      ${configmaps_image_pull_secrets}
    " | xargs -n1 | uniq)
  ;;
*)
  echo "Resource ${resource} not found."
  echo "Usage:"
  echo "  kubectl prune [RESOURCE (secrets|configmaps)] [NAMESPACE]"
  echo "Example:"
  echo "  kubectl prune secrets my-namespace"
  exit 1
  ;;
esac

resource_name_list=""
for available_name in $available_resources
do
  delete=true
  for resource_name in $used_resource
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

echo "About to delete the following resources: ${resource_name_list}"

# confirmation prompt
read -p "Delete listed resources? (yes/no): " -r
if [[ $REPLY =~ ^[Yy]es$ ]]
then
  for resource_name in $resource_name_list
  do
    kubectl delete $resource $resource_name -n $namespace
  done
fi
