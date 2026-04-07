#!/usr/bin/env bash
set -euo pipefail

# Spusti ADSB forwarder (Socket-Forwarder) v Docker kontejneru.
# Pouziti:
#   ./docker-adsbfwd.sh [ADSBFWD_SRC] [ADSBFWD_DST] [CONTAINER_NAME]
#
# Priklad:
#   ./docker-adsbfwd.sh 127.0.0.1:30005 czadsb.cz:50000 adsbfwd-czadsb

ADSBFWD_SRC="${1:-127.0.0.1:30005}"
ADSBFWD_DST="${2:-czadsb.cz:50000}"
CONTAINER_NAME="${3:-adsbfwd-czadsb}"
IMAGE_NAME="${CONTAINER_NAME}:latest"
WORKDIR="$(mktemp -d)"

cleanup() {
  rm -rf "${WORKDIR}"
}
trap cleanup EXIT

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker neni dostupny. Nainstalujte Docker a zkuste to znovu."
  exit 1
fi

cat > "${WORKDIR}/Dockerfile" <<'EOF'
FROM python:3.12-alpine
WORKDIR /opt/adsbfwd
RUN apk add --no-cache curl \
    && curl -fsSL https://raw.githubusercontent.com/clazzor/Socket-Forwarder/main/socketForwarder.py -o /opt/adsbfwd/adsbfwd.py \
    && chmod +x /opt/adsbfwd/adsbfwd.py \
    && apk del curl
ENTRYPOINT ["python3", "/opt/adsbfwd/adsbfwd.py"]
EOF

echo "* Building Docker image: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" "${WORKDIR}"

if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
  echo "* Removing existing container: ${CONTAINER_NAME}"
  docker rm -f "${CONTAINER_NAME}" >/dev/null
fi

echo "* Starting container ${CONTAINER_NAME}"
echo "  Source: ${ADSBFWD_SRC}"
echo "  Target: ${ADSBFWD_DST}"
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  --network host \
  "${IMAGE_NAME}" \
  "${ADSBFWD_SRC}" "${ADSBFWD_DST}" >/dev/null

echo
echo "Container is running. Useful commands:"
echo "  docker logs -f ${CONTAINER_NAME}"
echo "  docker ps --filter name=${CONTAINER_NAME}"
