Kubectl plugins
===============

> Kubectl plugins repository which contains a few helpers that improve the
kubectl experience.

## Available plugins

|  plugin      | description |
|--------------|-------------|
| prune-unused | Prune secrets or configmaps that are not being used in a given namespace. It checks against all resources from mounted volumes, env, envFrom and imagePullSecrets.
| exec-cronjob | Run a CronJob immediately as Job by extracting the Job spec and creating a Job instance thereof.

## Getting started

Install [krew](https://krew.dev) to manage Kubectl plugins. Refer to the
[Krew documentation](https://krew.dev) to get started.

### Prune unused

```bash
# install the prune-used plugins
$ kubectl krew install prune-unused
```

```
Prune unused configmaps/secret resources from a given namespace. It
checks against all resources from mounted volumes, env and envFrom and
imagePullSecrets.

Usage:
    kubectl prune-unused <configmaps|secrets> [options]

Options:
    -l, --selector='': Selector (label query) to filter on, supports '=', '==', and '!='.(e.g. -l key1=value1,key2=value2)"
    --context='': If present, the name of the kubeconfig context for this CLI request
    -n, --namespace='': If present, the namespace scope for this CLI request
    --dry-run: If true, only print the object that would be pruned, without deleting it.
    -h, --help: Display this help
```

### Exec cronjob

> DEPRECATION NOTICE:
> This plugin isn't necessary anymore, the kubectl cli let you create
> cronjob with the create subcommand:
> ```
> $ kubectl create job --from cronjob/my-cronjob my-job
> ```

```bash
# install the exec-cronjob plugins
$ kubectl krew install exec-cronjob
```

```
Run a CronJob immediately as Job by extracting the Job spec and creating a Job
instance thereof.

Usage:
    kubectl exec-cronjob <name> [options]

Options:
    --context='': If present, the name of the kubeconfig context for this CLI request
    -n, --namespace='': If present, the namespace scope for this CLI request
    --dry-run: If true, only print the object that would be sent, without sending it.
    -h, --help: Display this help
```
