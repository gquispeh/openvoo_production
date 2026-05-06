# OpenVoo Production

Arquitectura multi-tenant de Odoo 19 con Docker Compose, Traefik y PostgreSQL compartido.

## Arquitectura

```
                    ┌─────────────────────────────────┐
                    │          INTERNET                │
                    └──────────┬──────────────────────┘
                               │ :80 / :443
                    ┌──────────▼──────────────────────┐
                    │        TRAEFIK                   │
                    │   (reverse proxy + SSL auto)     │
                    └──┬──────────────┬───────────────┘
                       │              │
          ┌────────────▼───┐   ┌──────▼────────────┐
          │   openvoo      │   │     demo           │   ... mas instancias
          │   Odoo 19      │   │     Odoo 19        │
          │ openvoo.com    │   │ demo.openvoo.com   │
          └───────┬────────┘   └──────┬─────────────┘
                  │                   │
          ┌───────▼───────────────────▼─────────────┐
          │            PostgreSQL 16                  │
          │         (base de datos compartida)        │
          │  DB: openvoo | DB: demo | DB: clienteX   │
          └──────────────────────────────────────────┘
```

## Estructura de carpetas

```
openvoo_production/
├── .env                        # Variables globales (passwords, dominio)
├── .gitignore
├── core/
│   └── docker-compose.yml      # Traefik + PostgreSQL
├── traefik/
│   └── traefik.yml             # Config de Traefik
├── enterprise/                 # Modulos enterprise de Odoo (compartidos)
├── instances/
│   ├── openvoo/                # Produccion: openvoo.com
│   │   ├── docker-compose.yml
│   │   ├── odoo.conf
│   │   └── addons/             # Addons custom de openvoo
│   ├── demo/                   # Demo: demo.openvoo.com
│   │   ├── docker-compose.yml
│   │   ├── odoo.conf
│   │   └── addons/             # Addons custom de demo
│   └── _template/              # Plantilla para nuevos clientes
│       ├── docker-compose.yml
│       ├── odoo.conf
│       └── addons/
└── scripts/
    ├── start.sh                # Levantar todo
    ├── stop.sh                 # Detener todo
    ├── status.sh               # Ver estado
    ├── new-client.sh           # Crear nueva instancia
    └── backup-db.sh            # Respaldar base de datos
```

## Requisitos del servidor

- Ubuntu 24.04
- Docker Engine 24+
- Docker Compose v2+
- Puertos 80 y 443 abiertos
- Dominio `openvoo.com` apuntando al servidor

## Instalacion paso a paso

### 1. Instalar Docker en Ubuntu 24.04

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com | sh

# Agregar tu usuario al grupo docker
sudo usermod -aG docker $USER

# Cerrar sesion y volver a entrar para que aplique
exit
```

### 2. Clonar el repositorio

```bash
cd /opt
git clone <URL_DE_TU_REPO> openvoo_production
cd openvoo_production
```

### 3. Configurar variables

```bash
# Copiar y editar el archivo de variables
cp .env.example .env   # o editar .env directamente
nano .env
```

Cambiar estos valores en `.env`:
- `POSTGRES_PASSWORD` -> una password segura
- `ODOO_MASTER_PASSWORD` -> otra password segura
- `ACME_EMAIL` -> tu email real (para Let's Encrypt)

Luego actualizar las mismas passwords en:
- `instances/openvoo/odoo.conf`
- `instances/demo/odoo.conf`

### 4. Agregar modulos Enterprise

```bash
# Clonar el repo enterprise de Odoo en la carpeta compartida
git clone https://github.com/odoo/enterprise.git --branch 19.0 --depth 1 enterprise/
```

### 5. Configurar DNS

En tu panel de Hetzner o proveedor DNS, crear estos registros:

| Tipo | Nombre | Valor |
|------|--------|-------|
| A | openvoo.com | IP_DEL_SERVIDOR |
| A | demo.openvoo.com | IP_DEL_SERVIDOR |
| A | *.openvoo.com | IP_DEL_SERVIDOR |

El registro wildcard (`*`) permite agregar nuevos clientes sin tocar el DNS.

### 6. Dar permisos a los scripts

```bash
chmod +x scripts/*.sh
```

### 7. Levantar todo

```bash
./scripts/start.sh
```

## Comandos de operacion

### Levantar todo
```bash
./scripts/start.sh
```

### Detener todo
```bash
./scripts/stop.sh
```

### Ver estado
```bash
./scripts/status.sh
```

### Agregar un nuevo cliente

```bash
# Ejemplo: crear cliente "acme" -> acme.openvoo.com
./scripts/new-client.sh acme

# Levantar la nueva instancia
docker compose -f instances/acme/docker-compose.yml --env-file .env up -d
```

### Respaldar una base de datos

```bash
./scripts/backup-db.sh openvoo
# Genera: backup_openvoo_20260506_120000.sql.gz
```

### Ver logs de una instancia

```bash
docker logs -f openvoo     # logs de produccion
docker logs -f demo        # logs de demo
docker logs -f postgres    # logs de la BD
docker logs -f traefik     # logs del proxy
```

### Reiniciar una instancia

```bash
docker restart openvoo
```

### Levantar solo una instancia

```bash
docker compose -f instances/openvoo/docker-compose.yml --env-file .env up -d
```

## Orden de arranque

Es importante respetar este orden:

1. **Traefik + PostgreSQL** (core) -> siempre primero
2. **Instancias Odoo** -> despues de que PostgreSQL este listo

El script `start.sh` ya maneja esto automaticamente.

## Orden de apagado

Inverso al arranque:

1. **Instancias Odoo** -> primero
2. **Traefik + PostgreSQL** -> ultimo

El script `stop.sh` ya maneja esto automaticamente.

## Como funciona la red

Todos los contenedores estan en la misma red Docker: `openvoo_network`.

- **Traefik** escucha los puertos 80/443 del servidor y rutea por dominio
- **PostgreSQL** es accesible internamente por hostname `postgres`
- **Cada Odoo** tiene su propia base de datos dentro del mismo PostgreSQL
- **Let's Encrypt** genera certificados SSL automaticamente via HTTP challenge

## Notas importantes

- Los **datos persisten** en Docker volumes aunque detengas los contenedores
- Los **certificados SSL** se generan solos la primera vez (puede tardar 1-2 min)
- Cada instancia tiene su carpeta `addons/` para modulos custom
- La carpeta `enterprise/` es compartida (solo lectura) por todas las instancias
- Para **desarrollo local**, comenta las lineas de `tls.certresolver` en los compose
