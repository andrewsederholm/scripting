#!/bin/bash

# ============================================================
# Portainer Version Lock
# Checks /srv/docker for a Portainer Docker Compose deployment
# and pins Portainer CE to version 2.45.1
# ============================================================

set -euo pipefail

PORTAINER_VERSION="2.45.1"
DOCKER_ROOT="/srv/docker"

echo
echo "============================================================"
echo " Portainer Version Lock"
echo " Target version: ${PORTAINER_VERSION}"
echo "============================================================"
echo

# ------------------------------------------------------------
# Must be root
# ------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script must be run as root."
    exit 1
fi

# ------------------------------------------------------------
# Check Docker
# ------------------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
    echo "[ERROR] Docker is not installed."
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo "[ERROR] Docker Compose is not available."
    exit 1
fi

# ------------------------------------------------------------
# Check Docker directory
# ------------------------------------------------------------

if [ ! -d "$DOCKER_ROOT" ]; then
    echo "[INFO] $DOCKER_ROOT does not exist."
    echo "[INFO] Portainer does not appear to be installed here."
    exit 0
fi

echo "[INFO] Searching for Portainer under $DOCKER_ROOT..."

# ------------------------------------------------------------
# Find Portainer compose file
# ------------------------------------------------------------

COMPOSE_FILE=""

while IFS= read -r file; do
    if grep -qiE 'portainer/portainer-(ce|ee)' "$file"; then
        COMPOSE_FILE="$file"
        break
    fi
done < <(
    find "$DOCKER_ROOT" -maxdepth 3 -type f \
        \( -name "docker-compose.yml" \
        -o -name "docker-compose.yaml" \
        -o -name "compose.yml" \
        -o -name "compose.yaml" \) \
        2>/dev/null
)

# ------------------------------------------------------------
# Portainer not found
# ------------------------------------------------------------

if [ -z "$COMPOSE_FILE" ]; then
    echo
    echo "[INFO] No Portainer Docker Compose deployment was found."
    echo "[INFO] Nothing needs to be changed."
    exit 0
fi

COMPOSE_DIR="$(dirname "$COMPOSE_FILE")"

echo
echo "[FOUND] Portainer deployment:"
echo "        $COMPOSE_FILE"
echo

# ------------------------------------------------------------
# Show existing image
# ------------------------------------------------------------

CURRENT_IMAGE="$(grep -iE '^[[:space:]]*image:[[:space:]]*.*portainer/portainer-(ce|ee)' "$COMPOSE_FILE" | head -n 1 || true)"

echo "[INFO] Current image:"
echo "       ${CURRENT_IMAGE:-Unable to determine}"
echo

# ------------------------------------------------------------
# Backup compose file
# ------------------------------------------------------------

BACKUP_FILE="${COMPOSE_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
cp -a "$COMPOSE_FILE" "$BACKUP_FILE"

echo "[INFO] Backup created:"
echo "       $BACKUP_FILE"

# ------------------------------------------------------------
# Lock Portainer CE to requested version
# ------------------------------------------------------------

echo
echo "[INFO] Locking Portainer CE to ${PORTAINER_VERSION}..."

sed -i -E \
    "s|(image:[[:space:]]*portainer/portainer-ce:)[^[:space:]\"']+|\1${PORTAINER_VERSION}|g" \
    "$COMPOSE_FILE"

# ------------------------------------------------------------
# Verify change
# ------------------------------------------------------------

if ! grep -qE "portainer/portainer-ce:${PORTAINER_VERSION}([[:space:]\"']|$)" "$COMPOSE_FILE"; then
    echo
    echo "[ERROR] Could not verify the Portainer version change."
    echo "[INFO] Restoring original compose file..."

    cp -a "$BACKUP_FILE" "$COMPOSE_FILE"

    echo "[INFO] Original file restored."
    exit 1
fi

echo "[OK] Compose file updated successfully."

# ------------------------------------------------------------
# Validate Compose
# ------------------------------------------------------------

cd "$COMPOSE_DIR"

echo
echo "[INFO] Validating Docker Compose configuration..."

if ! docker compose config >/dev/null; then
    echo "[ERROR] Docker Compose validation failed."
    echo "[INFO] Restoring original compose file..."

    cp -a "$BACKUP_FILE" "$COMPOSE_FILE"

    echo "[INFO] Original file restored."
    exit 1
fi

echo "[OK] Docker Compose configuration is valid."

# ------------------------------------------------------------
# Pull exact Portainer version
# ------------------------------------------------------------

echo
echo "[INFO] Pulling Portainer ${PORTAINER_VERSION}..."

docker compose pull

# ------------------------------------------------------------
# Recreate containers
# ------------------------------------------------------------

echo
echo "[INFO] Recreating deployment..."

docker compose up -d

# ------------------------------------------------------------
# Verify Portainer container
# ------------------------------------------------------------

echo
echo "[INFO] Verifying Portainer container..."

sleep 3

PORTAINER_CONTAINER="$(
    docker ps \
        --filter "ancestor=portainer/portainer-ce:${PORTAINER_VERSION}" \
        --format '{{.Names}}' \
        | head -n 1
)"

if [ -z "$PORTAINER_CONTAINER" ]; then
    echo
    echo "[WARNING] Compose completed, but a running Portainer"
    echo "          container using ${PORTAINER_VERSION} was not detected."
    echo
    docker compose ps
    exit 1
fi

# ------------------------------------------------------------
# Complete
# ------------------------------------------------------------

echo
echo "============================================================"
echo " SUCCESS"
echo "============================================================"
echo
echo " Portainer has been locked to:"
echo
echo "     portainer/portainer-ce:${PORTAINER_VERSION}"
echo
echo " Compose file:"
echo "     $COMPOSE_FILE"
echo
echo " Backup:"
echo "     $BACKUP_FILE"
echo
echo " Running container:"
echo "     $PORTAINER_CONTAINER"
echo
echo " Portainer update completed successfully."
echo "============================================================"
echo
