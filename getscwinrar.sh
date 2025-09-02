#!/bin/bash

# 目标页面
URL="https://www.win-rar.com/singlenewsview.html?&L=0"

# 获取页面内容
HTML=$(curl -s "$URL")

# 提取版本号（如 WinRAR 6.23）
version=$(echo "$HTML" | grep -oP 'WinRAR\s+\K\d+(\.\d+)+' | head -n 1)
# 提取发布日期（如 30.08.2025 → 2025-08-30）
RAW_DATE=$(echo "$HTML" | grep 'news-single-timedata' | grep -oP '\d{2}\.\d{2}\.\d{4}')
RELEASE_DATE=$(echo "$RAW_DATE" | sed -E 's#([0-9]{2})\.([0-9]{2})\.([0-9]{4})#\3-\2-\1#')


# 输出结果
echo "🗓️ 发布日期: ${RELEASE_DATE:-未找到发布日期}"
echo "✅ 最新版本号: $version"

# 构造下载地址
version_nodot=$(echo "$version" | tr -d '.')
download_url="https://www.win-rar.com/fileadmin/winrar-versions/partners/hua/winrar-x64-${version_nodot}sc.exe"
echo "🔗 下载地址: $download_url"

# Step 2: 提取版本号和下载链接
echo "🔍 正在尝试构造并验证 WinRAR 简体中文下载暗链..."

# 设置起始日期（今天）
start_date=$(echo "$RELEASE_DATE" | sed 's/-//g')

# 最大尝试天数（向前回溯）
max_days=60
found=0
for ((i=0; i<max_days; i++)); do
    try_date=$(date -d "$start_date - $i days" +%Y%m%d)
    url="https://www.win-rar.com/fileadmin/winrar-versions/sc/sc${try_date}/rrlb/winrar-x64-${version_nodot}sc.exe"

    # 检查链接是否存在
    if curl --head --silent --fail "$url" > /dev/null; then
        echo "✅ 找到暗链下载地址:"
        echo "$url"
         found=1
        break;
    fi
done
if [ "$found" -eq 0 ]; then
    echo "❌ 未能在过去 $max_days 天内找到匹配的暗链地址。可能尚未发布商业版或路径已变动。"
    exit 1
fi

# Step 3: 下载
echo "🧪 正在尝试下载"
filename="winrar-x64-${version_nodot}-sc.exe"
curl -L "$url" -o "$filename"
if [ $? -eq 0 ]; then
    echo "✔️ 下载完成"
else
    echo "❌ 下载失败"
fi

# 可选：清理安装包
#rm -f "$filename"
#echo "✅ 安装完成"
