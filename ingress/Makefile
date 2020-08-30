MAKEFILE_PATH := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECT_ROOT := $(abspath $(MAKEFILE_PATH)/../)
NAMESPACE = default

create_cluster:
	# Mounts local data directory to /data-fixtures in all nodes (for testing)"
	k3d cluster create --port 5000:80@loadbalancer --wait --volume $(PROJECT_ROOT)/data:/data-fixtures@all test-cluster

delete_cluster:
	k3d cluster delete test-cluster || echo

apply:
	kubectl apply --wait -f local-stack.yaml

wait:
	kubectl wait pods --timeout=60s --for=condition=Ready -l app=localstack

test:
	kubectl get ingress
	curl http://s3.localhost:5000 || echo
	curl http://aws.localhost:5000 || echo

get_nodes:
	kubectl get nodes

get_pods:
	kubectl get pods

describe_pods:    
	kubectl describe pods

upload_to_s3:
	aws s3api create-bucket --bucket test-bucket --region ap-northeast-1 --endpoint-url http://s3.localhost:5000
	aws s3api list-buckets --query "Buckets[].Name" --endpoint-url http://s3.localhost:5000
	aws s3 sync ../data s3://test-bucket --endpoint-url http://s3.localhost:5000

download_images:
	date
	docker pull localstack/localstack:0.11.4
	date

import_images:
	date
	k3d image import -c test-cluster localstack/localstack:0.11.4
	date

forward_s3:
	kubectl port-forward deploy/localstack 31000:31000

forward_aws_ui:
	kubectl port-forward deploy/localstack 32000:32000

