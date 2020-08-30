MAKEFILE_PATH := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECT_ROOT := $(abspath $(MAKEFILE_PATH)/../)
NAMESPACE = default

# k3d cluster

create_cluster:
	# Mounts local src code directory to /data-fixtures in all nodes (for testing)"
	k3d cluster create --wait --volume $(PROJECT_ROOT)/k3d-volume/src:/src@all test-cluster

delete_cluster:
	k3d cluster delete test-cluster || echo

# k8s Job

PODNAME=$(shell bash -c  "kubectl get pods hello-loop --no-headers -o name | head -n1") 

apply:
	kubectl apply -f deploy.yaml

describe:
	kubectl get pv
	kubectl get pvc
	kubectl describe pv/task-pv-volume
	kubectl describe pvc/task-pv-claim 
	kubectl describe pods 

wait:
	# kubectl wait --timeout=60s --for=condition=complete jobs/hello-loop
	
logs:
	kubectl get deployment hello-loop
	kubectl describe pods hello-loop
	kubectl describe pods hello-loop
	kubectl logs -l app=hello-loop --tail=100 --timestamps=true

delete:
	kubectl delete pods hello-loop 
	# If stuck, uncomment line below
	# https://github.com/kubernetes/kubernetes/issues/69697
	# kubectl patch pvc task-pv-claim -p '{"metadata":{"finalizers":null}}' || echo
	kubectl delete pvc task-pv-claim || echo
	kubectl delete pv task-pv-volume || echo

bash:
	kubectl exec -it $(PODNAME) -c pi -- /bin/sh

# Utils

restart_container_v1:
	# Thw following does not work: /bin/sh -c "kill 1"
	kubectl exec $(PODNAME) -c pi -- /bin/sh -c "ps -af | awk '{print $1}' | xargs kill -9"

restart_container_v2:
	kubectl scale deployment hello-loop --replicas=0
	kubectl get pods
	kubectl scale deployment hello-loop --replicas=1
	kubectl get pods