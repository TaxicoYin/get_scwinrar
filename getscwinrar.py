import requests
import re
from bs4 import BeautifulSoup
from datetime import datetime, timedelta

# 最新新闻页面
url = "https://www.win-rar.com/latestnews.html?&L=0"
resp = requests.get(url)
soup = BeautifulSoup(resp.text, "html.parser")

release_date = None
version = None
version_nodot = None
latest_final_title = None

# 遍历新闻条目
for item in soup.find_all("div", class_="news-list-item"):
    date_tag = item.find("span", class_="news-list-date")
    title_tag = item.find("h2").find("a") if item.find("h2") else None

    if not date_tag or not title_tag:
        continue

    title_text = title_tag.text.strip()
    if "Final released" not in title_text:  # 跳过 Beta
        continue

    # 日期
    date_match = re.search(r'(\d{2})\.(\d{2})\.(\d{4})', date_tag.text)
    if date_match:
        day, month, year = date_match.groups()
        release_date = f"{year}-{month}-{day}"

    # 版本号
    match = re.search(r'WinRAR\s+(\d+\.\d+)', title_text)
    if match:
        version = match.group(1)
        version_nodot = version.replace('.', '')
        latest_final_title = title_text
        break

if not release_date or not version:
    print("❌ 未找到正式版新闻或版本号")
    exit()

print(f"✅ 最新正式版本: {latest_final_title}")
print(f"🗓️ 发布日期: {release_date}")
print(f"✅ 最新正式版版本号: {version}")

# 商业版下载链接
full_url = f"https://www.win-rar.com/fileadmin/winrar-versions/partners/hua/winrar-x64-{version_nodot}sc.exe"
print(f"📥 商业版下载链接: {full_url}")

# 构造简体中文暗链
base_date = datetime.strptime(release_date, "%Y-%m-%d")
file_name = f"winrar-x64-{version_nodot}sc.exe"

print("🔍 正在尝试构造并验证 WinRAR 简体中文下载暗链...")
url = ""
for i in range(60):
    test_date = base_date - timedelta(days=i)
    date_str = test_date.strftime('%Y%m%d')
    url = f"https://www.win-rar.com/fileadmin/winrar-versions/sc/sc{date_str}/rrlb/{file_name}"

    try:
        r = requests.head(url, timeout=5)
        if r.status_code == 200:
            print(f"📥 获取到下载暗链: {url}")
            break
    except requests.RequestException as e:
        print(f"⚠️ 请求失败: {e}")

    if i == 59:
        print(f"❌ 获取简体中文暗链失败，过去60天内无版本发布")

# 下载文件
if url:
    print("🧪 正在尝试下载...")
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        with open(file_name, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
        print(f"✅ 文件已成功下载: {file_name}")
    except requests.RequestException as e:
        print(f"❌ 下载失败: {e}")
