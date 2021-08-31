locals {
  ecr_creds_sync = <<YAML
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ecr-credentials-sync
  namespace: flux-system
rules:
- apiGroups: [""]
  resources:
  - secrets
  verbs:
  - delete
  - create
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ecr-credentials-sync
  namespace: flux-system
subjects:
- kind: ServiceAccount
  name: ecr-credentials-sync
roleRef:
  kind: Role
  name: ecr-credentials-sync
  apiGroup: ""
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ecr-credentials-sync
  namespace: flux-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${var.account}:role/${var.cluster_name}-ecr-sync
---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: ecr-credentials-sync
  namespace: flux-system
spec:
  suspend: false
  schedule: 0 */6 * * *
  failedJobsHistoryLimit: 1
  successfulJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: ecr-credentials-sync
          restartPolicy: Never
          volumes:
          - name: token
            emptyDir:
              medium: Memory
          initContainers:
          - image: amazon/aws-cli
            name: get-token
            imagePullPolicy: IfNotPresent
            # You will need to set the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables if not using
            # IRSA. It is recommended to store the values in a Secret and load them in the container using envFrom.
            # envFrom:
            # - secretRef:
            #     name: aws-credentials
            env:
            - name: REGION
              value: ${var.region} # change this if ECR repo is in a different region
            volumeMounts:
            - mountPath: /token
              name: token
            command:
            - /bin/sh
            - -ce
            - aws ecr get-login-password --region $REGION > /token/ecr-token
          containers:
          - image: bitnami/kubectl
            name: create-secret
            imagePullPolicy: IfNotPresent
            env:
            - name: SECRET_NAME
              value: ecr-credentials
            - name: ECR_REGISTRY
              value: ${var.account}.dkr.ecr.${var.region}.amazonaws.com # fill in the account id and region
            volumeMounts:
            - mountPath: /token
              name: token
            command:
            - /bin/bash
            - -ce
            - |-
              kubectl delete secret --ignore-not-found $SECRET_NAME
              kubectl create secret docker-registry $SECRET_NAME \
                --docker-server="$ECR_REGISTRY" \
                --docker-username=AWS \
                --docker-password="$(</token/ecr-token)"
YAML

  ecr_sync_irsa_roles = var.ecr_sync_job ? [{
    role_name       = "${var.cluster_name}-ecr-sync"
    service_account = "system:serviceaccount:flux-system:ecr-credentials-sync"
    policies_to_assign = [
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    ]
  }] : []
}

resource "kubectl_manifest" "ecr-sync" {
  count     = var.ecr_sync_job ? 1 : 0
  yaml_body = local.ecr_creds_sync
}

resource "github_repository_file" "ecr-sync" {
  count      = var.ecr_sync_job ? 1 : 0
  repository = data.github_repository.main.name
  file       = "${var.flux_target_path}/${local.flux_manifests_path}/ecr-sync.yaml"
  content    = local.ecr_creds_sync
  branch     = var.flux_branch
  lifecycle {
    ignore_changes = [content,sha]
  }
}

