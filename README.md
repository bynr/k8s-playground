# k8s-playground

Personal playground with k8s

___

## 1. k3d + argo + localstack + github actions

### Requirements
    docker
    kubectl
    k3d
    argo (client)

### Resources

- [k3d: Little helper to run Rancher Lab's k3s in Docker](https://github.com/rancher/k3d)
- [Argo Workflows: examples](https://argoproj.github.io/argo/examples)
- [localstack: A fully functional local AWS cloud stack](https://github.com/localstack/localstack)
- [Github Actions](https://github.com/features/actions)
- [argo-minikube-github-action](https://github.com/katilp/argo-minikube-github-action)

### Run

```bash
cd argo/

make create_cluster
make switch_context
make install_argo_controller
make setup_localstack

make submit WF_FILENAME=hello-world.yaml
make submit WF_FILENAME=https://raw.githubusercontent.com/argoproj/argo/a24bc944822c9f5eed92c0b5b07284d7992908fa/examples/dag-coinflip.yaml

```

___
## 2. k3d + localstack + Ingress

### Run

```bash
cd ingress/

make create_cluster
make download_images
make import_images
make apply

# To run localstack's web UI, use the image with all dependencies: `localstack-full`.
make test
make upload_to_s3
```

___
## 3. k3d + local path + reload code

Useful for local development without restarting the whole cluster.

### Run
```bash
cd k3d-volume/

make create_cluster
make apply
make logs

# change src code in src/hello-loop/py
make restart_container_v2
make logs

# You will see the code is properly updated in the logs
```

___

# Other resources


- [Principles](https://github.com/ContainerSolutions/kubernetes-examples)
> The examples seek to be:
>
>     As simple as possible to illustrate the functionality
>
>     Self-contained (ie limited to one .yaml file)
>
>     Non-conflicting (eg resource names are unique)
>
>     Clear (eg resource names are verbose and unambiguous)
- [minikube-vs-kind-vs-k3s](https://brennerm.github.io/posts/minikube-vs-kind-vs-k3s.html)
- [k3d-demo](https://github.com/iwilltry42/k3d-demo)
