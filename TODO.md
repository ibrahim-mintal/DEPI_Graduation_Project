# TODO: Modify Jenkinsfile for App Deployment

## Tasks
- [x] Update 'Deploy to EKS' stage to include AWS credentials handling using `withCredentials` (credential ID: 'aws-creds')
- [x] Add kubectl apply for namespace (k8s/app_ns.yaml)
- [x] Add kubectl apply for service (k8s/app_service.yaml)
- [x] Add kubectl apply for deployment (k8s/app_deployment.yaml)
- [x] Update deployment image with newly built image using `kubectl set image`
- [x] Verify rollout status after image update
- [x] Test the pipeline to ensure deployment works without permission errors
