# Cine + WAF en modo monitoreo (transparent)

Este flujo habilita una policy WAF para `cine` en modo **solo monitoreo**.

## Archivos

- `policy-monitor.json`: policy base con `enforcementMode: transparent`
- `cine-waf-monitor.yaml`: recursos `Policy` + `VirtualServer`
- `deploy-monitor.sh`: compila bundle, aplica manifests y copia bundle a pods NIC

## Prerrequisitos

- WAF ya habilitado en NGINX Ingress Controller (`controller.appprotect.enable=true`, `controller.appprotect.v5=true`)
- Docker instalado localmente
- Acceso al registro `private-registry.nginx.com`
- `kubectl` configurado al cluster

## Ejecutar

Desde la raíz del repo:

```bash
chmod +x waf/cine/deploy-monitor.sh
export LICENSE_JWT='<tu_jwt>'
./waf/cine/deploy-monitor.sh
```

## Prueba

Obtén el LB del servicio de NGINX:

```bash
kubectl -n nginx get svc
```

Luego prueba:

```bash
curl -i -H 'Host: cine-waf.example.com' http://<NGINX_LB>/
curl -i -H 'Host: cine-waf.example.com' 'http://<NGINX_LB>/?a=%3Cscript%3E'
```

En `transparent`, el request malicioso **no se bloquea**; debe quedar registrado en logs WAF.

## Ver logs WAF

```bash
kubectl -n nginx logs -l app.kubernetes.io/name=nginx-ingress -c nginx-ingress --tail=200 | grep -Ei 'app_protect|viol|support id|attack'
```
