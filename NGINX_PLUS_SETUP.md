# Configuración de NGINX Plus con NGINX One Agent

Esta guía describe cómo configurar NGINX Plus Ingress Controller con NGINX One Agent para monitoreo en tu cluster EKS.

## Requisitos Previos

1. **Suscripcion a NGINX Plus**: JWT de licencia
2. **NGINX One Agent**: Data plane key
3. **Cluster EKS ya creado**: Usar el workflow `eks-tfc` primero si aun no existe

## Paso 1: Obtener Credenciales NGINX Plus

### 1.1 License JWT y Data Plane Key

Desde MyF5 descarga el archivo `license.jwt` y copia el `DATA_PLANE_KEY` desde NGINX One.

## Paso 2: Configurar Secretos en GitHub

1. Ve a tu repositorio en GitHub
2. Settings → Secrets and variables → Actions
3. Haz clic en "New repository secret"

**IMPORTANTE**: NGINX One Agent requiere **ambos secretos** (`LICENSE_JWT` y `DATA_PLANE_KEY`).

### Crear Secret: LICENSE_JWT

- **Name**: `LICENSE_JWT`
- **Secret**: Copia el token JWT completo de tu licencia NGINX One Agent

Ejemplo:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Haz clic en "Add secret"

### Crear Secret: DATA_PLANE_KEY

- **Name**: `DATA_PLANE_KEY`
- **Secret**: Copia el API key del data plane de NGINX One Agent

Ejemplo:

```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

Haz clic en "Add secret"

## Paso 3: Habilitar NGINX Plus en el Workflow

### Opcion A: Usar inputs del workflow (Recomendado)

En GitHub Actions:

- `enable_nginx=true`
- `terraform_target=module.nginx`

### Opción B: Usar terraform.tfvars Local (Para Desarrollo)

Si trabajas localmente:

```bash
# Crear archivo de variables
cat > terraform.tfvars << 'EOF'
aws_region    = "us-east-1"
cluster_name  = "eks-21959515353"
enable_nginx  = true

# Cargar desde archivos locales
license_jwt    = file("/ruta/a/license.jwt")
data_plane_key = file("/ruta/a/dataplane.key")
EOF
```

Luego ejecuta:

```bash
terraform plan -var="enable_nginx=true"
terraform apply -auto-approve -var="enable_nginx=true"
```

## Paso 4: Ejecutar el Workflow

1. Ve a GitHub → Actions
2. Selecciona el workflow `eks-tfc`
3. Haz clic en "Run workflow"
4. Haz clic en "Run workflow" nuevamente

El workflow:

- Verifica que los secretos estan disponibles
- Aplica CRDs del chart OCI
- Crea secrets `nplus-license`, `regcred` y `nginx-agent`
- Despliega NGINX Plus + NGINX One Agent

## Paso 5: Verificar la Instalación

```bash
# Obtener credenciales del cluster
aws eks update-kubeconfig --region us-east-1 --name eks-21959515353

# Verificar que el namespace nginx existe
kubectl get namespace nginx

# Verificar Kubernetes secrets creados
kubectl get secrets -n nginx
# Deberías ver:
# - regcred (credenciales del registry)
# - nplus-license (licencia NGINX Plus)
# - nginx-agent (dataplane key)

# Ver los pods de NGINX Plus
kubectl get pods -n nginx -w

# Verificar logs (agente integrado)
kubectl logs -n nginx -l app.kubernetes.io/name=nginx-ingress -f | grep -i agent

# Obtener endpoint del Load Balancer
kubectl get svc -n nginx
# Deberías ver un ingress controller service con IP externa
```

## Estructura de Secretos Creados

El workflow crea automáticamente:

### Kubernetes Secret: regcred

Contiene credenciales Docker para el registry privado:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: regcred
  namespace: nginx
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-registry-auth>
```

### Kubernetes Secret: nplus-license

Contiene el JWT de licencia NGINX Plus:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: nplus-license
  namespace: nginx
type: nginx.com/license
data:
  license.jwt: <base64-encoded-jwt>
```

### Kubernetes Secret: nginx-agent

Contiene el dataplane key para NGINX One:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: nginx-agent
  namespace: nginx
type: Opaque
data:
  dataplane.key: <base64-encoded-key>
```

````

## Solución de Problemas

### Error: "Unauthorized: incorrect username, password, or token"

**Causa**: Las credenciales del repositorio son inválidas o expiradas.

**Solución**:
1. Verifica que `LICENSE_JWT` sea correcto
2. Confirma que la suscripcion de NGINX Plus sigue activa
3. Actualiza los secretos en GitHub con nuevas credenciales

### Error: "ImagePullBackOff" en el pod de NGINX Plus

**Causa**: El pod no puede descargar la imagen desde el repositorio privado.

**Solución**:
```bash
# Verificar estado del pod
kubectl describe pod <pod-name> -n nginx

# Verificar que el secret regcred existe
kubectl get secret regcred -n nginx -o yaml

# Reiniciar el pod
kubectl rollout restart ds/nginx-plus-nginx-ingress-controller -n nginx
````

### NGINX One Agent no se conecta

**Causa**: `DATA_PLANE_KEY` incorrecta o secret desactualizado.

**Solucion**:

1. Verifica `DATA_PLANE_KEY`
2. Borra el secret y re-ejecuta el workflow:

```bash
kubectl delete secret nginx-agent -n nginx
```

### Pods en estado "Pending"

**Causa**: No hay suficientes recursos en el cluster.

**Solución**:

```bash
# Verificar nodos disponibles
kubectl get nodes

# Aumentar desired_size en el workflow o terraform.tfvars
desired_size = 3  # En lugar de 2
```

## Deshabilitar NGINX Plus

Para remover NGINX Plus:

1. Cambiar `enable_nginx=false` en el workflow
2. Ejecutar el workflow nuevamente
3. Terraform destruirá los recursos de NGINX automáticamente

```bash
# O localmente:
terraform apply -auto-approve -var="enable_nginx=false"
```

## Próximos Pasos

- [x] NGINX Plus Ingress Controller desplegado
- [x] NGINX One Agent configurado para monitoreo
- [ ] Configurar ingress rules para aplicaciones
- [ ] Certificados SSL/TLS para aplicaciones
- [ ] Integrar con monitoreo centralizado

## Referencias

- [NGINX Plus Documentation](https://docs.nginx.com/)
- [NGINX Ingress Controller Helm Chart](https://github.com/nginx/helm-charts)
- [NGINX One Agent](https://www.nginx.com/products/nginx-one/)

## Soporte

Para problemas específicos de NGINX Plus, consulta:

- [NGINX Support Portal](https://support.nginx.com/)
- Logs del workflow en GitHub Actions
