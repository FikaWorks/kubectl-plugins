#!/usr/bin/env bash
# Run a CronJob immediately as Job by extracting the Job spec and creating a
# Job instance thereof.

set -e

function usage() {
  echo "DEPRECATION NOTICE:"
  echo "This plugin isn't necessary anymore, the kubectl cli let you create"
  echo "cronjob with the create subcommand:"
  echo "    kubectl create job --from cronjob/my-cronjob my-job"
  echo ""
  echo ""
  echo "Run a CronJob immediately as Job by extracting the Job spec and"
  echo "creating a Job instance thereof."
  echo ""
  echo "Usage:"
  echo "    kubectl exec-cronjob <name> [options]"
  echo ""
  echo "Options:"
  echo "    --context='': If present, the name of the kubeconfig context for this CLI request"
  echo "    -n, --namespace='': If present, the namespace scope for this CLI request"
  echo "    --dry-run: If true, only print the object that would be sent, without sending it."
  echo "    -h, --help: Display this help"
  exit 0
}

if [[ $# -lt 1 ]] || [[ "$1" == "-"* ]]
then
  usage
fi

cronjob_name=$1
dry_run_arg=""
context_arg=""
namespace_arg=""

while test $# -gt 1
do
  case "$2" in
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
      dry_run_arg="--dry-run -o yaml"
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

cron_job=$(kubectl $context_arg get cronjob $namespace_arg -o yaml $cronjob_name)

api_version=$(echo $cron_job | awk '/^apiVersion: / {print $2}')

job="apiVersion: batch/v1
kind: Job"

# extract the cronjob spec and insert the job name
job_spec=$(echo "$cron_job" | awk -v name=$cronjob_name '
  capture && !/^    / { capture=0 }
  capture { sub("^    ", ""); print $0 }
  capture && /metadata:/ && !named { print "  name: " name; named=1 }
  /jobTemplate:$/ { capture=1 }
')

echo "${job}
${job_spec}" | kubectl $context_arg apply -f - $dry_run_arg $namespace_arg
