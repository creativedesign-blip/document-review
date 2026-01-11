@echo off
chcp 65001 >nul 2>&1
title AI Document Review - 停止服務

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║        🛑 AI Document Review - 停止所有服務              ║
echo ╚══════════════════════════════════════════════════════════╝
echo.

echo 🔍 正在查找運行中的服務...
echo.

:: 停止 Uvicorn (後端)
echo 🔧 停止後端服務 (Uvicorn)...
taskkill /f /im uvicorn.exe >nul 2>&1
if errorlevel 1 (
    echo    ⚪ 後端服務未運行
) else (
    echo    ✅ 後端服務已停止
)

:: 停止 Node (前端)
echo 🎨 停止前端服務 (Node)...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":5173" ^| findstr "LISTENING"') do (
    taskkill /f /pid %%a >nul 2>&1
)
echo    ✅ 前端服務已停止

:: 停止可能殘留的 Python 進程（僅限本項目）
echo 🐍 清理 Python 進程...
for /f "tokens=2" %%a in ('tasklist /fi "imagename eq python.exe" /fo list ^| findstr "PID"') do (
    wmic process where "ProcessId=%%a" get CommandLine 2>nul | findstr "uvicorn" >nul
    if not errorlevel 1 (
        taskkill /f /pid %%a >nul 2>&1
    )
)

echo.
echo ═══════════════════════════════════════════════════════════
echo ✅ 所有服務已停止
echo ═══════════════════════════════════════════════════════════
echo.

pause

