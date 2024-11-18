#!/bin/bash

# Variables
REPO_URL="https://github.com/lucasrestrepo/nginx-app-test.git"
BRANCH="main"
NAMESPACE=""
ENVIRONMENT=""
CLUSTER_CONTEXT="default" # Adjust for your local k3s cluster context
HELM_CHART="./helm" # Path to the Helm chart in the repository
MANIFEST_DIR="./kustomize"
RENDERED_YAML="${MANIFEST_DIR}/base/rendered.yaml"
KUBECTL="/usr/local/bin/kubectl"
HELM="/usr/local/bin/helm"

# Functions
usage() {
    echo "Usage: $0 [dev|prd]"
    exit 1
}

# Step 1: Parse Environment Argument
if [ $# -ne 1 ]; then
    usage
fi

ENVIRONMENT=$1

if [ "$ENVIRONMENT" == "dev" ]; then
    NAMESPACE="dev"
elif [ "$ENVIRONMENT" == "prd" ]; then
    NAMESPACE="prd"
else
    usage
fi

# Step 2: Clone Repository
if [ ! -d ./nginx-app-test ]; then
    echo "Cloning repository..."
    git clone -b $BRANCH $REPO_URL
else
    echo "Repository already cloned. Pulling latest changes..."
    cd ./nginx-app-test
    git pull origin $BRANCH
    cd ..
fi

# Step 3: Render Helm Manifests
echo "Rendering Helm chart for $ENVIRONMENT environment..."
$HELM template my-app ./nginx-app-test/$HELM_CHART --namespace $NAMESPACE > $RENDERED_YAML
if [ $? -ne 0 ]; then
    echo "Helm rendering failed. Exiting."
    exit 1
fi

# Step 4: Apply Kustomize Overlay
echo "Applying Kustomize overlay for $ENVIRONMENT..."
kustomize build ${MANIFEST_DIR}/overlays/${ENVIRONMENT} | $KUBECTL apply -f -
if [ $? -ne 0 ]; then
    echo "Kustomize application failed. Exiting."
    exit 1
fi

# Step 5: Rollout Status Check
echo "Checking rollout status for namespace $NAMESPACE..."
$KUBECTL rollout status deployment/my-app --namespace $NAMESPACE
if [ $? -ne 0 ]; then
    echo "Deployment failed. Exiting."
    exit 1
fi

# Step 6: Verify Resources
echo "Verifying resources in namespace $NAMESPACE..."
$KUBECTL get all --namespace $NAMESPACE

echo "Deployment completed successfully for $ENVIRONMENT environment."

