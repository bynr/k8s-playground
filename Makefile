NAMESPACE=argo
LATEST_ARGO_JOB = $(shell bash -c  "argo list -n $(NAMESPACE) --no-headers -o name | head -n1")

delete_cluster:
	k3d cluster delete test-cluster || echo

# we use argo namespace for now...
create_cluster:
# only 10Sec to setup everything!
	date
	k3d cluster delete test-cluster || echo
	k3d cluster create test-cluster
	kubectl config use-context k3d-test-cluster
	kubectl create ns argo
	# https://raw.githubusercontent.com/argoproj/argo/master/manifests/
	# quick-start-minimal.yaml
	kubectl apply -n argo -f install.yaml 
	kubectl -n argo apply -f workflow-controller-configmap.yaml
	kubectl create clusterrolebinding serviceaccounts-cluster-admin \
	  --clusterrole=cluster-admin \
	  --group=system:serviceaccounts
	# kubectl create ns de-prod-1
	kubectl apply -n argo -f service-account.yaml
	date
	kubectl apply -n $(NAMESPACE) -f de-prod-config.yaml
	sleep 3

setup_local_stack:
	kubectl apply -n $(NAMESPACE) -f local-stack.yaml


authenticate:
	aws-google-auth -u remy@alpacadb.com -I C00gjp4i8 -S 693697393264 -D -d 14400 -r arn:aws:iam::854338797458:role/de-prod_developer -R ap-northeast-1 --save-failure-html

# You neehd to run authenticate comamad above 
# alsom tou nweed to wait after cretin the preoper serie acccoint
# Error from server (NotFound): serviceaccounts "default" not found	
create_ecr_secrets:
	AWS_ACCOUNT_ID=854338797458	NAMESPACE=$(NAMESPACE) SERVICEACCOUNT=default bash create-ecr-secrets.sh
	AWS_ACCOUNT_ID=854338797458	NAMESPACE=$(NAMESPACE) SERVICEACCOUNT=de-prod-1-pipeline bash create-ecr-secrets.sh

get_pods:
	kubectl get pods -n $(NAMESPACE)

get_jobs:
	kubectl get jobs -n $(NAMESPACE)

.PHONY: describe_pods ## Describe pods setup matching the argo workflow id.
describe_pods:    
	kubectl -n $(NAMESPACE) describe pods


# TEMP
desc_volume:
	kubectl describe pvc -n $(NAMESPACE)

# TEMP
del_volume:
	 kubectl delete pvc -n argo ob-cache-pvc-vm20200813test-cache

.PHONY: list ## List all argo workflows.  
list:     
	argo list -n $(NAMESPACE) 

.PHONY: get ##
get:    
	argo get -n $(NAMESPACE) $(LATEST_ARGO_JOB)

.PHONY: watch ## Watches the most recently submitted argo workflow that matches your experiment ID.
watch:    
	argo watch -n $(NAMESPACE) $(LATEST_ARGO_JOB)

.PHONY: logs ## Prints logs of the most recently submitted argo workflow that matches your experiment ID.
logs:     
	argo logs -n $(NAMESPACE) $(LATEST_ARGO_JOB) --timestamps

.PHONY: follow ## Follows logs of the most recently submitted argo workflow that matches your experiment ID.
follow:   
	argo logs -n $(NAMESPACE) -w $(LATEST_ARGO_JOB) -f --timestamps

delete:   
	argo delete -n $(NAMESPACE) $(LATEST_ARGO_JOB)

# STATUS:OK
submit:
	argo submit -n $(NAMESPACE) --wait hello-world.yaml

# test service account
# STATUS:NOK
# STEP                  TEMPLATE  PODNAME            DURATION  MESSAGE
#  ⚠ hello-world-x5vrf  whalesay  hello-world-x5vrf  0s        pods "hello-world-x5vrf" is forbidden: error looking up service account argo/de-prod-1-pipeline: serviceaccount "de-prod-1-pipeline" not found  
# pods "hello-world-wmkg7" is forbidden: error looking up service account argo/de-prod-1-pipeline: serviceaccount "de-prod-1-pipeline" not found
# does not work as this service account to run the job does not have enough authorizations
submit2:
	argo submit -n $(NAMESPACE) --wait hello-world-2.yaml

# hello-world-q5rfs: 2020-08-14T00:46:30.302045193Z time="2020-08-14T00:46:30.301Z" level=info msg="Starting Workflow Executor" version=21dc23dbe3571f745bd124edd0f0e0c7cf09aced
# hello-world-q5rfs: 2020-08-14T00:46:30.303997615Z time="2020-08-14T00:46:30.303Z" level=info msg="Creating PNS executor (namespace: argo, pod: hello-world-q5rfs, pid: 8, hasOutputs: false)"
# hello-world-q5rfs: 2020-08-14T00:46:30.304016215Z time="2020-08-14T00:46:30.303Z" level=info msg="Executor (version: 21dc23dbe3571f745bd124edd0f0e0c7cf09aced, build_date: 2020-08-14T00:01:20Z) initialized (pod: argo/hello-world-q5rfs) with template:\n{\"name\":\"whalesay\",\"arguments\":{},\"inputs\":{},\"outputs\":{},\"metadata\":{},\"resource\":{\"action\":\"create\",\"manifest\":\"apiVersion: batch/v1\\nkind: Job\\nmetadata:\\n  name: \\\"whalesay-inner-job\\\"\\nspec:\\n  template:\\n    spec:\\n      serviceAccountName: de-prod-1-pipeline\\n      containers:\\n      - name: whalesay-inner\\n        image: docker/whalesay:latest\\n        command: [cowsay]\\n        args: [\\\"hello world\\\"]\\n\",\"successCondition\":\"status.succeeded \\u003e 0\",\"failureCondition\":\"status.failed \\u003e 0\"}}"
# hello-world-q5rfs: 2020-08-14T00:46:30.304029911Z time="2020-08-14T00:46:30.304Z" level=info msg="Loading manifest to /tmp/manifest.yaml"
# hello-world-q5rfs: 2020-08-14T00:46:30.304267164Z time="2020-08-14T00:46:30.304Z" level=info msg="kubectl create -f /tmp/manifest.yaml -o json"
# hello-world-q5rfs: 2020-08-14T00:46:30.731326332Z time="2020-08-14T00:46:30.730Z" level=error msg="executor error: Error from server (Forbidden): error when creating \"/tmp/manifest.yaml\": jobs.batch is forbidden: User \"system:serviceaccount:argo:default\" cannot create resource \"jobs\" in API group \"batch\" in the namespace \"argo\"\ngithub.com/argoproj/argo/errors.New\n\t/go/src/github.com/argoproj/argo/errors/errors.go:49\ngithub.com/argoproj/argo/workflow/executor.(*WorkflowExecutor).ExecResource\n\t/go/src/github.com/argoproj/argo/workflow/executor/resource.go:41\ngithub.com/argoproj/argo/cmd/argoexec/commands.execResource\n\t/go/src/github.com/argoproj/argo/cmd/argoexec/commands/resource.go:45\ngithub.com/argoproj/argo/cmd/argoexec/commands.NewResourceCommand.func1\n\t/go/src/github.com/argoproj/argo/cmd/argoexec/commands/resource.go:22\ngithub.com/spf13/cobra.(*Command).execute\n\t/go/pkg/mod/github.com/spf13/cobra@v1.0.0/command.go:846\ngithub.com/spf13/cobra.(*Command).ExecuteC\n\t/go/pkg/mod/github.com/spf13/cobra@v1.0.0/command.go:950\ngithub.com/spf13/cobra.(*Command).Execute\n\t/go/pkg/mod/github.com/spf13/cobra@v1.0.0/command.go:887\nmain.main\n\t/go/src/github.com/argoproj/argo/cmd/argoexec/main.go:17\nruntime.main\n\t/usr/local/go/src/runtime/proc.go:203\nruntime.goexit\n\t/usr/local/go/src/runtime/asm_amd64.s:1357"
# hello-world-q5rfs: 2020-08-14T00:46:30.754211068Z time="2020-08-14T00:46:30.754Z" level=fatal msg="Error from server (Forbidden): error when creating \"/tmp/manifest.yaml\": jobs.batch is forbidden: User \"system:serviceaccount:argo:default\" cannot create resource \"jobs\" in API group \"batch\" in the namespace \"argo\"\ngithub.com/argoproj/argo/errors.New\n\t/go/src/github.com/argoproj/argo/errors/errors.go:49\ngithub.com/argoproj/argo/workflow/executor.(*WorkflowExecutor).ExecResource\n\t/go/src/github.com/argoproj/argo/workflow/executor/resource.go:41\ngithub.com/argoproj/argo/cmd/argoexec/commands.execResource\n\t/go/src/github.com/argoproj/argo/cmd/argoexec/commands/resource.go:45\ngithub.com/argoproj/argo/cmd/argoexec/commands.NewResourceCommand.func1\n\t/go/src/github.com/argoproj/argo/cmd/argoexec/commands/resource.go:22\ngithub.com/spf13/cobra.(*Command).execute\n\t/go/pkg/mod/github.com/spf13/cobra@v1.0.0/command.go:846\ngithub.com/spf13/cobra.(*Command).ExecuteC\n\t/go/pkg/mod/github.com/spf13/cobra@v1.0.0/command.go:950\ngithub.com/spf13/cobra.(*Command).Execute\n\t/go/pkg/mod/github.com/spf13/cobra@v1.0.0/command.go:887\nmain.main\n\t/go/src/github.com/argoproj/argo/cmd/argoexec/main.go:17\nruntime.main\n\t/usr/local/go/src/runtime/proc.go:203\nruntime.goexit\n\t/usr/local/go/src/runtime/asm_amd64.s:1357"
# ran this afterwards
# WARNING: This allows any user with read access to secrets or the ability to create a pod to access super-user credentials.
# kubectl create clusterrolebinding serviceaccounts-cluster-admin \
#   --clusterrole=cluster-admin \
#   --group=system:serviceaccounts
# STATUS:OK
submit2fix:
	argo submit -n $(NAMESPACE) --wait hello-world-2-bis.yaml


# @NOW here
# private ECR
# time="2020-08-14T00:59:17Z" level=info msg="Updating node hello-world-ngbj6 message: ImagePullBackOff: Back-off pulling image \"854338797458.dkr.ecr.ap-northeast-1.amazonaws.com/alpacadb/data-pipelines.marketstore:0.15.3\""
# time="2020-08-14T00:59:17Z" level=info msg="Skipped pod hello-world-ngbj6 (hello-world-ngbj6) creation: already exists" namespace=argo workflow=hello-world-ngbj6
# time="2020-08-14T00:59:17Z" level=info msg="Workflow update successful" namespace=argo phase=Running resourceVersion=20527 workflow=hello-world-ngbj6
# time="2020-08-14T00:59:18Z" level=info msg="Processing workflow" namespace=argo workflow=hello-world-ngbj6
# time="2020-08-14T00:59:18Z" level=info msg="Skipped pod hello-world-ngbj6 (hello-world-ngbj6) creation: already exists" namespace=argo workflow=hello-world-ngbj6
# time="2020-08-14T00:59:39Z" level=info msg="Processing workflow" namespace=argo workflow=hello-world-ngbj6
# time="2020-08-14T00:59:39Z" level=info msg="Updating node hello-world-ngbj6 message: ErrImagePull: rpc error: code = Unknown desc = failed to pull and unpack image \"854338797458.dkr.ecr.ap-northeast-1.amazonaws.com/alpacadb/data-pipelines.marketstore:0.15.3\": failed to resolve reference \"854338797458.dkr.ecr.ap-northeast-1.amazonaws.com/alpacadb/data-pipelin
# es.marketstore:0.15.3\": unexpected status code [manifests 0.15.3]: 401 Unauthorized"     
# STEP                  TEMPLATE  PODNAME            DURATION  MESSAGE
#  ◷ hello-world-ngbj6  whalesay  hello-world-ngbj6  2m        ImagePullBackOff: Back-off pulling image "854338797458.dkr.ecr.ap-northeast-1.amazonaws.com/alpacadb/data-pipelines.marketstore:0.15.3"
# Need to create secret to Imagepull 
submit3:
	argo submit -n $(NAMESPACE) --wait hello-world-3.yaml

submit3bis:
	argo submit -n $(NAMESPACE) --wait hello-world-3.yaml

submit4:
	argo submit -n $(NAMESPACE) --wait hello-world-4.yaml

submit4fail:
	argo submit -n $(NAMESPACE) hello-world-4-fail.yaml
	$(MAKE) watch

submit_s3:
	argo submit -n $(NAMESPACE) hello-world-s3.yaml
	$(MAKE) watch

submit_s3_local:
	argo submit -n $(NAMESPACE) hello-world-s3-local.yaml
	$(MAKE) watch

# WIP
# kubectl apply -f pv-volume.yaml
# argo submit -n argo  --wait argo-volume-test.yaml


next:
	# fix the logic with namespaces

k9s:
	KUBECONFIG=$(HOME)/.kube/config k9s -l debug -n argo


# WIP
# if running from an external python scripts, I may need 
# TODO: make it a daemon using &? TODO test it 
forward_s3_mock:
	kubectl port-forward deploy/localstack -n argo 31000:31000

forward_aws_ui:
	kubectl port-forward deploy/localstack -n argo 32000:32000

test_s3_mock_from_local:
	AWS_ACCESS_KEY_ID=x AWS_SECRET_ACCESS_KEY=x aws s3api list-buckets --query "Buckets[].Name" --endpoint-url http://localhost:31000
	AWS_ACCESS_KEY_ID=x AWS_SECRET_ACCESS_KEY=x aws s3 ls --endpoint-url http://localhost:31000 s3://test-bucket


MAKEFILE_PATH := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECT_ROOT := $(abspath $(MAKEFILE_PATH)/../../../)
INTEG_TEST_ROOT := $(abspath $(MAKEFILE_PATH)/../)

# requires boto3, awscli, ZipFile, GZipfile etc.
setup_fixtures_from_local:
	DATA_ROOT=$(INTEG_TEST_ROOT)/data_fixtures/s3 \
	AWS_ACCESS_KEY_ID=x AWS_SECRET_ACCESS_KEY=x \
	python3 $(INTEG_TEST_ROOT)/s3_server_fixture.py \
	--action setup --endpoint-url http://localhost:31000 \
	--buckets test-raw-de-prod-alpaca-ai test-processed-de-prod-alpaca-ai test-master-de-prod-alpaca-ai \
	--bucket-prefix phase1

show:
	AWS_ACCESS_KEY_ID=x AWS_SECRET_ACCESS_KEY=x \
	aws s3 ls --recursive --endpoint-url http://localhost:31000 s3://test-raw-de-prod-alpaca-ai 
	AWS_ACCESS_KEY_ID=x AWS_SECRET_ACCESS_KEY=x \
	aws s3 ls --recursive --endpoint-url http://localhost:31000 s3://test-processed-de-prod-alpaca-ai 
	AWS_ACCESS_KEY_ID=x AWS_SECRET_ACCESS_KEY=x \
	aws s3 ls --recursive --endpoint-url http://localhost:31000 s3://test-master-de-prod-alpaca-ai
