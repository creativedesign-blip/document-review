@echo off
chcp 65001 >nul 2>&1
title AI Document Review - 一鍵啓動

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║        🚀 AI Document Review - 一鍵啓動                  ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

cd /d "%~dp0"

echo 📁 項目目錄: %CD%
echo.

:: 檢查 Node.js
echo 🔍 檢查 Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js 未安裝，請先安裝 Node.js
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('node --version') do echo ✅ Node.js: %%i

:: 檢查 Python
echo 🔍 檢查 Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python 未安裝，請先安裝 Python
    pause
    exit /b 1
)
for /f "tokens=*" %%i in ('python --version') do echo ✅ Python: %%i

echo.

:: 檢查環境變量文件
if not exist "app\api\.env" (
    echo ⚠️  未找到 app\api\.env 文件
    echo    請複製 app\api\.env.tpl 並重命名爲 .env，然後配置 API Key
    echo.
)

:: 啓動後端
echo 🔧 啓動後端服務 (FastAPI)...
start "Backend - FastAPI" cmd /k "cd /d %~dp0app\api && if exist venv\Scripts\activate.bat (call venv\Scripts\activate.bat) && python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload"
echo    ✅ 後端服務已在新窗口啓動
echo    📍 API 地址: http://localhost:8000
echo    📍 API 文檔: http://localhost:8000/docs
echo.

:: 等待後端啓動
echo ⏳ 等待後端服務啓動 (5秒)...
timeout /t 5 /nobreak >nul

:: 啓動前端
echo 🎨 啓動前端服務 (Vite)...
start "Frontend - Vite" cmd /k "cd /d %~dp0app\ui && npm run dev"
echo    ✅ 前端服務已在新窗口啓動
echo    📍 前端地址: http://localhost:5173
echo.

:: 完成
echo ═══════════════════════════════════════════════════════════
echo 🎉 所有服務已啓動！
echo.
echo 📌 服務地址:
echo    • 前端 UI:  http://localhost:5173
echo    • 後端 API: http://localhost:8000
echo    • API 文檔: http://localhost:8000/docs
echo.
echo 📌 關閉服務:
echo    • 關閉各自的命令行窗口即可停止服務
echo ═══════════════════════════════════════════════════════════
echo.

:: 詢問是否打開瀏覽器
set /p openBrowser="是否打開瀏覽器？(Y/n): "
if /i not "%openBrowser%"=="n" (
    start http://localhost:5173
)

echo.
echo 按任意鍵關閉此窗口（服務會繼續運行）...
pause >nul

