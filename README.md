Kubectl plugins
===============

> Kubectl plugins repository.

|        plugin       | description |
|---------------------|-------------|
| prune               | Delete secrets or configmaps that are not being used in
a given namespace. It checks from mounted volumes, env, envFrom and
imagePullSecrets.

## Getting started

Install [krew](https://krew.dev) to manage Kubectl plugins. Refer to the
[Krew documentation](https://krew.dev) to get started.

```bash
# install the prune plugin
$ kubectl krew install prune

# usage
$ kubectl prune <resource type> <namespace>

# delete unused secrets
$ kubectl prune secrets my-namespace

# delete unused configmaps
$ kubectl prune configmaps my-namespace
```
