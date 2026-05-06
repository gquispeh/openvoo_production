#!/bin/bash
# ============================================
# OpenVoo - Backup de base de datos
# Uso: ./scripts/backup-db.sh nombre_db
# Ejemplo: ./scripts/backup-db.sh openvoo
# ============================================
set -e

if [ -z "$1" ]; then
    echo "Uso: ./scripts/backup-db.sh <nombre_base_de_datos>"
    echo ""
    echo "Bases de datos disponibles:"
    docker exec postgres psql -U odoo -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';"
    exit 1
fi

DB_NAME="$1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${DB_NAME}_${TIMESTAMP}.sql.gz"

echo "Respaldando base de datos: $DB_NAME"
docker exec postgres pg_dump -U odoo "$DB_NAME" | gzip > "$BACKUP_FILE"
echo "Backup creado: $BACKUP_FILE"
