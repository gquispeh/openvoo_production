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

# Copiar template
cp -r "$ROOT_DIR/instances/_template" "$CLIENT_DIR"

# Reemplazar placeholders
sed -i "s/NOMBRE_CLIENTE/$CLIENT/g" "$CLIENT_DIR/docker-compose.yml"
sed -i "s/NOMBRE_CLIENTE/$CLIENT/g" "$CLIENT_DIR/odoo.conf"

# Leer password del .env para el odoo.conf
DB_PASS=$(grep POSTGRES_PASSWORD "$ROOT_DIR/.env" | cut -d '=' -f2)
MASTER_PASS=$(grep ODOO_MASTER_PASSWORD "$ROOT_DIR/.env" | cut -d '=' -f2)
sed -i "s/CAMBIAR_ESTA_PASSWORD_SEGURA/$DB_PASS/g" "$CLIENT_DIR/odoo.conf"
sed -i "s/CAMBIAR_MASTER_PASSWORD/$MASTER_PASS/g" "$CLIENT_DIR/odoo.conf"

echo "Instancia creada en: instances/$CLIENT/"
echo ""
echo "Archivos generados:"
echo "  instances/$CLIENT/docker-compose.yml"
echo "  instances/$CLIENT/odoo.conf"
echo "  instances/$CLIENT/addons/"
echo ""
echo "Para levantar:"
echo "  docker compose -f instances/$CLIENT/docker-compose.yml --env-file .env up -d"
echo ""
echo "IMPORTANTE: Agrega el registro DNS:"
echo "  $CLIENT.openvoo.com -> IP_DE_TU_SERVIDOR"
