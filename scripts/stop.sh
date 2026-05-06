#!/bin/bash
# ============================================
# OpenVoo - Detener toda la infraestructura
# Uso: ./scripts/stop.sh
# ============================================
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "=========================================="
echo " OpenVoo Production - Deteniendo"
echo "=========================================="

# Primero detener instancias Odoo
for dir in instances/*/; do
    name=$(basename "$dir")
    if [ "$name" = "_template" ]; then continue; fi

    echo "Deteniendo instancia: $name..."
    docker compose -f "$dir/docker-compose.yml" --env-file .env down 2>/dev/null || true
done

# Luego detener core
echo "Deteniendo Traefik + PostgreSQL..."
docker compose -f core/docker-compose.yml --env-file .env down

echo ""
echo "Todo detenido. Los datos persisten en los volumes de Docker."
