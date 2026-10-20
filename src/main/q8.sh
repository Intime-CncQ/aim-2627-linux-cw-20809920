#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

mkdir -p "$output"

if [ "$action" = "repair" ]; then
    source "$input/process.env"

    # 定位与停止采集器

    {
        echo "pid=$TARGET_PID"
        echo "user=$(ps -p "$TARGET_PID" -o user= | awk '{print $1}')"
        echo "state=$(ps -p "$TARGET_PID" -o stat= | awk '{print $1}')"
        echo "command=$(ps -p "$TARGET_PID" -o args=)"
    } > "$output/process.txt"

    grep 'TICK' "$WORKER_LOG" | tail -n 2 > "$output/collector-sample.log" || true

    kill "$TARGET_PID" 2>/dev/null || true
    for i in $(seq 1 50); do
        if ! kill -0 "$TARGET_PID" 2>/dev/null; then
            break
        fi
        sleep 0.1
    done

    # 恢复 HTTP 服务

    kill "$SERVICE_PID" 2>/dev/null || true
    for i in $(seq 1 50); do
        if ! kill -0 "$SERVICE_PID" 2>/dev/null; then
            break
        fi
        sleep 0.1
    done

    cat > "$output/server.conf" <<EOF
bind=127.0.0.1
port=$TARGET_PORT
route=/status
EOF

    bash "$START_TOOL" "$output/server.conf" "$output/service"

    for i in $(seq 1 50); do
        code=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$TARGET_PORT/status" || true)
        if [ "$code" = "200" ]; then
            echo "200" > "$output/http-status.txt"
            echo "SENTRY READY" > "$output/http-body.txt"
            break
        fi
        sleep 0.1
    done

elif [ "$action" = "cleanup" ]; then
    if [ -f "$output/service/pid" ]; then
        SVC_PID=$(cat "$output/service/pid")
        kill "$SVC_PID" 2>/dev/null || true
        for i in $(seq 1 50); do
            if ! kill -0 "$SVC_PID" 2>/dev/null; then
                break
            fi
            sleep 0.1
        done
    fi
fi
