# Configuración de NGINX Plus con NGINX One Agent

Esta guía describe cómo configurar NGINX Plus Ingress Controller con NGINX One Agent para monitoreo en tu cluster EKS.

## Requisitos Previos

1. **Suscripción a NGINX Plus**: Acceso a repositorio privado de NGINX
2. **Licencia NGINX One Agent**: Token JWT para telemetría
3. **Cluster EKS ya creado**: Usar el workflow `eks-tfc` primero con `enable_nginx=false`

## Paso 1: Obtener Credenciales NGINX Plus

### 1.1 Certificado y Clave del Repositorio

Desde tu descarga de NGINX Plus en el portal:

```bash
# Busca estos archivos en tu descarga
nginx-repo.crt    # Certificado de cliente
nginx-repo.key    # Clave privada de cliente
license.jwt       # Licencia (si está incluida)
```

Si no tienes estos archivos, contacta a tu proveedor de NGINX Plus.

### 1.2 Verificar Formato

Los archivos deben verse algo así:

**nginx-repo.crt**:
```
-----BEGIN CERTIFICATE-----
MIIF...
...
-----END CERTIFICATE-----
```

**nginx-repo.key**:
```
-----BEGIN RSA PRIVATE KEY-----
MIIJJwIBA...
...
-----END RSA PRIVATE KEY-----
```

**license.jwt** (token JWT):
```
eyJhbGciOiJ...
```

## Paso 2: Configurar Secretos en GitHub

1. Ve a tu repositorio en GitHub
2. Settings → Secrets and variables → Actions
3. Haz clic en "New repository secret"

### Crear Secret: NGINX_REPO_CRT

- **Name**: `NGINX_REPO_CRT`
- **Secret**: Copia el contenido completo del archivo `nginx-repo.crt` (incluyendo las líneas BEGIN/END)

Ejemplo:
```
-----BEGIN CERTIFICATE-----
MIIF...
-----END CERTIFICATE-----
```

Haz clic en "Add secret"

### Crear Secret: NGINX_REPO_KEY

- **Name**: `NGINX_REPO_KEY`
- **Secret**: Copia el contenido completo del archivo `nginx-repo.key` (incluyendo las líneas BEGIN/END)

Ejemplo:
```
-----BEGIN RSA PRIVATE KEY-----
MIIJJwIBA...
-----END RSA PRIVATE KEY-----
```

Haz clic en "Add secret"

### Crear Secret: LICENSE_JWT

- **Name**: `LICENSE_JWT`
- **Secret**: Copia el token JWT completo de tu licencia NGINX One Agent

Ejemplo:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Haz clic en "Add secret"

## Paso 3: Habilitar NGINX Plus en el Workflow

### Opción A: Modificar el Workflow (Recomendado para Producción)

Edita `.github/workflows/eks-tfc.yml`:

**En el job `plan`** (línea ~124):
```yaml
# Cambiar de:
-var="enable_nginx=false"

# A:
-var="enable_nginx=true"
```

**En el job `apply`** (línea ~179):
```yaml
# Cambiar de:
-var="enable_nginx=false"

# A:
-var="enable_nginx=true"
```

Luego:
```bash
git add .github/workflows/eks-tfc.yml
git commit -m "feat: Enable NGINX Plus deployment"
git push
```

### Opción B: Usar terraform.tfvars Local (Para Desarrollo)

Si trabajas localmente:

```bash
# Crear archivo de variables
cat > terraform.tfvars << 'EOF'
aws_region    = "us-east-1"
cluster_name  = "eks-21959515353"
enable_nginx  = true

# Cargar desde archivos locales
nginx_repo_crt = file("/ruta/a/nginx-repo.crt")
nginx_repo_key = file("/ruta/a/nginx-repo.key")
license_jwt    = file("/ruta/a/license.jwt")
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
- Verificará que los secretos están disponibles
- Creará Kubernetes secrets internos para las credenciales
- Desplegará NGINX Plus Ingress Controller
- Habilitará NGINX One Agent para monitoreo

## Paso 5: Verificar la Instalación

```bash
# Obtener credenciales del cluster
aws eks update-kubeconfig --region us-east-1 --name eks-21959515353

# Verificar que el namespace nginx existe
kubectl get namespace nginx

# Verificar Kubernetes secrets creados
kubectl get secrets -n nginx
# Deberías ver:
# - nginx-repo (credenciales del repositorio)
# - nginx-license (licencia NGINX One Agent)

# Ver los pods de NGINX Plus
kubectl get pods -n nginx -w

# Verificar logs
kubectl logs -n nginx -l app.kubernetes.io/name=nginx-ingress -f

# Obtener endpoint del Load Balancer
kubectl get svc -n nginx
# Deberías ver un ingress controller service con IP externa
```

## Estructura de Secretos Creados

El workflow crea automáticamente:

### Kubernetes Secret: nginx-repo
Contiene credenciales Docker para el repositorio privado:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: nginx-repo
  namespace: nginx
type: kubernetes.io/dockercfg
data:
  .dockercfg: <base64-encoded-registry-auth>
```

### Kubernetes Secret: nginx-license
Contiene el JWT de licencia NGINX One Agent:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: nginx-license
  namespace: nginx
type: Opaque
data:
  license.jwt: <base64-encoded-jwt>
```

## Solución de Problemas

### Error: "Unauthorized: incorrect username, password, or token"

**Causa**: Las credenciales del repositorio son inválidas o expiradas.

**Solución**:
1. Verifica que `NGINX_REPO_CRT` y `NGINX_REPO_KEY` sean exactos
2. Confirma que la suscripción de NGINX Plus sigue activa
3. Actualiza los secretos en GitHub con nuevas credenciales

### Error: "ImagePullBackOff" en el pod de NGINX Plus

**Causa**: El pod no puede descargar la imagen desde el repositorio privado.

**Solución**:
```bash
# Verificar estado del pod
kubectl describe pod <pod-name> -n nginx

# Verificar que el secret nginx-repo existe
kubectl get secret nginx-repo -n nginx -o yaml

# Reiniciar el pod
kubectl rollout restart deployment/nginx-plus -n nginx
```

### NGINX One Agent no se conecta

**Causa**: Token JWT no válido o expirado.

**Solución**:
1. Verifica que `LICENSE_JWT` sea el token correcto
2. Confirma que el token no ha expirado
3. Actualiza el secret `nginx-license`:
   ```bash
   kubectl delete secret nginx-license -n nginx
   # Vuelve a ejecutar el workflow o:
   kubectl create secret generic nginx-license \
     --from-literal=license.jwt=$(cat license.jwt) \
     -n nginx
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
