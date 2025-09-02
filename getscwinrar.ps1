# 设置目标页面
$URL = "https://www.win-rar.com/singlenewsview.html?&L=0"

# 获取页面内容
$HTML = Invoke-WebRequest -Uri $URL -UseBasicParsing
$Content = $HTML.Content

# 提取版本号（如 WinRAR 7.13）
$versionLine = ($Content -split "`n" | Select-String -Pattern 'WinRAR\s+\d+(\.\d+)+') | Select-Object -First 1
$version = $versionLine.Matches.Value -replace 'WinRAR\s+', ''

# 提取发布日期（如 30.07.2025 → 2025-07-30）
$rawDate = [regex]::Match(
    $Content,
    'class="[^"]*\bnews-single-timedata\b[^"]*"[^>]*>.*?(\d{2}\.\d{2}\.\d{4})',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
).Groups[1].Value.Trim()

if (-not $rawDate) {
    Write-Host "未找到日期，请检查页面结构是否变化"
    exit 1
}

try {
    $releaseDate = [datetime]::ParseExact($rawDate, 'dd.MM.yyyy', $null).ToString('yyyy-MM-dd')
} catch {
    Write-Host "日期解析失败，原始值为: $rawDate"
    exit 1
}

# 输出结果
Write-Host "发布日期: $releaseDate"
Write-Host "最新版本号: $version"

# 构造下载地址（合作伙伴版）
$version_nodot = $version -replace '\.', ''
$download_url = "https://www.win-rar.com/fileadmin/winrar-versions/partners/hua/winrar-x64-${version_nodot}sc.exe"
Write-Host "下载地址: $download_url"

# 暗链尝试逻辑
Write-Host "正在尝试构造并验证 WinRAR 简体中文下载暗链..."

$startDate = [datetime]::ParseExact($releaseDate, 'yyyy-MM-dd', $null)
$maxDays = 60
$found = $false

for ($i = 0; $i -lt $maxDays; $i++) {
    $tryDate = $startDate.AddDays(-$i).ToString("yyyyMMdd")
    $url = "https://www.win-rar.com/fileadmin/winrar-versions/sc/sc${tryDate}/rrlb/winrar-x64-${version_nodot}sc.exe"

    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -ErrorAction Stop
        Write-Host "找到暗链下载地址:"$url
        $found = $true
        break
    } catch {
        # 链接不存在，继续尝试
    }
}

if (-not $found) {
    Write-Host "未能在过去 $maxDays 天内找到匹配的暗链地址。可能尚未发布商业版或路径已变动。"
    exit 1
}

# 下载文件
# 获取当前用户桌面路径
$desktopPath = [Environment]::GetFolderPath("Desktop")

# 构造完整文件路径
$filename = Join-Path $desktopPath "winrar-x64-${version_nodot}-sc.exe"

# 下载文件到桌面
Write-Host "正在下载到桌面..."
try {
    Invoke-WebRequest -Uri $url -OutFile $filename -UseBasicParsing
    Write-Host "下载完成，文件位置: $filename"
} catch {
    Write-Host "下载失败"
}

