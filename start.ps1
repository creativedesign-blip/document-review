# ============================================================
# 🚀 AI Document Review - 一鍵啓動腳本 (PowerShell)
# ============================================================
# 功能：同時啓動後端 API 和前端 UI
# 用法：右鍵點擊 start.ps1 -> 使用 PowerShell 運行
#       或在 PowerShell 中執行: .\start.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "AI Document Review - Launcher"

# 顏色輸出函數
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Banner {
    Write-Color ""
    Write-Color "╔══════════════════════════════════════════════════════════╗" "Cyan"
    Write-Color "║        🚀 AI Document Review - 一鍵啓動                  ║" "Cyan"
    Write-Color "╚══════════════════════════════════════════════════════════╝" "Cyan"
    Write-Color ""
}

# 檢查 Node.js
function Test-NodeJS {
    try {
        $version = node --version 2>$null
        if ($version) {
            Write-Color "✅ Node.js: $version" "Green"
            return $true
        }
    } catch {}
    Write-Color "❌ Node.js 未安裝，請先安裝 Node.js" "Red"
    return $false
}

# 檢查 Python
function Test-Python {
    try {
        $version = python --version 2>$null
        if ($version) {
            Write-Color "✅ Python: $version" "Green"
            return $true
        }
    } catch {}
    Write-Color "❌ Python 未安裝，請先安裝 Python" "Red"
    return $false
}

# 主流程
Write-Banner

$ProjectRoot = $PSScriptRoot
Write-Color "📁 項目目錄: $ProjectRoot" "Yellow"
Write-Color ""

# 環境檢查
Write-Color "🔍 環境檢查..." "Yellow"
$nodeOk = Test-NodeJS
$pythonOk = Test-Python

if (-not ($nodeOk -and $pythonOk)) {
    Write-Color ""
    Write-Color "⚠️  請先安裝缺失的依賴後重試" "Red"
    Read-Host "按 Enter 鍵退出"
    exit 1
}

Write-Color ""

# 檢查環境變量文件
$envFile = Join-Path $ProjectRoot "app\api\.env"
if (-not (Test-Path $envFile)) {
    Write-Color "⚠️  未找到 app\api\.env 文件" "Yellow"
    Write-Color "   請複製 app\api\.env.tpl 並重命名爲 .env，然後配置 API Key" "Yellow"
    Write-Color ""
}

# 啓動後端
Write-Color "🔧 啓動後端服務 (FastAPI)..." "Cyan"
$backendPath = Join-Path $ProjectRoot "app\api"
$backendCmd = @"
cd '$backendPath'
if (Test-Path 'venv\Scripts\Activate.ps1') {
    & '.\venv\Scripts\Activate.ps1'
}
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd -WindowStyle Normal

Write-Color "   ✅ 後端服務已在新窗口啓動" "Green"
Write-Color "   📍 API 地址: http://localhost:8000" "White"
Write-Color "   📍 API 文檔: http://localhost:8000/docs" "White"
Write-Color ""

# 等待後端啓動
Write-Color "⏳ 等待後端服務啓動 (5秒)..." "Yellow"
Start-Sleep -Seconds 5

# 啓動前端
Write-Color "🎨 啓動前端服務 (Vite)..." "Cyan"
$frontendPath = Join-Path $ProjectRoot "app\ui"
$frontendCmd = @"
cd '$frontendPath'
npm run dev
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd -WindowStyle Normal

Write-Color "   ✅ 前端服務已在新窗口啓動" "Green"
Write-Color "   📍 前端地址: http://localhost:5173" "White"
Write-Color ""

# 完成
Write-Color "═══════════════════════════════════════════════════════════" "Cyan"
Write-Color "🎉 所有服務已啓動！" "Green"
Write-Color ""
Write-Color "📌 服務地址:" "Yellow"
Write-Color "   • 前端 UI:  http://localhost:5173" "White"
Write-Color "   • 後端 API: http://localhost:8000" "White"
Write-Color "   • API 文檔: http://localhost:8000/docs" "White"
Write-Color ""
Write-Color "📌 關閉服務:" "Yellow"
Write-Color "   • 關閉各自的 PowerShell 窗口即可停止服務" "White"
Write-Color "═══════════════════════════════════════════════════════════" "Cyan"
Write-Color ""

# 詢問是否打開瀏覽器
$openBrowser = Read-Host "是否打開瀏覽器？(Y/n)"
if ($openBrowser -ne "n" -and $openBrowser -ne "N") {
    Start-Process "http://localhost:5173"
}

Write-Color ""
Write-Color "按 Enter 鍵關閉此窗口（服務會繼續運行）..." "Gray"
Read-Host

