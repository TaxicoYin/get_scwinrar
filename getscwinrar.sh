#!/bin/bash

# 最新新闻页面
url="https://www.win-rar.com/latestnews.html?&L=0"
html=$(curl -s "$url")

release_date=""
version=""
version_nodot=""
latest_final_title=""

# 提取新闻条目
while read -r line; do
    # 提取日期
    if [[ $line =~ ([0-9]{2})\.([0-9]{2})\.([0-9]{4}) ]]; then
        day=${BASH_REMATCH[1]}
        month=${BASH_REMATCH[2]}
        year=${BASH_REMATCH[3]}
        release_date="${year}-${month}-${day}"
    fi

    # 提取版本号
    if [[ $line =~ WinRAR[[:space:]]([0-9]+\.[0-9]+).*Final\ released ]]; then
        version="${BASH_REMATCH[1]}"
        version_nodot="${version//./}"
        latest_final_title=$(echo "$line" | sed -E 's/<[^>]+>//g' | xargs)
        break
    fi
done <<< "$(echo "$html" | grep -E 'news-list-date|WinRAR')"

if [[ -z $release_date || -z $version ]]; then
    echo "❌ 未找到正式版新闻或版本号"
    exit 1
fi

echo "✅ 最新正式版本: $latest_final_title"
echo "🗓️ 发布日期: $release_date"
echo "✅ 最新正式版版本号: $version"

# 商业版下载链接
full_url="https://www.win-rar.com/fileadmin/winrar-versions/partners/hua/winrar-x64-${version_nodot}sc.exe"
echo "📥 商业版下载链接: $full_url"

# 构造简体中文暗链
base_date=$(date -d "$release_date" +%Y%m%d)
file_name="winrar-x64-${version_nodot}sc.exe"

echo "🔍 正在尝试构造并验证 WinRAR 简体中文下载暗链..."
url=""
for i in $(seq 0 59); do
    test_date=$(date -d "$release_date -$i day" +%Y%m%d)
    test_url="https://www.win-rar.com/fileadmin/winrar-versions/sc/sc${test_date}/rrlb/${file_name}"

    if curl -s --head --fail "$test_url" >/dev/null; then
        url="$test_url"
        echo "📥 获取到下载暗链: $url"
        break
    fi

    if [[ $i -eq 59 ]]; then
        echo "❌ 获取简体中文暗链失败，过去60天内无版本发布"
    fi
done

# 下载文件
if [[ -n $url ]]; then
    echo "🧪 正在尝试下载..."
    if curl -fLo "$file_name" "$url"; then
        echo "✅ 文件已成功下载: $file_name"
    else
        echo "❌ 下载失败"
    fi
fi
