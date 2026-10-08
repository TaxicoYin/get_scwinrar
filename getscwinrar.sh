#!/bin/bash

# ============================================
# WinRAR 简体中文正式版自动下载脚本
# ============================================

# 最新新闻页面
NEWS_URL="https://www.win-rar.com/latestnews.html?&L=0"

echo "正在获取 WinRAR 最新新闻..."

html=$(curl -fsSL --connect-timeout 10 --max-time 30 "$NEWS_URL")

if [[ $? -ne 0 || -z "$html" ]]; then
    echo "❌ 获取 WinRAR 新闻页面失败"
    exit 1
fi

release_date=""
version=""
version_nodot=""
latest_final_title=""

# ============================================
# 寻找最新 Final Release
# ============================================

echo "正在寻找最新 Final Release..."

while read -r line; do

    # ----------------------------------------
    # 提取日期
    # ----------------------------------------

    if [[ $line =~ ([0-9]{2})\.([0-9]{2})\.([0-9]{4}) ]]; then
        day="${BASH_REMATCH[1]}"
        month="${BASH_REMATCH[2]}"
        year="${BASH_REMATCH[3]}"

        release_date="${year}-${month}-${day}"
    fi

    # ----------------------------------------
    # 提取正式版
    #
    # Beta / Alpha / RC 等自动跳过
    # ----------------------------------------

    if [[ $line =~ WinRAR[[:space:]]+([0-9]+\.[0-9]+).*Final[[:space:]]+released ]]; then

        version="${BASH_REMATCH[1]}"
        version_nodot="${version//./}"

        latest_final_title=$(echo "$line" | sed -E 's/<[^>]+>//g' | xargs)

        break
    fi

done <<< "$(echo "$html" | grep -E 'news-list-date|WinRAR')"


# ============================================
# 检查是否找到正式版
# ============================================

if [[ -z "$release_date" || -z "$version" ]]; then
    echo ""
    echo "❌ 未找到正式版新闻或版本号"
    exit 1
fi


echo ""
echo "========================================"
echo "✅ 最新正式版本: $latest_final_title"
echo "🗓️ 发布日期: $release_date"
echo "✅ 最新正式版版本号: $version"
echo "========================================"
echo ""


# ============================================
# 简体中文商业版下载链接
# ============================================

commercial_url="https://www.win-rar.com/fileadmin/winrar-versions/partners/hua/winrar-x64-${version_nodot}sc.exe"

echo "📥 简体中文商业版下载链接:"
echo "$commercial_url"
echo ""


# ============================================
# 构造简体中文暗链
# ============================================

file_name="winrar-x64-${version_nodot}sc.exe"

found_url=""

echo "🔍 正在尝试构造并验证 WinRAR 简体中文下载暗链..."
echo ""


for i in $(seq 0 29); do

    test_date=$(date -d "$release_date -$i day" +%Y%m%d)

    test_url="https://www.win-rar.com/fileadmin/winrar-versions/sc/sc${test_date}/rrlb/${file_name}"

    echo "检查: $(date -d "$release_date -$i day" +%Y-%m-%d)"

    # ----------------------------------------
    # HEAD 检查
    #
    # 不下载文件，只检查 URL 是否存在
    # ----------------------------------------

    if curl -sSIL --connect-timeout 5 --max-time 5 \
        --fail "$test_url" >/dev/null 2>&1; then

        found_url="$test_url"

        echo ""
        echo "📥 找到简体中文暗链:"
        echo "$found_url"

        break
    fi

done


# ============================================
# 60 天没有找到暗链
# ============================================

if [[ -z "$found_url" ]]; then

    echo ""
    echo "========================================"
    echo "❌ 过去 30 天内没有找到简体中文暗链"
    echo "========================================"
    echo ""

    echo "是否下载简体中文商业版？"
    echo "下载地址:"
    echo "$commercial_url"
    echo ""

    read -r -p "输入 Y 下载，其他任意键退出: " choice

    if [[ "${choice,,}" == "y" ]]; then

        found_url="$commercial_url"

        echo ""
        echo "✅ 已选择下载简体中文商业版"
        echo ""

    else

        echo ""
        echo "已取消下载。"
        exit 0
    fi
fi


# ============================================
# 下载文件
# ============================================

echo "🧪 正在下载..."
echo "📥 下载地址: $found_url"
echo "💾 保存文件: $file_name"
echo ""


if curl -fL --progress-bar -o "$file_name" "$found_url"; then

    echo ""
    echo "========================================"
    echo "✅ 文件下载完成!"
    echo "========================================"
    echo "📦 版本: $version"
    echo "📄 文件: $file_name"

else

    echo ""
    echo "❌ 下载失败"
    exit 1
fi
