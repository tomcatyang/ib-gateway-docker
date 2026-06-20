#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# 读取本机 git 代理并转换为构建容器可访问的 host.docker.internal。
docker_build_proxy() {
  local proxy host port userpass
  proxy="$(git config --global --get https.https://github.com.proxy \
    || git config --global --get http.https://github.com.proxy \
    || true)"
  [ -n "${proxy}" ] || return 0

  if [[ "${proxy}" =~ ^(https?://)([^@/]+@)?([^:/]+):([0-9]+)$ ]]; then
    userpass="${BASH_REMATCH[2]}"
    host="${BASH_REMATCH[3]}"
    port="${BASH_REMATCH[4]}"
    if [ "${host}" != "host.docker.internal" ]; then
      proxy="${BASH_REMATCH[1]}${userpass}host.docker.internal:${port}"
    fi
  fi
  echo "${proxy}"
}

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

BUILD_PROXY="$(docker_build_proxy || true)"
if [ -n "${BUILD_PROXY:-}" ]; then
  export HTTP_PROXY="${BUILD_PROXY}"
  export HTTPS_PROXY="${BUILD_PROXY}"
  export NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,host.docker.internal,mirrors.aliyun.com,archive.ubuntu.com,security.ubuntu.com,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16}"
  echo "Docker 构建代理: ${BUILD_PROXY%%@*}@***"
fi

docker-compose down
#删除已经退出的容器
# docker container prune -f
#删除已经退出的镜像
# docker image prune -f
#构建并启动
docker-compose up --build -d

# docker-compose up --build