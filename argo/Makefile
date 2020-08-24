NAMESPACE = argo
LATEST_ARGO_WF = $(shell bash -c  "argo list -n $(NAMESPACE) --no-headers -o name | head -n1")

# Setup

install_k3d:
	curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | TAG=v3.0.0 bash

install_kubectl:
	curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
	chmod a+x /usr/local/bin/kubectl

delete_cluster:
	k3d cluster delete test-cluster || echo

create_cluster:
	k3d cluster create test-cluster

switch_context:
	kubectl config use-context k3d-test-cluster

# For linux only!
install_argo:
	# Download the binary
	curl -sLO https://github.com/argoproj/argo/releases/download/v2.10.0-rc3/argo-linux-amd64
	# Make binary executable
	chmod +x argo-linux-amd64
	# Move binary to path
	mkdir $(HOME)/bin/
	mv ./argo-linux-amd64 $(HOME)/bin/argo

create_namespace:
	kubectl create ns $(NAMESPACE)

setup_argo_controller:
	# Latest config as of 2020-08-23 
	kubectl apply -n $(NAMESPACE) --wait -f https://raw.githubusercontent.com/argoproj/argo/master/manifests/install.yaml
	# Modify the containerRuntimeExecutor
	kubectl -n $(NAMESPACE) apply --wait -f workflow-controller-configmap.yaml
	kubectl create clusterrolebinding serviceaccounts-cluster-admin \
	  --clusterrole=cluster-admin \
	  --group=system:serviceaccounts
	# Create a custom service account
	kubectl apply -n $(NAMESPACE) --wait -f service-account.yaml

setup_localstack:
	kubectl apply -n $(NAMESPACE) --wait -f local-stack.yaml

# Localstack utils

forward_localstack_s3:
	kubectl port-forward deploy/localstack -n $(NAMESPACE) 31000:31000

forward_localstack_s3_bg:
	kubectl port-forward deploy/localstack -n $(NAMESPACE) 31000:31000 &

forward_localstack_aws_ui:
	kubectl port-forward deploy/localstack -n $(NAMESPACE) 32000:32000

wait_localstack:
	kubectl wait pods --timeout=60s -n $(NAMESPACE) --for=condition=Ready -l app=localstack

# Argo utils

list:     
	argo list -n $(NAMESPACE) 

get:    
	argo get -n $(NAMESPACE) $(LATEST_ARGO_WF)

watch:    
	argo watch -n $(NAMESPACE) $(LATEST_ARGO_WF)

logs:     
	argo logs -n $(NAMESPACE) $(LATEST_ARGO_WF) --timestamps

follow:   
	argo logs -n $(NAMESPACE) -w $(LATEST_ARGO_WF) -f --timestamps

delete:   
	argo delete -n $(NAMESPACE) $(LATEST_ARGO_WF)

WF_FILENAME ?= hello-world.yaml
submit:
	argo submit -n $(NAMESPACE) --wait $(WF_FILENAME)

wait_argo:
	kubectl wait pods --timeout=60s -n $(NAMESPACE) --for=condition=Ready -l app=argo-server
	kubectl wait pods --timeout=60s -n $(NAMESPACE) --for=condition=Ready -l app=workflow-controller

# kubectl utils

get_nodes:
	kubectl get nodes

get_pods:
	kubectl get pods -n $(NAMESPACE)

get_jobs:
	kubectl get jobs -n $(NAMESPACE)

describe_pods:    
	kubectl -n $(NAMESPACE) describe pods


# S3 utils

setup_data_fixture:
	aws s3api create-bucket --bucket test-bucket --region ap-northeast-1 --endpoint-url http://localhost:31000
	aws s3api list-buckets --query "Buckets[].Name" --endpoint-url http://localhost:31000
	aws s3 sync ../data s3://test-bucket --endpoint-url http://localhost:31000