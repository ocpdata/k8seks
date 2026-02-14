#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
MANIFEST="${SCRIPT_DIR}/cine-waf-monitor.yaml"

echo "[1/1] Aplicando APPolicy + APLogConf + VirtualServer..."
kubectl apply -f "$MANIFEST"

echo "Listo. Prueba con:"
echo "  curl -i -H 'Host: cine-waf.example.com' http://<NGINX_LB>/"
echo "  curl -i -H 'Host: cine-waf.example.com' 'http://<NGINX_LB>/?a=%3Cscript%3E'"
echo "En modo monitor (transparent) NO bloquea, pero sí registra eventos WAF."
