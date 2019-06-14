Kubectl plugins
===============

> Kubectl plugins repository.

|        plugin    | description |
|------------------|-------------|
| prune-configmaps | Delete configmaps that are not being used in a given namespace. It checks against all resources from mounted volumes, env and envFrom.
| prune-secrets    | Delete secrets that are not being used in a given namespace. It checks against all resources from mounted volumes, env, envFrom and imagePullSecrets.

## Getting started

Install [krew](https://krew.dev) to manage Kubectl plugins. Refer to the
[Krew documentation](https://krew.dev) to get started.

```bash
# install the prune-configmaps and prune-secrets plugins
$ kubectl krew install prune-configmaps
$ kubectl krew install prune-secrets
```

### Prune configmaps usage

```bash
$ kubectl prune-configmaps -h
Delete configmaps that are not being used in a given namespace. It
checks against all resources from mounted volumes, env and envFrom.

Usage:
    kubectl prune-configmaps [options]

Options:
    -n, --namespace='': If present, the namespace scope for this CLI request
    -h, --help='': Deplay this help
```

### prune-secrets usage

```bash
$ kubectl prune-secrets -h
Delete secrets that are not being used in a given namespace. It
checks against all resources from mounted volumes, env, envFrom and
imagePullSecrets.

Usage:
    kubectl prune-secrets [options]

Options:
    -n, --namespace='': If present, the namespace scope for this CLI request
    -h, --help='': Deplay this help
```
