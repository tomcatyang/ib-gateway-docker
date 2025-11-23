#!/bin/bash
# docker-compose up --build -d
docker-compose down
#删除已经退出的容器
# docker container prune -f
#删除已经退出的镜像
# docker image prune -f
#构建并启动
docker-compose up --build -d