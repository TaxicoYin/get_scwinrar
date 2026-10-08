import requests
import re
from bs4 import BeautifulSoup
from datetime import datetime, timedelta

# ============================================
# WinRAR 简体中文正式版自动下载脚本
# ============================================

# 最新新闻页面
NEWS_URL = "https://www.win-rar.com/latestnews.html?&L=0"

# ============================================
# 获取 WinRAR 最新新闻
# ============================================

print("正在获取 WinRAR 最新新闻...")

try:
    resp = requests.get(
        NEWS_URL,
        timeout=10
    )
    resp.raise_for_status()

except requests.RequestException as e:
    print(f"❌ 获取 WinRAR 新闻页面失败: {e}")
    exit(1)

soup = BeautifulSoup(resp.text, "html.parser")

release_date = None
version = None
version_nodot = None
latest_final_title = None

# ============================================
# 寻找最新 Final Release
# ============================================

print("正在寻找最新 Final Release...")

for item in soup.find_all("div", class_="news-list-item"):

    date_tag = item.find(
        "span",
        class_="news-list-date"
    )

    title_tag = (
        item.find("h2").find("a")
        if item.find("h2")
        else None
    )

    if not date_tag or not title_tag:
        continue

    title_text = title_tag.get_text(
        " ",
        strip=True
    )

    print(f"检查新闻: {title_text}")

    # ----------------------------------------
    # 只匹配正式版
    #
    # Beta / Alpha / RC 等自动跳过
    # ----------------------------------------

    if not re.search(
        r"\bFinal released\b",
        title_text,
        re.IGNORECASE
    ):
        continue

    # ----------------------------------------
    # 提取日期
    # ----------------------------------------

    date_match = re.search(
        r"(\d{2})\.(\d{2})\.(\d{4})",
        date_tag.get_text()
    )

    if not date_match:
        continue

    day, month, year = date_match.groups()

    release_date = f"{year}-{month}-{day}"

    # ----------------------------------------
    # 提取版本号
    # ----------------------------------------

    version_match = re.search(
        r"WinRAR\s+(\d+\.\d+)",
        title_text,
        re.IGNORECASE
    )

    if not version_match:
        continue

    version = version_match.group(1)

    # 7.23 -> 723
    version_nodot = version.replace(".", "")

    latest_final_title = title_text

    break


# ============================================
# 检查是否找到正式版
# ============================================

if not release_date or not version:

    print("")
    print("❌ 未找到正式版新闻或版本号")
    exit(1)


print("")
print("========================================")
print(f"✅ 最新正式版本: {latest_final_title}")
print(f"🗓️ 发布日期: {release_date}")
print(f"✅ 最新正式版版本号: {version}")
print("========================================")
print("")


# ============================================
# 简体中文商业版下载链接
# ============================================

commercial_url = (
    "https://www.win-rar.com/"
    f"fileadmin/winrar-versions/partners/hua/"
    f"winrar-x64-{version_nodot}sc.exe"
)

print("📥 简体中文商业版下载链接:")
print(commercial_url)
print("")


# ============================================
# 构造简体中文暗链
# ============================================

base_date = datetime.strptime(
    release_date,
    "%Y-%m-%d"
)

file_name = (
    f"winrar-x64-{version_nodot}sc.exe"
)

found_url = None

print("🔍 正在尝试构造并验证 WinRAR 简体中文下载暗链...")
print("")


for i in range(30):

    test_date = base_date - timedelta(days=i)

    date_str = test_date.strftime("%Y%m%d")

    test_url = (
        "https://www.win-rar.com/"
        f"fileadmin/winrar-versions/sc/"
        f"sc{date_str}/rrlb/{file_name}"
    )

    print(
        f"检查: {test_date.strftime('%Y-%m-%d')}"
    )

    # ----------------------------------------
    # 使用 HEAD 检查
    #
    # 不下载文件，只检查 URL 是否存在
    # ----------------------------------------

    try:

        r = requests.head(
            test_url,
            timeout=5,
            allow_redirects=True
        )

        if 200 <= r.status_code < 400:

            found_url = test_url

            print("")
            print("📥 找到简体中文暗链:")
            print(found_url)

            break

    except requests.RequestException:
        pass


# ============================================
# 60 天没有找到暗链
# ============================================

if not found_url:

    print("")
    print("========================================")
    print("❌ 过去 30 天内没有找到简体中文暗链")
    print("========================================")
    print("")

    print("是否下载简体中文商业版？")
    print("下载地址:")
    print(commercial_url)
    print("")

    choice = input(
        "输入 Y 下载，其他任意键退出: "
    ).strip()

    if choice.lower() == "y":

        found_url = commercial_url

        print("")
        print("✅ 已选择下载简体中文商业版")
        print("")

    else:

        print("")
        print("已取消下载。")
        exit(0)


# ============================================
# 下载文件
# ============================================

print("🧪 正在下载...")
print(f"📥 下载地址: {found_url}")
print(f"💾 保存文件: {file_name}")
print("")


try:

    response = requests.get(
        found_url,
        stream=True,
        timeout=30
    )

    response.raise_for_status()

    # ----------------------------------------
    # 写入文件
    # ----------------------------------------

    with open(file_name, "wb") as f:

        for chunk in response.iter_content(
            chunk_size=8192
        ):

            if chunk:
                f.write(chunk)

    print("")
    print("========================================")
    print("✅ 文件下载完成!")
    print("========================================")
    print(f"📦 版本: {version}")
    print(f"📄 文件: {file_name}")

except requests.RequestException as e:

    print("")
    print("❌ 下载失败:")
    print(e)

    exit(1)
