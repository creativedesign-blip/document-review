#!/bin/bash
# ============================================================
# 📦 AI Document Review - 安裝依賴腳本 (Linux/Mac)
# ============================================================

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        📦 AI Document Review - 安裝依賴                  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📁 項目目錄: $SCRIPT_DIR${NC}"
echo ""

# ========== 環境檢查 ==========
echo -e "${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│ 🔍 環境檢查                                              │${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"

# 檢查 Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js: $NODE_VERSION${NC}"
else
    echo -e "${RED}❌ Node.js 未安裝${NC}"
    echo -e "${YELLOW}   請安裝 Node.js: https://nodejs.org/${NC}"
    exit 1
fi

# 檢查 npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✅ npm: $NPM_VERSION${NC}"
else
    echo -e "${RED}❌ npm 未安裝${NC}"
    exit 1
fi

# 檢查 Python (優先使用較新版本，SQLite3 將通過 pysqlite3-binary 解決)
if command -v python &> /dev/null; then
    PYTHON_CMD="python"
    PIP_CMD="pip"
elif command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    PIP_CMD="pip3"
else
    echo -e "${RED}❌ Python 未安裝${NC}"
    echo -e "${YELLOW}   請安裝 Python 3.9+: https://www.python.org/${NC}"
    exit 1
fi
PYTHON_VERSION=$($PYTHON_CMD --version)
echo -e "${GREEN}✅ $PYTHON_VERSION${NC}"

echo ""

# ========== 後端依賴 ==========
echo -e "${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│ 🔧 安裝後端依賴 (Python)                                 │${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"

cd app/api

# 創建虛擬環境（如果不存在）
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}📦 創建 Python 虛擬環境...${NC}"
    $PYTHON_CMD -m venv venv
    echo -e "${GREEN}✅ 虛擬環境已創建${NC}"
fi

# 激活虛擬環境
source venv/bin/activate

# 升級 pip
echo -e "${YELLOW}📦 升級 pip...${NC}"
pip install --upgrade pip -q

# 安裝依賴
echo -e "${YELLOW}📦 安裝 Python 依賴...${NC}"
pip install -r requirements.txt -q
echo -e "${GREEN}✅ Python 依賴安裝完成${NC}"

# 檢查 .env 文件
if [ ! -f ".env" ]; then
    if [ -f ".env.tpl" ]; then
        echo ""
        echo -e "${YELLOW}⚠️  未找到 .env 文件，正在從模板創建...${NC}"
        cp .env.tpl .env
        echo -e "${GREEN}✅ 已創建 .env 文件${NC}"
        echo -e "${YELLOW}   請編輯 app/api/.env 並配置 API Key${NC}"
    fi
fi

cd "$SCRIPT_DIR"
echo ""

# ========== 前端依賴 ==========
echo -e "${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│ 🎨 安裝前端依賴 (Node.js)                                │${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"

cd app/ui

# 安裝 npm 依賴
echo -e "${YELLOW}📦 安裝 npm 依賴...${NC}"
npm install
echo -e "${GREEN}✅ npm 依賴安裝完成${NC}"

cd "$SCRIPT_DIR"
echo ""

# ========== 設置腳本權限 ==========
echo -e "${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│ 🔐 設置腳本權限                                          │${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"

chmod +x start.sh stop.sh install.sh 2>/dev/null || true
echo -e "${GREEN}✅ 腳本權限已設置${NC}"
echo ""

# ========== 完成 ==========
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 所有依賴安裝完成！${NC}"
echo ""
echo -e "${YELLOW}📌 下一步:${NC}"
echo -e "${WHITE}   1. 編輯 app/api/.env 文件，配置必要的 API Key${NC}"
echo -e "${WHITE}   2. 運行 ./start.sh 啓動服務${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

