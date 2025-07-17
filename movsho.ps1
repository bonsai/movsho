# すべてのイベントサブスクリプションを解除（テスト用）
Get-EventSubscriber | Unregister-Event -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " スクリーンショット自動移動スクリプト (PowerShell)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor DarkCyan
Write-Host ""

# スクリーンショットの保存元フォルダ
$defaultSourcePath = "C:\Users\dance\画像\Picasa\スクリーンショット"
$sourcePath = ""
while ($true) {
    $inputPath = Read-Host "スクリーンショットの保存元フォルダのパスを入力してください (デフォルト: $($defaultSourcePath))"
    
    if ([string]::IsNullOrWhiteSpace($inputPath)) {
        $sourcePath = $defaultSourcePath
        Write-Host "デフォルトパスを使用します: $($sourcePath)" -ForegroundColor DarkGreen
        break
    } elseif (-not (Test-Path $inputPath -PathType Container)) {
        Write-Host "指定されたパスはフォルダとして存在しません。正しいパスを入力してください。" -ForegroundColor Red
    } else {
        $sourcePath = $inputPath
        break
    }
}

Write-Host ""
$destinationPath = Get-Location
Write-Host "現在の作業フォルダ: $($destinationPath.Path)" -ForegroundColor Green

while ($true) {
    $confirm = Read-Host "このフォルダにスクリーンショットを移動しますか？ (y/n)"
    if ($confirm -eq "y") {
        break
    } elseif ($confirm -eq "n") {
        Write-Host "処理をキャンセルしました。" -ForegroundColor Yellow
        exit
    } else {
        Write-Host "無効な入力です。「y」または「n」を入力してください。" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
Write-Host " スクリーンショットの監視を開始します..." -ForegroundColor DarkYellow
Write-Host " 新しいスクリーンショットが作成されると即座に移動します。" -ForegroundColor DarkYellow
Write-Host " このウィンドウを閉じるか Ctrl+C を押すと停止します。" -ForegroundColor DarkYellow
Write-Host "----------------------------------------------------" -ForegroundColor DarkYellow
Write-Host ""

# イベントID作成
$eventIdentifier = "ScreenshotWatcherEvent_$([guid]::NewGuid().ToString())"
$oldErrorAction = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
Get-EventSubscriber -SourceIdentifier $eventIdentifier | Unregister-Event
$ErrorActionPreference = $oldErrorAction

# FileSystemWatcher の設定
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $sourcePath
$watcher.Filter = "*.png"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

Write-Host "$(Get-Date -Format 'HH:mm:ss') - FileSystemWatcherが設定されました。" -ForegroundColor DarkCyan
Write-Host "$(Get-Date -Format 'HH:mm:ss') - 監視パス: $($watcher.Path)" -ForegroundColor DarkCyan
Write-Host "$(Get-Date -Format 'HH:mm:ss') - フィルタ: $($watcher.Filter)" -ForegroundColor DarkCyan
Write-Host "$(Get-Date -Format 'HH:mm:ss') - イベント発生有効: $($watcher.EnableRaisingEvents)" -ForegroundColor DarkCyan

# グローバル変数
$global:DestinationPathForScreenshotMove = $destinationPath.Path
$global:ScreenshotHistory = @()

# イベントアクション
$actionScript = {
    $destinationPathFromGlobal = $global:DestinationPathForScreenshotMove
    $filePath = $Event.SourceEventArgs.FullPath
    $fileName = $Event.SourceEventArgs.Name
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $status = ""
    $message = ""

    if ($fileName -imatch "^スクリーンショット .+\.png$" -or $fileName -imatch "^Screenshot .+\.png$") {
        Start-Sleep -Milliseconds 500
        if (Test-Path $filePath) {
            try {
                $destinationFilePath = Join-Path $destinationPathFromGlobal $fileName
                if (-not (Test-Path $destinationFilePath)) {
                    Move-Item -Path $filePath -Destination $destinationPathFromGlobal -Force -ErrorAction Stop

                    # ←ここで移動後の存在チェックを追加
                    if (Test-Path $destinationFilePath) {
                        $status = "成功"
                        $message = "OK（移動後に存在確認済）"
                    } else {
                        $status = "エラー"
                        $message = "移動後にファイルが見つかりません"
                    }
                } else {
                    $status = "スキップ"
                    $message = "移動先に既に存在"
                }
            } catch {
                $status = "エラー"
                $message = $_.Exception.Message
            }
        } else {
            $status = "警告"
            $message = "移動前にファイルが消失"
        }
    } else {
        $status = "スキップ"
        $message = "スクリーンショット以外"
    }

    $global:ScreenshotHistory += [PSCustomObject]@{
        ファイル名    = $fileName
        タイムスタンプ = $timestamp
        ステータス   = $status
        詳細        = $message
    }

    # テーブル表示（Out-Stringで確実に表示）
    $table = $global:ScreenshotHistory | Select-Object -Last 10 | Format-Table -AutoSize | Out-String
    Write-Host "`n=== スクリーンショット移動履歴 (最新10件) ===" -ForegroundColor Cyan
    Write-Host $table
}

# Register-ObjectEvent
try {
    $subscriber = Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier $eventIdentifier -Action $actionScript -ErrorAction Stop
} catch {
    exit
}

if ($null -eq $subscriber) {
    Write-Host "イベントサブスクリプションの登録に失敗しました。" -ForegroundColor Red
    exit
} else {
    Write-Host "$(Get-Date -Format 'HH:mm:ss') - イベントハンドラが正常に登録されました。サブスクライバーID: $($subscriber.SubscriberId)" -ForegroundColor DarkCyan
    Write-Host "$(Get-Date -Format 'HH:mm:ss') - 監視を開始します。" -ForegroundColor DarkCyan
}

# 永続待機
while ($true) {
    Start-Sleep -Seconds 1
}
