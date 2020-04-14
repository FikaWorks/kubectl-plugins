#!/usr/bin/env bash

set -e

function usage() {
  echo "Trigger a Rolling Restart of a deployment's pods."
  echo ""
  echo "Usage:"
  echo "    kubectl rolling_restart <deployment> [options]"
  echo ""
  echo "Options:"
  echo "    -n, --namespace='': If present, the namespace scope for this CLI request"
  echo "    -d, --delay='': the delay to wait between each pod being restarted, in seconds [default:5]"
  echo "    -w, --wait: If set, wait for the resource to be deleted before continuing [default]"
  echo "    --no-wait: If set, do not wait for the resource to be deleted before continuing"
  echo "    -h, --help: Display this help"
  exit 0
}

if [[ $# -lt 1 ]] || [[ "$1" == "-"* ]]
then
  usage
fi

deploy_name=$1
namespace_arg=""
delay_arg=5
wait_arg="true"

while test $# -gt 1
do
  case "$2" in
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
    -w|--wait)
      wait_arg="true"
      shift
      ;;
    --no-wait)
      wait_arg="false"
      shift
      ;;
    -h|--help)
      usage
      ;;
    -d|--delay*)
      if [[ $2 == *"="* ]]
      then
        delay_arg=${2#=*}
      else
        shift
        delay_arg="${2}"
      fi
      shift
      ;;
    *)
      break
      ;;
  esac
done

selector=$(kubectl describe $namespace_arg deploy $deploy_name | awk '/Selector/ {print $2}')
echo "restarting pods with the following selector(s): ${selector}"
pods=$(kubectl get po $namespace_arg -l $selector | awk '!/NAME/ {print $1}')
echo "No. Pods: ${#pods[@]}"
for pod in $pods; do
    sleep $delay_arg
    kubectl delete pod $namespace_arg $pod --wait=$wait_arg
done
