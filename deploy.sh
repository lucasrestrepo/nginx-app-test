#!/bin/bash

# Variables
ENV=$1
NAMESPACE=""
KUSTOMIZE_DIR="./kustomize"
HELM_CHART="./helm"
RENDERED_YAML="${KUSTOMIZE_DIR}/base/rendered.yaml"

# Validate environment argument
if [ "$ENV" == "dev" ]; then
    NAMESPACE="dev"
elif [ "$ENV" == "prd" ]; then
    NAMESPACE="prd"
else
    echo "Usage: $0 [dev|prd]"
    exit 1
fi

# Create namespace if it doesn't exist
kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE

# Render Helm templates
echo "Rendering Helm templates for $ENV environment..."
helm template my-app $HELM_CHART --namespace $NAMESPACE > $RENDERED_YAML
if [ $? -ne 0 ]; then
    echo "Failed to render Helm templates. Exiting."
    exit 1
fi

# Apply Kustomize overlay
echo "Applying Kustomize overlay for $ENV environment..."
kustomize build $KUSTOMIZE_DIR/overlays/$ENV | kubectl apply -f - --namespace $NAMESPACE
if [ $? -ne 0 ]; then
    echo "Failed to apply Kustomize overlay. Exiting."
    exit 1
fi

# Verify deployment
echo "Checking rollout status for namespace $NAMESPACE..."
kubectl rollout status deployment/my-app --namespace $NAMESPACE
if [ $? -ne 0 ]; then
    echo "Deployment failed. Exiting."
    exit 1
fi

echo "Deployment to $ENV namespace completed successfully!"

