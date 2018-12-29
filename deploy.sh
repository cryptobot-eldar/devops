#! /usr/bin/env bash
set -o errexit
set -o pipefail


#NAMESPACE=$1
K8_CONFIG=$1

NAMESPACE=crypto

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $BASEDIR
echo $BASEDIR

if [ ! -z ${RANCHER_K8S_CONFIG:-} ]; then
  DECODE_OPT="-d"
  unameOut="$(uname -s)"
  case "${unameOut}" in
    Darwin*)    DECODE_OPT="-D";;
    *)          DECODE_OPT="-d"
  esac
  echo ${RANCHER_K8S_CONFIG} | base64 ${DECODE_OPT} > "$BASEDIR/rancher.config"
  export KUBECONFIG="$BASEDIR/rancher.config"
  K8_CONFIG=$KUBECONFIG
else
  export KUBECONFIG=$K8_CONFIG
fi

if [ ! -z ${KUBECONFIG:-} ]; then
  echo "$KUBECONFIG"
else
  echo "ERROR: failed to get KUBECONFIG"
  exit 1;
fi


#kubectl version

kctl() {
   kubectl --namespace "$NAMESPACE" "$@"
}

kubectl get nodes

# delete existing deployments
# Clean Deploy Actions
if [ ! -z ${UPGRADE:-} ]; then
  if [[ "${UPGRADE}" == "false" ]]; then
    kubectl delete deployments,svc,jobs,pod,pvc --all -n "$NAMESPACE"
    kubectl delete pv --all
    # DELAY!
    echo "Waiting for delete namespace."
    sleep 60
  fi
fi


kctl apply -f k8-templates/namespace.yaml
for deploy in k8-templates/*/; do
  echo "$deploy"
  kctl apply -f "$deploy"
done

echo "Waiting for deploy."
