@echo off
chcp 65001 >nul 2>&1
title AI Document Review - 安裝依賴

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║        📦 AI Document Review - 安裝依賴                  ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

cd /d "%~dp0"
echo 📁 項目目錄: %CD%
echo.

:: ========== 檢查環境 ==========
echo ┌──────────────────────────────────────────────────────────┐
echo │ 🔍 環境檢查                                              │
echo └──────────────────────────────────────────────────────────┘

:: 檢查 Node.js
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js 未安裝
    echo    請訪問 https://nodejs.org/ 下載安裝
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do echo ✅ Node.js: %%i

:: 檢查 npm
npm --version >nul 2>&1
if errorlevel 1 (
    echo ❌ npm 未安裝
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('npm --version') do echo ✅ npm: %%i

:: 檢查 Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python 未安裝
    echo    請訪問 https://www.python.org/ 下載安裝
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('python --version') do echo ✅ Python: %%i

echo.

:: ========== 後端依賴 ==========
echo ┌──────────────────────────────────────────────────────────┐
echo │ 🔧 安裝後端依賴 (Python)                                 │
echo └──────────────────────────────────────────────────────────┘

cd app\api

:: 創建虛擬環境（如果不存在）
if not exist "venv" (
    echo 📦 創建 Python 虛擬環境...
    python -m venv venv
    if errorlevel 1 (
        echo ❌ 創建虛擬環境失敗
        pause
        exit /b 1
    )
    echo ✅ 虛擬環境已創建
)

:: 激活虛擬環境
call venv\Scripts\activate.bat

:: 安裝依賴
echo 📦 安裝 Python 依賴...
pip install -r requirements.txt -q
if errorlevel 1 (
    echo ❌ 安裝 Python 依賴失敗
    pause
    exit /b 1
)
echo ✅ Python 依賴安裝完成

:: 檢查 .env 文件
if not exist ".env" (
    if exist ".env.tpl" (
        echo.
        echo ⚠️  未找到 .env 文件，正在從模板創建...
        copy .env.tpl .env >nul
        echo ✅ 已創建 .env 文件，請編輯並配置 API Key
    )
)

cd ..\..
echo.

:: ========== 前端依賴 ==========
echo ┌──────────────────────────────────────────────────────────┐
echo │ 🎨 安裝前端依賴 (Node.js)                                │
echo └──────────────────────────────────────────────────────────┘

cd app\ui

:: 安裝 npm 依賴
echo 📦 安裝 npm 依賴...
call npm install
if errorlevel 1 (
    echo ❌ 安裝 npm 依賴失敗
    pause
    exit /b 1
)
echo ✅ npm 依賴安裝完成

cd ..\..
echo.

:: ========== 完成 ==========
echo ═══════════════════════════════════════════════════════════
echo 🎉 所有依賴安裝完成！
echo.
echo 📌 下一步:
echo    1. 編輯 app\api\.env 文件，配置必要的 API Key
echo    2. 運行 start.bat 啓動服務
echo ═══════════════════════════════════════════════════════════
echo.

pause

