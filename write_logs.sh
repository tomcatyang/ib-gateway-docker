#!/bin/bash

# 配置日志文件路径
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/ib_gateway_$(date +%Y%m%d_%H%M%S).log"
PID_FILE="${LOG_DIR}/docker_logs.pid"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 检查是否已有后台进程在运行
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "日志收集进程已在运行 (PID: $OLD_PID)"
        echo "如需停止: ./stop_logs.sh"
        exit 1
    fi
fi

# 在后台持续收集日志
nohup docker logs -f algo-trader-ib-gateway-1 >> "$LOG_FILE" 2>&1 &
PID=$!

# 保存进程ID
echo $PID > "$PID_FILE"

echo "✓ 日志收集已启动"
echo "  日志文件: $LOG_FILE"
echo "  进程ID: $PID"
echo ""
echo "查看日志: tail -f $LOG_FILE"
echo "停止收集: ./stop_logs.sh"

