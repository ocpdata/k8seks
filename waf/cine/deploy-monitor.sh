#!/usr/bin/env bash
set -euo pipefail

NS_NGINX="nginx"
NS_APP="cine"
POLICY_JSON="$(dirname "$0")/policy-monitor.json"
BUNDLE_TGZ="$(dirname "$0")/cine-monitor.tgz"
MANIFEST="$(dirname "$0")/cine-waf-monitor.yaml"
WAF_COMPILER_IMAGE="private-registry.nginx.com/nap/waf-compiler:5.11.0"

if [[ ! -f "$POLICY_JSON" ]]; then
  echo "No existe $POLICY_JSON"
  exit 1
fi

if [[ -z "${LICENSE_JWT:-}" ]]; then
  echo "Define LICENSE_JWT en el entorno (contenido del jwt, no ruta)."
  exit 1
fi

echo "[1/4] Compilando bundle WAF (transparent monitor)..."
docker run --rm \
  -v "$(pwd):$(pwd)" \
  -v "$(dirname "$POLICY_JSON")":"$(dirname "$POLICY_JSON")" \
  "$WAF_COMPILER_IMAGE" \
  -p "$POLICY_JSON" \
  -o "$BUNDLE_TGZ"

echo "[2/4] Aplicando Policy + VirtualServer..."
kubectl apply -f "$MANIFEST"

echo "[3/4] Copiando bundle a todos los pods nginx-ingress..."
PODS=$(kubectl -n "$NS_NGINX" get pods -l app.kubernetes.io/name=nginx-ingress -o jsonpath='{.items[*].metadata.name}')

if [[ -z "$PODS" ]]; then
  echo "No se encontraron pods nginx-ingress en namespace $NS_NGINX"
  exit 1
fi

for pod in $PODS; do
  echo "  -> $pod"
  kubectl -n "$NS_NGINX" cp "$BUNDLE_TGZ" "$pod:/etc/app_protect/bundles/cine-monitor.tgz" -c nginx-ingress
  kubectl -n "$NS_NGINX" exec "$pod" -c nginx-ingress -- ls -l /etc/app_protect/bundles/cine-monitor.tgz >/dev/null

done

echo "[4/4] Listo. Prueba con:"
echo "  curl -i -H 'Host: cine-waf.example.com' http://<NGINX_LB>/"
echo "  curl -i -H 'Host: cine-waf.example.com' 'http://<NGINX_LB>/?a=%3Cscript%3E'"
echo "En modo monitor (transparent) NO bloquea, pero sí registra eventos WAF."
