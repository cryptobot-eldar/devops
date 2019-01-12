#! /usr/bin/env bash
set -o errexit
set -o pipefail

NAMESPACE=${NAMESPACE}

echo "deploy script started to execute..."

export KUBECONFIG=kube.conf
if [ ! -z $KUBECONFIG ]; then
  echo "$KUBECONFIG"
else
  echo "ERROR: failed to get KUBECONFIG"
  exit 1;
fi

kctl() {
   kubectl --namespace "$NAMESPACE" "$@"
}

echo "Kubectl get nodes:"
kctl get nodes

# delete existing deployments
# Clean Deploy Actions
if [ ! -z ${UPGRADE:-} ]; then
  if [[ "${UPGRADE}" == "false" ]]; then
    echo "Executing delete..."
    kubectl delete deployments,svc,jobs,pod,pvc --all -n "$NAMESPACE"
    kubectl delete pv --all
    echo 'Waiting for delete all resources...'
    sleep 30
    kubectl delete namespace $NAMESPACE
    echo 'Waiting for deletion of namespace...'
    sleep 60
  fi
fi

echo "Starting deploying of the application..."
kubectl apply -f cryptobot/k8-templates/namespace.yaml
for deploy in cryptobot/k8-templates/*/; do
  echo "$deploy"
  kctl apply -f "$deploy"
done


