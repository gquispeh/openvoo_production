#!/bin/bash
# ============================================
# OpenVoo - Estado de todos los contenedores
# Uso: ./scripts/status.sh
# ============================================

echo "=========================================="
echo " OpenVoo Production - Estado"
echo "=========================================="
echo ""
docker ps -a --filter "network=openvoo_network" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
