
$URL = "https://www.win-rar.com/latestnews.html?&L=0"

# --------------------------------------------
# 获取 WinRAR 最新新闻
# --------------------------------------------

Write-Host "正在获取 WinRAR 最新新闻..."

try {
    $HTML = Invoke-WebRequest `
        -Uri $URL `
        -UseBasicParsing `
        -ErrorAction Stop

    $Content = $HTML.Content
}
catch {
    Write-Host ""
    Write-Host "获取 WinRAR 新闻页面失败:"
    Write-Host $_.Exception.Message
    exit 1
}

# 获取所有新闻项目
$items = [regex]::Matches(
    $Content,
    '<div class="news-list-item">(.*?)</div>',
    'Singleline'
)

$releaseDate = $null
$version = $null
$version_nodot = $null
$latestTitle = $null

# --------------------------------------------
# 寻找最新正式版
# --------------------------------------------

Write-Host "正在寻找最新 Final Release..."

foreach ($item in $items) {

    $block = $item.Groups[1].Value

    # 获取发布日期
    $matchDate = [regex]::Match(
        $block,
        '<span class="news-list-date">\s*(\d{2}\.\d{2}\.\d{4})\s*</span>'
    )

    # 获取新闻标题
    $matchTitle = [regex]::Match(
        $block,
        '<h2>\s*<a[^>]*>\s*(.*?)\s*</a>\s*</h2>',
        'Singleline'
    )

    if (-not $matchDate.Success -or -not $matchTitle.Success) {
        continue
    }

    $rawDate = $matchDate.Groups[1].Value

    $title = $matchTitle.Groups[1].Value.Trim()

    # HTML 解码
    $title = [System.Net.WebUtility]::HtmlDecode($title)

    # 删除可能存在的 HTML 标签
    $title = $title -replace '<[^>]+>', ''

    # 清理多余空白
    $title = $title -replace '\s+', ' '
    $title = $title.Trim()

    Write-Host "检查新闻: $title"

    # ----------------------------------------
    # 只匹配正式版
    # Beta / Alpha / RC 等自动跳过
    # ----------------------------------------

    if ($title -notmatch '\bFinal released\b') {
        continue
    }

    # ----------------------------------------
    # 提取版本号
    # ----------------------------------------

    $matchVersion = [regex]::Match(
        $title,
        'WinRAR\s+([\d\.]+)'
    )

    if ($matchVersion.Success) {

        $version = $matchVersion.Groups[1].Value

        # 7.23 -> 723
        $version_nodot = $version -replace '\.', ''

        # DD.MM.YYYY -> YYYY-MM-DD
        $releaseDate = $rawDate -replace `
            '(\d{2})\.(\d{2})\.(\d{4})', `
            '$3-$2-$1'

        $latestTitle = $title

        break
    }
}

# --------------------------------------------
# 检查是否找到正式版
# --------------------------------------------

if (-not $releaseDate -or -not $version) {

    Write-Host ""
    Write-Host "未找到最新正式版新闻或版本号。"
    exit 1
}

Write-Host ""
Write-Host "========================================"
Write-Host "最新正式版: $latestTitle"
Write-Host "发布日期:   $releaseDate"
Write-Host "版本号:     $version"
Write-Host "========================================"
Write-Host ""

# --------------------------------------------
# 简体中文商业版下载链接
# --------------------------------------------

$commercial_url = `
    "https://www.win-rar.com/fileadmin/winrar-versions/partners/hua/winrar-x64-${version_nodot}sc.exe"

Write-Host "简体中文商业版下载链接:"
Write-Host $commercial_url
Write-Host ""

# --------------------------------------------
# 设置暗链搜索范围
# --------------------------------------------

$startDate = [datetime]::ParseExact(
    $releaseDate,
    'yyyy-MM-dd',
    $null
)

$maxDays = 60

$found = $false
$url = ""

Write-Host "正在寻找 WinRAR 简体中文下载暗链..."
Write-Host "搜索范围: 正式版发布日期前 $maxDays 天"
Write-Host ""

# --------------------------------------------
# 搜索暗链
# --------------------------------------------

for ($i = 0; $i -lt $maxDays; $i++) {

    $currentDate = $startDate.AddDays(-$i)

    $tryDate = $currentDate.ToString("yyyyMMdd")

    $testUrl = `
        "https://www.win-rar.com/fileadmin/winrar-versions/sc/sc${tryDate}/rrlb/winrar-x64-${version_nodot}sc.exe"

    Write-Host `
        "检查: $($currentDate.ToString('yyyy-MM-dd'))"

    # ----------------------------------------
    # 第一种方式：HEAD
    # 不下载文件，只检查 HTTP 状态
    # ----------------------------------------

    try {

        $response = Invoke-WebRequest `
            -Uri $testUrl `
            -Method Head `
            -UseBasicParsing `
            -ErrorAction Stop

        if (
            $response.StatusCode -ge 200 -and
            $response.StatusCode -lt 400
        ) {

            $url = $testUrl
            $found = $true

            Write-Host ""
            Write-Host "找到暗链下载地址:"
            Write-Host $url

            break
        }
    }
    catch {
        # HEAD 失败，继续使用 GET 验证
    }

    # ----------------------------------------
    # 第二种方式：GET
    # HEAD 不支持时进行备用验证
    # ----------------------------------------

    try {

        $request = [System.Net.HttpWebRequest]::Create($testUrl)

        $request.Method = "GET"
        $request.Timeout = 10000
        $request.AllowAutoRedirect = $true

        $response = $request.GetResponse()

        if (
            $response.StatusCode -ge 200 -and
            $response.StatusCode -lt 400
        ) {

            $url = $testUrl
            $found = $true

            $response.Close()

            Write-Host ""
            Write-Host "找到暗链下载地址:"
            Write-Host $url

            break
        }

        $response.Close()
    }
    catch {
        # 当前日期没有文件，继续检查前一天
        continue
    }
}

# --------------------------------------------
# 60 天内没有找到暗链
# --------------------------------------------

if (-not $found) {

    Write-Host ""
    Write-Host "========================================"
    Write-Host "未能在过去 $maxDays 天内找到简体中文暗链。"
    Write-Host "========================================"
    Write-Host ""

    Write-Host "是否下载简体中文商业版？"
    Write-Host "下载地址:"
    Write-Host $commercial_url
    Write-Host ""

    $choice = Read-Host "输入 Y 下载，其他任意键退出"

    if ($choice -match '^[Yy]$') {

        $url = $commercial_url

        Write-Host ""
        Write-Host "已选择下载简体中文商业版。"
        Write-Host ""
    }
    else {

        Write-Host ""
        Write-Host "已取消下载。"
        exit 0
    }
}

# --------------------------------------------
# 设置下载路径
# --------------------------------------------

$desktopPath = [Environment]::GetFolderPath("Desktop")

$filename = Join-Path `
    $desktopPath `
    "winrar-x64-${version_nodot}-sc.exe"

Write-Host ""
Write-Host "正在下载 WinRAR..."
Write-Host "下载地址:"
Write-Host $url
Write-Host ""
Write-Host "保存位置:"
Write-Host $filename
Write-Host ""

# --------------------------------------------
# 正式下载
# --------------------------------------------

try {

    Invoke-WebRequest `
        -Uri $url `
        -OutFile $filename `
        -UseBasicParsing `
        -ErrorAction Stop

    # ----------------------------------------
    # 检查文件
    # ----------------------------------------

    if (-not (Test-Path $filename)) {

        Write-Host "下载请求完成，但没有找到下载文件。"
        exit 1
    }

    $fileInfo = Get-Item $filename

    Write-Host ""
    Write-Host "========================================"
    Write-Host "下载完成!"
    Write-Host "========================================"
    Write-Host "版本: $version"
    Write-Host "文件: $($fileInfo.FullName)"
    Write-Host "大小: $([math]::Round($fileInfo.Length / 1MB, 2)) MB"
    Write-Host "========================================"

}
catch {

    Write-Host ""
    Write-Host "下载失败:"
    Write-Host $_.Exception.Message

    exit 1
}
