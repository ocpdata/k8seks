# EKS Terraform Cloud Automation

Este proyecto automatiza la creación y destrucción de clusters EKS en AWS usando Terraform Cloud como backend remoto, orquestado mediante GitHub Actions.

## Descripción

El proyecto proporciona dos workflows principales:
- **eks-tfc.yml**: Crea un cluster EKS con VPC, subnets, NAT Gateway y nodos gestionados.
- **eks-tfc-destroy.yml**: Destruye la infraestructura EKS y elimina el workspace en Terraform Cloud.

## Requisitos Previos

### Secretos en GitHub
Configura los siguientes secretos en tu repositorio:

- `TFC_TOKEN`: API token de Terraform Cloud (con permisos para crear/gestionar workspaces)
- `TFC_ORG`: Nombre de la organización en Terraform Cloud
- `AWS_REGION`: Región AWS por defecto (ej: `us-east-1`)
- `AWS_ACCESS_KEY_ID`: Credenciales AWS
- `AWS_SECRET_ACCESS_KEY`: Credenciales AWS

### Dependencias
- Terraform >= 1.5.0
- AWS Provider >= 5.0
- Cuenta en Terraform Cloud

## Estructura del Proyecto

```
.
├── README.md                 # Este archivo
├── MODULES.md                # Guía de módulos y ramas
├── main.tf                   # Orquestación de módulos
├── variables.tf              # Variables raíz
├── versions.tf               # Configuración de versiones y backend
├── outputs.tf                # Outputs combinados
├── .tfworkspace              # Workspace suffix (generado)
├── modules/
│   ├── eks/
│   │   ├── main.tf          # VPC + EKS cluster
│   │   ├── variables.tf     # Variables EKS
│   │   └── outputs.tf       # Outputs EKS
│   └── nginx/
│       ├── main.tf          # NGINX Plus Helm deployment
│       ├── variables.tf     # Variables NGINX
│       └── outputs.tf       # Outputs NGINX
└── .github/workflows/
    ├── eks-tfc.yml          # Workflow de creación
    └── eks-tfc-destroy.yml  # Workflow de destrucción
```

## Infraestructura Creada

### VPC
- CIDR: `10.0.0.0/16` (configurable)
- 3 subnets privadas y 3 públicas en diferentes AZs
- NAT Gateway único para salida desde subnets privadas

### EKS
- Cluster Kubernetes gestionado
- Node group con instancias `t3.medium` (1-3 nodos, 2 deseados)
- IRSA habilitado para pods con credenciales IAM

## Uso

### Arquitectura Modular

El proyecto está organizado en módulos independientes que pueden activarse/desactivarse:

- **`modules/eks`**: Cluster EKS base (siempre se despliega)
- **`modules/nginx`**: NGINX Plus ingress controller (activar con `enable_nginx=true`)

Ver [MODULES.md](MODULES.md) para detalles sobre ramas y desarrollo modular.

### 1. Crear Cluster

Ejecuta el workflow `eks-tfc`:

```bash
# En GitHub Actions UI:
# Actions → eks-tfc → Run workflow → Run workflow
```

**Inputs opcionales** (dejándolos vacíos usa defaults):
- `workspace_suffix`: Sufijo para el workspace (default: `github.run_id`)
- `cluster_name`: Nombre del cluster EKS (default: `eks-<workspace_suffix>`)
- `region`: Región AWS (default: `secrets.AWS_REGION`)

**Resultado**:
- Crea workspace `eks-<suffix>` en Terraform Cloud
- Crea VPC y EKS
- Genera `.tfworkspace` con el suffix (versionado en Git)

### 2. Destruir Cluster

Ejecuta el workflow `eks-tfc-destroy`:

```bash
# En GitHub Actions UI:
# Actions → eks-tfc-destroy → Run workflow → Run workflow
```

**Proceso**:
1. Lee `.tfworkspace` para obtener el workspace creado anteriormente
2. Ejecuta `terraform destroy`
3. Elimina el workspace en Terraform Cloud

---

## Flujo de Jobs

### Workflow Apply (eks-tfc.yml)

```
prep
  ├─ Valida que AWS_REGION exista
  │
  ├─→ workspace
      ├─ Crea o reutiliza workspace en TFC
      │
      ├─→ plan
          ├─ terraform init
          ├─ terraform plan
          │
          ├─→ apply
              ├─ terraform init
              ├─ terraform apply -auto-approve
              ├─ Guarda workspace_suffix en .tfworkspace
              └─ Versionea en Git
```

### Workflow Destroy (eks-tfc-destroy.yml)

```
prep
  ├─ Valida que AWS_REGION exista
  │
  ├─→ workspace
      ├─ Lee .tfworkspace
      ├─ Valida que workspace exista en TFC
      │
      ├─→ plan-destroy
          ├─ terraform init
          ├─ terraform plan -destroy
          │
          ├─→ destroy
              ├─ terraform init
              ├─ terraform destroy -auto-approve
              └─ Elimina workspace en TFC
```

## Variables Terraform

| Variable | Default | Descripción |
|----------|---------|-------------|
| `aws_region` | (requerido) | Región AWS para la infra |
| `cluster_name` | `eks-<suffix>` | Nombre del cluster EKS |
| `vpc_cidr` | `10.0.0.0/16` | CIDR del VPC |
| `kubernetes_version` | `1.27` | Versión de Kubernetes |

Modifica `variables.tf` para cambiar defaults.

## Outputs

El cluster genera:

- `cluster_id`: ID del cluster EKS
- `cluster_endpoint`: Endpoint del servidor API
- `cluster_security_group_id`: Security group del cluster
- `vpc_id`: ID del VPC
- (Ver `outputs.tf` para más)

## Troubleshooting

### Error: "Workspace does not exist"
- **Causa**: `destroy` intenta eliminar un workspace que no existe.
- **Solución**: Ejecuta `apply` primero para crear el workspace.

### Error: "Failed to select workspace: EOF"
- **Causa**: `TF_WORKSPACE` no coincide con el prefijo configurado en `versions.tf`.
- **Solución**: El workflow ahora usa `-input=false` para evitar prompts. Si persiste, verifica `TF_WORKSPACE` en el job.

### Error: "AWS region is required"
- **Causa**: Falta `secrets.AWS_REGION` o no hay input `region`.
- **Solución**: Configura el secreto `AWS_REGION` en GitHub o pasa `region` al workflow.

### Error: "TFC_TOKEN and TFC_ORG must be set"
- **Causa**: Secretos no configurados en GitHub.
- **Solución**: Agrega `TFC_TOKEN` y `TFC_ORG` en Settings → Secrets and variables → Actions.

## Seguridad

- Los tokens y credenciales se pasan mediante secrets de GitHub (enmascarados en logs).
- Workspace en TFC con `execution-mode: local` (Terraform ejecuta en GitHub Actions).
- `auto-apply: false` en TFC (no aplica automáticamente; lo hace el workflow).

## Limitaciones y Consideraciones

- Los jobs `plan-destroy` y `destroy` son **obligatorios**; no hay aprobación manual entre pasos.
- El `.tfworkspace` se versionea en Git; múltiples apply generan conflictos si se ejecutan en paralelo.
- NAT Gateway es único; considerar múltiples para alta disponibilidad.

## Próximas Mejoras

- [ ] Guardar plan como artefacto para auditoria
- [ ] Agregar aprobación manual antes de `apply` o `destroy`
- [ ] Configurar NGINX Plus con certificados SSL
- [ ] Integrar ECR para imágenes de aplicaciones
- [ ] Ampliar a múltiples regiones
- [ ] Agregar políticas de autoescalado para node groups
- [ ] Completar módulo de NGINX con valores reales

## Desarrollo Modular (Ramas)

```
main (cluster EKS base)
└─→ feature/nginx-plus
    └─→ Desarrolla modules/nginx
        └─→ Merge a main cuando esté listo
```

**Para desarrollar una rama:**

1. Crea rama desde `main`:
   ```bash
   git checkout -b feature/nginx-plus
   ```

2. Modifica los archivos en `modules/nginx/`

3. Prueba localmente:
   ```bash
   terraform plan -var=enable_nginx=true
   ```

4. Haz PR a `main` cuando esté listo

5. En `main`, el módulo nginx se activa con `enable_nginx=true`

## Soporte

Para errores o preguntas, revisa los logs del workflow en GitHub Actions.

---

**Última actualización**: 12 de febrero de 2026
