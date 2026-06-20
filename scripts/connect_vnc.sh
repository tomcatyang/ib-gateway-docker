#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/connect_vnc.sh <ssh-host> [ssh-user]

Examples:
  scripts/connect_vnc.sh 10.0.0.12 dev
  scripts/connect_vnc.sh trade-server root
  LOCAL_PORT=5901 SSH_PORT=2222 scripts/connect_vnc.sh 10.0.0.12 dev

Environment:
  LOCAL_PORT   Local VNC port, default: 5900
  REMOTE_HOST  Remote VNC bind address on server, default: 127.0.0.1
  REMOTE_PORT  Remote VNC port on server, default: 5900
  SSH_PORT     SSH port, default: 22

After this script is connected, open VNC Viewer on:
  127.0.0.1:${LOCAL_PORT:-5900}

Read VNC password on the server:
  grep '^VNC_SERVER_PASSWORD=' /home/dev/high-freq-trade-sys/ib-gateway-docker/.env
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 2
fi

ssh_host="$1"
ssh_user="${2:-${USER:-}}"
local_port="${LOCAL_PORT:-5900}"
remote_host="${REMOTE_HOST:-127.0.0.1}"
remote_port="${REMOTE_PORT:-5900}"
ssh_port="${SSH_PORT:-22}"

if [[ -z "${ssh_user}" ]]; then
  echo "ssh user is required" >&2
  usage >&2
  exit 2
fi

echo "Starting VNC SSH tunnel:"
echo "  local:  127.0.0.1:${local_port}"
echo "  remote: ${remote_host}:${remote_port}"
echo "  ssh:    ${ssh_user}@${ssh_host}:${ssh_port}"
echo
echo "Keep this terminal open, then connect VNC Viewer to 127.0.0.1:${local_port}"

exec ssh \
  -p "${ssh_port}" \
  -o ServerAliveInterval=20 \
  -o ServerAliveCountMax=3 \
  -N \
  -L "${local_port}:${remote_host}:${remote_port}" \
  "${ssh_user}@${ssh_host}"
