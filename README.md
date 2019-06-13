Krew prune plugin
=================

> Krew plugin which delete secrets or configmaps that are not being used in a
given namespace. It checks from mounted volumes, env, envFrom and
imagePullSecrets.

## Getting started

Install as a kubectl plugin using [krew](https://krew.dev). Refer to the
[Krew documentation](https://krew.dev) to get started.

```bash
$ kubectl krew install prune

# Usage:
$ kubectl prune <resource type> <namespace>

# delete unused secrets
$ kubectl prune secrets my-namespace

# delete unused configmaps
$ kubectl prune configmaps my-namespace
```
