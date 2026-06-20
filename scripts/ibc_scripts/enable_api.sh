#!/usr/bin/env bash
set -euo pipefail

port="${IBC_COMMAND_SERVER_PORT:-7462}"
host="127.0.0.1"

for _ in $(seq 1 60); do
  if timeout 1 bash -c "</dev/tcp/${host}/${port}" 2>/dev/null; then
    break
  fi
  sleep 1
done

if ! timeout 1 bash -c "</dev/tcp/${host}/${port}" 2>/dev/null; then
  echo ".> IBC command server is not reachable on ${host}:${port}; cannot enable API"
  exit 0
fi

{
  printf 'ENABLEAPI\n'
  sleep 1
  printf 'EXIT\n'
  printf 'quit\n'
} >/dev/tcp/"${host}"/"${port}"

echo ".> Sent ENABLEAPI to IBC command server"
