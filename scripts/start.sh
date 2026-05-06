#!/bin/bash
# ============================================
# OpenVoo - Levantar toda la infraestructura
# Uso: ./scripts/start.sh
# ============================================
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "=========================================="
echo " OpenVoo Production - Iniciando"
echo "=========================================="

# --- Paso 1: Core (Traefik + PostgreSQL) ---
echo ""
echo "[1/3] Levantando Traefik + PostgreSQL..."
docker compose -f core/docker-compose.yml --env-file .env up -d

# Esperar a que PostgreSQL este listo
echo "      Esperando a PostgreSQL..."
until docker exec postgres pg_isready -U odoo > /dev/null 2>&1; do
    sleep 2
done
echo "      PostgreSQL listo."

# --- Paso 2: Instancias Odoo ---
echo ""
echo "[2/3] Levantando instancia: openvoo..."
docker compose -f instances/openvoo/docker-compose.yml --env-file .env up -d

echo ""
echo "[3/3] Levantando instancia: demo..."
docker compose -f instances/demo/docker-compose.yml --env-file .env up -d

# --- Resumen ---
echo ""
echo "=========================================="
echo " Todo levantado correctamente"
echo "=========================================="
echo ""
echo " openvoo.com        -> Produccion"
echo " demo.openvoo.com   -> Demo"
echo ""
echo " PostgreSQL          -> container: postgres"
echo " Traefik             -> container: traefik"
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
