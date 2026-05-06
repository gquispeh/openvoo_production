#!/bin/bash
# ============================================
# OpenVoo - Crear nueva instancia de cliente
# Uso: ./scripts/new-client.sh nombre_cliente
# ============================================
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [ -z "$1" ]; then
    echo "Uso: ./scripts/new-client.sh <nombre_cliente>"
    echo ""
    echo "Ejemplo: ./scripts/new-client.sh acme"
    echo "         Esto crea: acme.openvoo.com"
    exit 1
fi

CLIENT="$1"
CLIENT_DIR="$ROOT_DIR/instances/$CLIENT"

if [ -d "$CLIENT_DIR" ]; then
    echo "Error: La instancia '$CLIENT' ya existe en instances/$CLIENT"
    exit 1
fi

echo "Creando instancia: $CLIENT"
echo "Dominio: $CLIENT.openvoo.com"
echo ""

# Copiar template de instancia
cp -r "$ROOT_DIR/instances/_template" "$CLIENT_DIR"
sed -i "s/NOMBRE_CLIENTE/$CLIENT/g" "$CLIENT_DIR/docker-compose.yml"
sed -i "s/NOMBRE_CLIENTE/$CLIENT/g" "$CLIENT_DIR/odoo.conf"

# Crear ruta en Traefik
cp "$ROOT_DIR/traefik/dynamic/_template.yml" "$ROOT_DIR/traefik/dynamic/$CLIENT.yml"
sed -i "s/NOMBRE_CLIENTE/$CLIENT/g" "$ROOT_DIR/traefik/dynamic/$CLIENT.yml"

echo "Instancia creada."
echo ""
echo "Archivos generados:"
echo "  instances/$CLIENT/docker-compose.yml"
echo "  instances/$CLIENT/odoo.conf"
echo "  instances/$CLIENT/addons/"
echo "  traefik/dynamic/$CLIENT.yml"
echo ""
echo "Para levantar:"
echo "  docker compose -f instances/$CLIENT/docker-compose.yml --env-file .env up -d"
echo ""
echo "Traefik detecta la ruta automaticamente (watch: true)."
echo "Si no tienes DNS wildcard, agrega: $CLIENT.openvoo.com -> IP_DEL_SERVIDOR"
