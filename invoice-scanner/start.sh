#!/bin/bash
# 发票扫码助手 - 一键启动脚本（含公网隧道）
# 用法: bash start.sh

set -e
cd "$(dirname "$0")"

cleanup() {
    echo ""
    echo "正在关闭服务..."
    kill $FLASK_PID 2>/dev/null
    kill $TUNNEL_PID 2>/dev/null
    wait $FLASK_PID 2>/dev/null
    wait $TUNNEL_PID 2>/dev/null
    echo "已关闭。"
    exit 0
}
trap cleanup INT TERM

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
source venv/bin/activate
pip install -q -r requirements.txt

echo "[3/3] 启动 Flask 服务..."
python3 app.py > /dev/null 2>&1 &
FLASK_PID=$!
sleep 2

if ! kill -0 $FLASK_PID 2>/dev/null; then
    echo "[错误] Flask 启动失败"
    exit 1
fi
echo "  ✓ Flask 服务已启动: http://localhost:5000"

CLOUDFLARED="./cloudflared"
if [ ! -f "$CLOUDFLARED" ]; then
    echo ""
    echo "[提示] 未找到 cloudflared，仅支持本地访问"
    echo "  本地访问: http://localhost:5000"
    echo "  下载 cloudflared: https://github.com/cloudflare/cloudflared/releases"
    echo ""
    echo "按 Ctrl+C 停止服务"
    wait $FLASK_PID
    exit 0
fi

echo "  ✓ 正在启动公网隧道..."

TUNNEL_LOG=$(mktemp)
$CLOUDFLARED tunnel --url http://localhost:5000 > "$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!

URL=""
for i in $(seq 1 30); do
    if grep -q "trycloudflare.com" "$TUNNEL_LOG" 2>/dev/null; then
        URL=$(grep -o 'https://[^ ]*trycloudflare.com' "$TUNNEL_LOG" | head -1)
        break
    fi
    URL=$(curl -s http://127.0.0.1:20241/metrics 2>/dev/null | grep -o 'https://[^\"]*trycloudflare.com' | head -1 || true)
    if [ -n "$URL" ]; then
        break
    fi
    sleep 1
done

if [ -n "$URL" ]; then
    echo ""
    echo "====================================================="
    echo ""
    echo "  发票扫码助手已启动!"
    echo ""
    echo "  本地访问: http://localhost:5000"
    echo "  公网访问: $URL"
    echo ""
    echo "  手机打开上面的公网地址即可使用"
    echo "  按 Ctrl+C 停止所有服务"
    echo ""
    echo "====================================================="
    echo ""
else
    echo ""
    echo "[警告] 隧道启动超时，仅支持本地访问"
    echo "  本地访问: http://localhost:5000"
    echo ""
fi

rm -f "$TUNNEL_LOG"
wait $FLASK_PID
