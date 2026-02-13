# Terraform Module Composition Guide

Esta guía explica cómo usar la estructura modular del proyecto para desarrollar funcionalidades independientes en ramas separadas.

## Estructura de Módulos

El proyecto está dividido en 2 módulos independientes:

### 1. `modules/eks/` - EKS Cluster Base

**Responsabilidad**: Crear cluster EKS + VPC + subnets + node groups

**Archivos**:

- `main.tf`: Módulos terraform-aws-modules (VPC, EKS)
- `variables.tf`: Variables de entrada (aws_region, cluster_name, kubernetes_version, etc.)
- `outputs.tf`: Outputs (cluster_endpoint, security_group_id, etc.)

**Estado**: Siempre activado (no tiene flag `enable_*`)

### 2. `modules/nginx/` - NGINX Plus Ingress Controller

**Responsabilidad**: Desplegar NGINX Plus en el cluster usando Helm (chart OCI) y habilitar NGINX One Agent

**Archivos**:

- `main.tf`: Helm release + namespace + autenticación con cluster
- `variables.tf`: Variables (enabled, chart_version, helm_values, data_plane_key, etc.)
- `outputs.tf`: Outputs (release_name, release_status, etc.)

**Activación**: `enable_nginx = true` en terraform.tfvars o workflow

**Secretos requeridos**:

- `LICENSE_JWT`
- `DATA_PLANE_KEY`

**Dependencias**: Requiere outputs de `modules/eks` (cluster endpoint, token, cert)

---

## Root Module (Orquestación)

El root (`main.tf`, `variables.tf`, `outputs.tf`) importa los 2 módulos:

```hcl
module "eks" {
  source = "./modules/eks"
  # ... pass variables
}

module "nginx" {
  source = "./modules/nginx"
  enabled = var.enable_nginx
  # ... depends_on modules/eks
}
```

---

## Estrategia de Ramas (Git)

### Rama `main`

- Contiene código stable de todos los módulos
- Workflows GitHub Actions (`eks-tfc.yml`, `eks-tfc-destroy.yml`) trabajan sobre `main`
- Puede desplegar cualquier combinación de módulos via variables

### Rama `feature/nginx-plus` (Ejemplo)

```bash
git checkout -b feature/nginx-plus
# Edita modules/nginx/
# Prueba localmente: terraform plan -var=enable_nginx=true
# Haz commits
# Abre PR a main
# Una vez aprobado, merge a main
```

---

## Flujo de Desarrollo

### Escenario 1: Desarrollar módulo NGINX Plus

```bash
# 1. Crear rama desde main
git checkout main
git pull origin main
git checkout -b feature/nginx-plus

# 2. Editar módulo
cd modules/nginx/
# ... edita main.tf, variables.tf, outputs.tf

# 3. Probar localmente (copiar terraform.tfvars.example → terraform.tfvars)
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars: enable_nginx=true
terraform plan -var=enable_nginx=true

# 4. Si todo valida, hacer commit
git add modules/nginx/
git commit -m "feat(nginx): Add NGINX Plus deployment"
git push origin feature/nginx-plus

# 5. Abrir PR en GitHub
# - GitHub Actions ejecutará validaciones
# - Revisor aprueba
# - Merge a main

# 6. Después del merge, main puede desplegar NGINX con:
# terraform apply -var=enable_nginx=true
```

---

## Configuración de Variables

### Opción 1: Usar `terraform.tfvars` localmente

```bash
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con valores reales
terraform plan
```

### Opción 2: Usar `-var` flags

```bash
terraform plan -var=enable_nginx=true -var=enable_people=true
```

### Opcion 3: En GitHub Actions (workflows)

Los workflows `eks-tfc.yml` e `eks-tfc-destroy.yml` pueden pasar variables:

```yaml
- name: Terraform apply
  run: |
    terraform apply -auto-approve \
      -var="aws_region=${AWS_REGION}" \
      -var="cluster_name=${CLUSTER_NAME}" \
      -var="enable_nginx=true"  # Agregar si necesitas
      -var="data_plane_key=${DATA_PLANE_KEY}"
```

---

## Ejemplo de PRs y Merges

### PR 1: Merge feature/nginx-plus → main

```
Commit History:
├─ main branch
│  └─ ef9c5a2: Merge PR #1 (feature/nginx-plus)
│     ├─ a1b2c3d: feat(nginx): Add NGINX Plus chart version 1.0.0
│     └─ d4e5f6g: docs(nginx): Update README with NGINX variables
```

Después del merge, `main` puede:

```bash
# Solo EKS
terraform apply -var=enable_nginx=false

# EKS + NGINX
terraform apply -var=enable_nginx=true
```

---

## Troubleshooting

### Error: "module not found"

```
Error: Module not found
  on main.tf line 15, in module "nginx":
    source = "./modules/nginx"
```

**Solución**: Asegúrate de que `modules/nginx/` existe con sus archivos tf.

### Error: "Outputs not available"

```
Error: Missing required argument
  on main.tf line 25, in module "nginx":
    cluster_endpoint = module.eks.cluster_endpoint
```

**Solución**: Asegúrate de que `module.eks` está desplegado y outputs están disponibles.

---

## Mejores Prácticas

1. **Cada rama, un módulo**: No mezcles cambios en múltiples módulos en una rama.
2. **Test antes de PR**: Ejecuta `terraform plan` localmente antes de pushear.
3. **Versionado claro**: Comenta cambios importantes en variables/outputs.
4. **Documentación**: Actualiza README de cada módulo si cambias interfaz.
5. **Dependencias explícitas**: En `main.tf`, declara `depends_on = [module.eks]`.
6. **Variables con defaults**: En módulos, proporciona defaults razonables para `enabled`, etc.

---

## Próximos Pasos

1. Crear rama `feature/nginx-plus` y completar modules/nginx/ con Helm chart real
2. Testear en rama antes de merge a main
3. Mergear a main cuando esté stable
4. Ejecutar workflows GitHub Actions para desplegar
