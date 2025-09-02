import requests
import re
from datetime import datetime, timedelta
from bs4 import BeautifulSoup
# 目标页面
url = "https://www.win-rar.com/singlenewsview.html?&L=0"

# 获取页面内容
response = requests.get(url)
soup = BeautifulSoup(response.text, 'html.parser')

# 提取发布日期（格式转换为 YYYY-MM-DD）
release_date = None
date_tag = soup.find('div', class_='news-single-timedata')
if date_tag:
    date_match = re.search(r'(\d{2})\.(\d{2})\.(\d{4})', date_tag.text)
    if date_match:
        day, month, year = date_match.groups()
        release_date = f"{year}-{month}-{day}"
        print("🗓️ 发布日期:", release_date if release_date else "未找到发布日期")
    else:
       print("❌ 未获取到发布日期")
       exit
# 提取版本号数字
version = None
for h1 in soup.find_all('h1'):
    match = re.search(r'WinRAR\s+(\d+\.\d+)', h1.text)
    if match:
        version = match.group(1)
        version_nodot = version.replace('.', '')
        full_url = f"https://www.win-rar.com/fileadmin/winrar-versions/partners/hua/winrar-x64-{version_nodot}sc.exe"
        print(f"✅ 最新版本号: {version}")
        print(f"📥 商业版下载链接: {full_url}")
        break


base_date = datetime.strptime(release_date, "%Y-%m-%d")
file_name = f"winrar-x64-{version_nodot}sc.exe"

print("🔍 正在尝试构造并验证 WinRAR 简体中文下载暗链...")
url=""
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
#下载
print("🧪 正在尝试下载...")
try:
    response = requests.get(url, stream=True)
    response.raise_for_status()  # 如果状态码不是 200，会抛出异常

    with open(file_name, "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            if chunk:
                f.write(chunk)
    print(f"✅ 文件已成功下载: {file_name}")
except requests.RequestException as e:
    print(f"❌ 下载失败: {e}")
