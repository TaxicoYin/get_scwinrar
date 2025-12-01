$URL = "https://www.win-rar.com/latestnews.html?&L=0"
$HTML = Invoke-WebRequest -Uri $URL -UseBasicParsing
$Content = $HTML.Content

$items = [regex]::Matches($Content, '<div class="news-list-item">(.*?)</div>', 'Singleline')

$releaseDate = $null
$version = $null
$version_nodot = $null
$latestTitle = $null

foreach ($item in $items) {
    $block = $item.Groups[1].Value

    $matchDate  = [regex]::Match($block, '<span class="news-list-date">(\d{2}\.\d{2}\.\d{4})</span>')
    $matchTitle = [regex]::Match($block, '<h2><a[^>]*>([^<]+)</a>')

    if ($matchDate.Success -and $matchTitle.Success) {
        $rawDate = $matchDate.Groups[1].Value
        $title   = $matchTitle.Groups[1].Value.Trim()

        if ($title -notmatch 'Final released') { continue }
        if ($title -match 'Beta') { continue }

        $matchVersion = [regex]::Match($title, 'WinRAR\s+([\d\.]+)')
        if ($matchVersion.Success) {
            $version = $matchVersion.Groups[1].Value
            $version_nodot = $version -replace '\.', ''
            $releaseDate = $rawDate -replace '(\d{2})\.(\d{2})\.(\d{4})','$3-$2-$1'
            $latestTitle = $title
            break
        }
    }
}

if (-not $releaseDate -or -not $version) {
    Write-Host "未找到最新正式版新闻或版本号"
    exit 1
}

Write-Host "最新正式版版本: $latestTitle"
Write-Host "发布日期: $releaseDate"
Write-Host "最新版本号: $version"

$download_url = "https://www.win-rar.com/fileadmin/winrar-versions/partners/hua/winrar-x64-${version_nodot}sc.exe"
Write-Host "商业版下载链接: $download_url"

$startDate = [datetime]::ParseExact($releaseDate, 'yyyy-MM-dd', $null)
$maxDays = 60
$found = $false
$url = ""

Write-Host "正在尝试构造并验证 WinRAR 简体中文下载暗链..."
for ($i = 0; $i -lt $maxDays; $i++) {
    $tryDate = $startDate.AddDays(-$i).ToString("yyyyMMdd")
    $url = "https://www.win-rar.com/fileadmin/winrar-versions/sc/sc${tryDate}/rrlb/winrar-x64-${version_nodot}sc.exe"
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -ErrorAction Stop
        Write-Host "找到暗链下载地址: $url"
        $found = $true
        break
    } catch {}
}

if (-not $found) {
    Write-Host "未能在过去 $maxDays 天内找到匹配的暗链地址。"
    exit 1
}

$desktopPath = [Environment]::GetFolderPath("Desktop")
$filename = Join-Path $desktopPath "winrar-x64-${version_nodot}-sc.exe"

Write-Host "正在下载到桌面..."
try {
    Invoke-WebRequest -Uri $url -OutFile $filename -UseBasicParsing
    Write-Host "下载完成，文件位置: $filename"
} catch {
    Write-Host "下载失败: $($_.Exception.Message)"
}
