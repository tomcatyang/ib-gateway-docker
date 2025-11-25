#!/bin/bash

LOG_DIR="./logs"
PID_FILE="${LOG_DIR}/docker_logs.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "未找到运行中的日志收集进程"
    exit 1
fi

PID=$(cat "$PID_FILE")

if ps -p "$PID" > /dev/null 2>&1; then
    kill "$PID"
    echo "✓ 已停止日志收集进程 (PID: $PID)"
    rm "$PID_FILE"
else
    echo "进程 $PID 未运行，清理PID文件"
    rm "$PID_FILE"
fi

