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


