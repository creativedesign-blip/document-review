#!/bin/bash
# ============================================================
# 🚀 AI Document Review - 一鍵啓動腳本 (Linux/Mac)
# ============================================================
# 功能：同時啓動後端 API 和前端 UI
# 用法：chmod +x start.sh && ./start.sh
# ============================================================

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 獲取腳本所在目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        🚀 AI Document Review - 一鍵啓動                  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📁 項目目錄: $SCRIPT_DIR${NC}"
echo ""

# ========== 環境檢查 ==========
echo -e "${YELLOW}🔍 環境檢查...${NC}"

# 檢查 Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js: $NODE_VERSION${NC}"
else
    echo -e "${RED}❌ Node.js 未安裝，請先安裝 Node.js${NC}"
    exit 1
fi

# 檢查 Python (優先使用較新版本，與 install.sh 保持一致)
if command -v python &> /dev/null; then
    PYTHON_CMD="python"
elif command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
else
    echo -e "${RED}❌ Python 未安裝，請先安裝 Python${NC}"
    exit 1
fi
PYTHON_VERSION=$($PYTHON_CMD --version)
echo -e "${GREEN}✅ $PYTHON_VERSION${NC}"

echo ""

# 檢查環境變量文件
if [ ! -f "app/api/.env" ]; then
    echo -e "${YELLOW}⚠️  未找到 app/api/.env 文件${NC}"
    echo -e "${YELLOW}   請複製 app/api/.env.tpl 並重命名爲 .env，然後配置 API Key${NC}"
    echo ""
fi

# ========== 啓動後端 ==========
echo -e "${CYAN}🔧 啓動後端服務 (FastAPI)...${NC}"

cd app/api

# 激活虛擬環境（如果存在）
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
fi

# 在後臺啓動後端
$PYTHON_CMD -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload &
BACKEND_PID=$!

echo -e "${GREEN}   ✅ 後端服務已啓動 (PID: $BACKEND_PID)${NC}"
echo -e "${WHITE}   📍 API 地址: http://localhost:8000${NC}"
echo -e "${WHITE}   📍 API 文件: http://localhost:8000/docs${NC}"
echo ""

cd "$SCRIPT_DIR"

# 等待後端啓動
echo -e "${YELLOW}⏳ 等待後端服務啓動 (3秒)...${NC}"
sleep 3

# ========== 啓動前端 ==========
echo -e "${CYAN}🎨 啓動前端服務 (Vite)...${NC}"

cd app/ui

# 在後臺啓動前端
npm run dev &
FRONTEND_PID=$!

echo -e "${GREEN}   ✅ 前端服務已啓動 (PID: $FRONTEND_PID)${NC}"
echo -e "${WHITE}   📍 前端地址: http://localhost:5173${NC}"
echo ""

cd "$SCRIPT_DIR"

# ========== 保存 PID ==========
echo "$BACKEND_PID" > .backend.pid
echo "$FRONTEND_PID" > .frontend.pid

# ========== 完成 ==========
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 所有服務已啓動！${NC}"
echo ""
echo -e "${YELLOW}📌 服務地址:${NC}"
echo -e "${WHITE}   • 前端 UI:  http://localhost:5173${NC}"
echo -e "${WHITE}   • 後端 API: http://localhost:8000${NC}"
echo -e "${WHITE}   • API 文件: http://localhost:8000/docs${NC}"
echo ""
echo -e "${YELLOW}📌 進程 PID:${NC}"
echo -e "${WHITE}   • 後端: $BACKEND_PID${NC}"
echo -e "${WHITE}   • 前端: $FRONTEND_PID${NC}"
echo ""
echo -e "${YELLOW}📌 停止服務:${NC}"
echo -e "${WHITE}   • 運行 ./stop.sh${NC}"
echo -e "${WHITE}   • 或按 Ctrl+C${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# 詢問是否打開瀏覽器
read -p "是否打開瀏覽器？(Y/n): " OPEN_BROWSER
if [ "$OPEN_BROWSER" != "n" ] && [ "$OPEN_BROWSER" != "N" ]; then
    # 跨平臺打開瀏覽器
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:5173" &
    elif command -v open &> /dev/null; then
        open "http://localhost:5173" &
    fi
fi

echo ""
echo -e "${WHITE}按 Ctrl+C 停止所有服務...${NC}"

# 捕獲 Ctrl+C 信號
trap 'echo ""; echo "🛑 正在停止服務..."; kill $BACKEND_PID 2>/dev/null; kill $FRONTEND_PID 2>/dev/null; rm -f .backend.pid .frontend.pid; echo "✅ 服務已停止"; exit 0' SIGINT SIGTERM

# 等待進程
wait

