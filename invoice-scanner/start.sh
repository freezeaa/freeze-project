#!/bin/bash
# 发票扫码助手 - 一键启动脚本（支持固定域名 Tunnel）
# 用法: bash start.sh

set -euo pipefail
cd "$(dirname "$0")"

LOCAL_URL="http://localhost:5000"
CLOUDFLARED="./cloudflared"
TUNNEL_ENV_FILE="${TUNNEL_ENV_FILE:-./tunnel.local.env}"
FLASK_PID=""
TUNNEL_PID=""

if [ -f "$TUNNEL_ENV_FILE" ]; then
    # shellcheck disable=SC1090
    source "$TUNNEL_ENV_FILE"
fi

cleanup() {
    echo ""
    echo "正在关闭服务..."

    if [ -n "${TUNNEL_PID:-}" ]; then
        kill "$TUNNEL_PID" 2>/dev/null || true
        wait "$TUNNEL_PID" 2>/dev/null || true
    fi

    if [ -n "${FLASK_PID:-}" ]; then
        kill "$FLASK_PID" 2>/dev/null || true
        wait "$FLASK_PID" 2>/dev/null || true
    fi

    rm -f flask.pid cloudflared.pid
    echo "已关闭。"
    exit 0
}
trap cleanup INT TERM

wait_for_named_tunnel() {
    local log_file="$1"
    for i in $(seq 1 30); do
        if grep -q "Registered tunnel connection" "$log_file" 2>/dev/null; then
            return 0
        fi
        if ! kill -0 "$TUNNEL_PID" 2>/dev/null; then
            return 1
        fi
        sleep 1
    done
    return 1
}

wait_for_quick_tunnel() {
    local log_file="$1"
    for i in $(seq 1 30); do
        if grep -q "trycloudflare.com" "$log_file" 2>/dev/null; then
            grep -o 'https://[^ ]*trycloudflare.com' "$log_file" | head -1
            return 0
        fi
        local url
        url=$(curl -s http://127.0.0.1:20241/metrics 2>/dev/null | grep -o 'https://[^\"]*trycloudflare.com' | head -1 || true)
        if [ -n "$url" ]; then
            echo "$url"
            return 0
        fi
        if ! kill -0 "$TUNNEL_PID" 2>/dev/null; then
            return 1
        fi
        sleep 1
    done
    return 1
}

echo ""
echo "====================================="
echo "  发票扫码助手 - 启动中..."
echo "====================================="
echo ""

if ! command -v python3 &> /dev/null; then
    echo "[错误] 未找到 python3，请先安装 Python 3"
    exit 1
fi

if [ ! -d "venv" ]; then
    echo "[1/3] 创建虚拟环境..."
    python3 -m venv venv
fi

echo "[2/3] 安装依赖..."
venv/bin/python -m pip install -q -r requirements.txt

echo "[3/3] 启动 Flask 服务..."
venv/bin/python -c 'from app import app; app.run(host="0.0.0.0", port=5000, debug=False)' > flask.out 2>&1 &
FLASK_PID=$!
echo "$FLASK_PID" > flask.pid
sleep 3

if ! kill -0 "$FLASK_PID" 2>/dev/null; then
    echo "[错误] Flask 启动失败"
    exit 1
fi
echo "  ✓ Flask 服务已启动: $LOCAL_URL"

if [ ! -f "$CLOUDFLARED" ]; then
    echo ""
    echo "[提示] 未找到 cloudflared，仅支持本地访问"
    echo "  本地访问: $LOCAL_URL"
    echo "  下载 cloudflared: https://github.com/cloudflare/cloudflared/releases"
    echo ""
    echo "按 Ctrl+C 停止服务"
    wait "$FLASK_PID"
    exit 0
fi

echo "  ✓ 正在启动公网隧道..."
TUNNEL_LOG=$(mktemp)
URL=""

if [ -n "${TUNNEL_TOKEN:-}" ]; then
    TUNNEL_HOSTNAME="${TUNNEL_HOSTNAME:-invoice.api-freeze.fun}"
    echo "  ✓ 检测到固定 Tunnel 配置: $TUNNEL_HOSTNAME"
    "$CLOUDFLARED" tunnel run --token "$TUNNEL_TOKEN" > "$TUNNEL_LOG" 2>&1 &
    TUNNEL_PID=$!
    echo "$TUNNEL_PID" > cloudflared.pid

    if wait_for_named_tunnel "$TUNNEL_LOG"; then
        URL="https://$TUNNEL_HOSTNAME"
    else
        echo ""
        echo "[警告] 固定 Tunnel 启动超时或失败，仅支持本地访问"
        tail -n 20 "$TUNNEL_LOG" || true
    fi
else
    "$CLOUDFLARED" tunnel --url "$LOCAL_URL" > "$TUNNEL_LOG" 2>&1 &
    TUNNEL_PID=$!
    echo "$TUNNEL_PID" > cloudflared.pid

    QUICK_URL=$(wait_for_quick_tunnel "$TUNNEL_LOG" || true)
    if [ -n "${QUICK_URL:-}" ]; then
        URL="$QUICK_URL"
    else
        echo ""
        echo "[警告] 随机 Tunnel 启动超时，仅支持本地访问"
    fi
fi

if [ -n "$URL" ]; then
    echo ""
    echo "====================================================="
    echo ""
    echo "  发票扫码助手已启动!"
    echo ""
    echo "  本地访问: $LOCAL_URL"
    echo "  公网访问: $URL"
    echo ""
    echo "  手机打开上面的公网地址即可使用"
    echo "  按 Ctrl+C 停止所有服务"
    echo ""
    echo "====================================================="
    echo ""
else
    echo ""
    echo "  本地访问: $LOCAL_URL"
    echo ""
fi

rm -f "$TUNNEL_LOG"
wait "$FLASK_PID"
