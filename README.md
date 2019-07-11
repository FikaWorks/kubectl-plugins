Kubectl plugins
===============

> Kubectl plugins repository.

|  plugin      | description |
|--------------|-------------|
| prune-unused | Prune secrets or configmaps that are not being used in a given namespace. It checks against all resources from mounted volumes, env, envFrom and imagePullSecrets.

## Getting started

Install [krew](https://krew.dev) to manage Kubectl plugins. Refer to the
[Krew documentation](https://krew.dev) to get started.

```bash
# install the prune-used plugins
$ kubectl krew install prune-unused
```

```bash
Prune unused configmaps/secret resources from a given namespace. It
checks against all resources from mounted volumes, env and envFrom and
imagePullSecrets.

Usage:
    kubectl prune-unused <configmaps|secrets> [options]

Options:
    -n, --namespace='': If present, the namespace scope for this CLI request
    -h, --help='': Display this help
```
