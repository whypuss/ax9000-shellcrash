# AX9000 + ShellCrash 科學上網攻略

> **設備**：小米 AX9000（IPQ8072A）| **固件**：原廠穩定版 1.0.140 | **無需刷機**

---

## 🚀 快速開始（全部 SSH 命令）

```bash
# 1. 用 xmir-patcher 解鎖 SSH
brew install cmake libssh2
cd /tmp && curl -sL "https://github.com/openwrt-xiaomi/xmir-patcher/archive/refs/heads/main.zip" -o xmir.zip
unzip -o xmir.zip && cd xmir-patcher-main
./venv/bin/python3 menu.py
# 選項 2（connect5），密碼：root

# 2. SSH 連接並修改密碼
sshpass -p 'root' ssh -o StrictHostKeyChecking=no root@192.168.31.1
# 修改密碼（之後每次用新密碼）
echo -e 'YOUR_NEW_SSH_PASSWORD\nYOUR_NEW_SSH_PASSWORD' | passwd root

# 3. 下載並安裝 ShellCrash
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 << 'ENDSSH'
mkdir -p /userdisk/shellcrash
cd /tmp
curl -kfsSL https://raw.githubusercontent.com/juewuy/ShellCrash/master/ShellCrash.tar.gz -o ShellCrash.tar.gz
tar -zxf ShellCrash.tar.gz -C /userdisk/shellcrash/
echo 'export CRASHDIR=/userdisk/shellcrash' >> /etc/profile
echo 'alias crash=/userdisk/shellcrash/menu.sh' >> /etc/profile
ENDSSH

# 4. 啟動 ShellCrash（核心：meta）
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "/userdisk/shellcrash/start.sh"

# 5. 直接在路由器上生成配置文件（見下方）
```

---

## ⚠️ 重要：不要上傳 config 文件

**不要**把 config.yaml 上傳到路由器或任何地方！

正確做法：在路由器上用 SSH 命令直接生成配置文件，这样：
- 不會暴露你的節點信息
- 不會有磁盤空間問題
- 不依賴文件傳輸

---

## 📋 完整流程圖

```
1. 解鎖 SSH（xmir-patcher connect5）
       ↓
2. SSH 進入路由器
       ↓
3. 安裝 ShellCrash
       ↓
4. 直接在路由器上生成 config.yaml（不要上傳！）
       ↓
5. 啟動並驗證
```

---

## 🔓 Step 1：解鎖 SSH（xmir-patcher）

### 前置需求
- Mac（需要 cmake + libssh2）
- 路由器已連接到互聯網
- 路由器管理密碼（Web 登入密碼）

### 安裝依賴
```bash
brew install cmake libssh2
```

### 下載並運行 xmir-patcher
```bash
cd /tmp
curl -sL "https://github.com/openwrt-xiaomi/xmir-patcher/archive/refs/heads/main.zip" -o xmir.zip
unzip -o xmir.zip
cd xmir-patcher-main
./venv/bin/python3 menu.py
```

### 選擇 exploit
| Exploit | 模塊 | 適用固件 |
|---------|------|---------|
| 2 | connect5 (smartcontroller) | ✅ 原廠 1.0.140 stable |
| 3 | connect6 (arn_switch) | ❌ |

### 輸入密碼
- `root`（預設 SSH 密碼）
- Web 管理密碼（你的路由器後台登入密碼）

### 驗證 SSH 已解鎖
```bash
sshpass -p 'root' ssh -o StrictHostKeyChecking=no root@192.168.31.1 "uname -a"
```

---

## 🔧 Step 2：SSH 進入並修改密碼

```bash
sshpass -p 'root' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1

# 修改 root 密碼
echo -e 'YOUR_NEW_SSH_PASSWORD\nYOUR_NEW_SSH_PASSWORD' | passwd root

# 之後用新密碼登入
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1
```

---

## 📦 Step 3：安裝 ShellCrash

ShellCrash 係一個純 Shell 腳本，不需要 opkg，直接下載二進制核心。

```bash
# 建立目錄
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "mkdir -p /userdisk/shellcrash"

# 下載 ShellCrash
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 << 'ENDSSH'
cd /tmp
curl -kfsSL https://raw.githubusercontent.com/juewuy/ShellCrash/master/ShellCrash.tar.gz -o ShellCrash.tar.gz
tar -zxf ShellCrash.tar.gz -C /userdisk/shellcrash/
ENDSSH

# 配置環境變量
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "echo 'export CRASHDIR=/userdisk/shellcrash' >> /etc/profile"

# 啟動
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "/userdisk/shellcrash/start.sh"
```

### 驗證安裝
```bash
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "ps | grep CrashCore"
# 應看到類似：1232m S /tmp/ShellCrash/CrashCore
```

---

## ⚙️ Step 4：直接在路由器上生成配置文件

**不要上傳任何 config 文件！** 直接 SSH 進入路由器，粘貼以下命令並替換 `YOUR_VLESS_URL` 為你的節點：

```bash
# SSH 進入路由器
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1
```

### 方式一：粘貼 VLESS URL（推薦）

在 SSH 會話中粘貼：
```bash
# 啟動 ShellCrash 菜單
/userdisk/shellcrash/menu.sh
```
選擇：`6 - 配置文件管理` → `1 - 添加節點` → 粘貼你的 VLESS URL

### 方式二：完全用命令生成（無需交互）

把你的 VLESS URL 代入以下命令（把 `YOUR_VLESS_URL` 換成你的）：

```bash
# 提取 URL 中的關鍵信息
VLESS_URL="YOUR_VLESS_URL"
UUID=$(echo "$VLESS_URL" | grep -oP '(?<=@)[^@]+' | cut -d: -f1)
SERVER=$(echo "$VLESS_URL" | grep -oP '(?<=@)[^:]+')
PORT=$(echo "$VLESS_URL" | grep -oP '(?<=:)\d+(?=/)')
PATH=$(echo "$VLESS_URL" | grep -oP '(?<==)[^&]+(?=&|$)')
NAME="proxy"

# 生成 config.yaml
cat > /tmp/ShellCrash/config.yaml << EOF
mixed-port: 7890
redir-port: 7892
allow-lan: true
mode: rule
log-level: debug
ipv6: false
external-controller: :9999
unified-delay: true

dns:
  enable: true
  listen: :1053
  ipv6: false
  enhanced-mode: fake-ip
  fake-ip-range: 28.0.0.0/8
  nameserver: [223.5.5.5, 1.2.4.8]
  fallback: [8.8.8.8, 1.1.1.1]
  fallback-filter:
    geoip: true
    geoip-code: CN

proxies:
  - name: $NAME
    type: vless
    server: $SERVER
    port: $PORT
    uuid: $UUID
    network: ws
    tls: true
    sni: $SERVER
    skip-cert-verify: false
    udp: true
    xudp: true
    ws-opts:
      path: "/"
      headers:
        Host: $SERVER

proxy-groups:
  - name: proxy
    type: select
    proxies: [$NAME]

rules:
  - DOMAIN-SUFFIX,anthropic.com,proxy
  - DOMAIN-SUFFIX,api.anthropic.com,proxy
  - DOMAIN-SUFFIX,claude.ai,proxy
  - DOMAIN-SUFFIX,platform.claude.ai,proxy
  - DOMAIN-SUFFIX,code.claude.ai,proxy
  - DOMAIN-SUFFIX,openai.com,proxy
  - DOMAIN-SUFFIX,chatgpt.com,proxy
  - DOMAIN-SUFFIX,api.openai.com,proxy
  - DOMAIN-SUFFIX,openaicom.imgix.net,proxy
  - DOMAIN-SUFFIX,googleapis.com,proxy
  - DOMAIN-SUFFIX,ai.google.dev,proxy
  - DOMAIN-SUFFIX,makersuite.google.com,proxy
  - DOMAIN-SUFFIX,aistudio.google.com,proxy
  - DOMAIN-KEYWORD,chatgpt,proxy
  - DOMAIN-KEYWORD,claude,proxy
  - DOMAIN-KEYWORD,anthropic,proxy
  - DOMAIN-KEYWORD,openai,proxy
  - DOMAIN-KEYWORD,google-ai,proxy
  - DOMAIN-KEYWORD,gemini,proxy
  - DOMAIN-SUFFIX,ip.sb,proxy
  - DOMAIN-SUFFIX,ipinfo.io,proxy
  - GEOIP,CN,DIRECT
  - MATCH,DIRECT
EOF

# 驗證配置
/userdisk/shellcrash/CrashCore -t -f /tmp/ShellCrash/config.yaml
```

---

## 🚀 Step 5：啟動並驗證

```bash
# 啟動 CrashCore
killall CrashCore 2>/dev/null
/userdisk/shellcrash/CrashCore -d /userdisk/shellcrash -f /tmp/ShellCrash/config.yaml > /tmp/crash.log 2>&1 &

# 等待啟動
sleep 3

# 驗證進程
ps | grep CrashCore | grep -v grep

# 驗證端口
netstat -lnp | grep -E '7890|9999'
```

### 驗證代理是否正常

在你的 Mac Terminal 執行：
```bash
# 測試 IP 檢測（需要設定 HTTP 代理或開啟 TUN）
curl -x http://192.168.31.1:7890 -s https://ipinfo.io/json
# 期望：返回你的代理伺服器 IP（不是你本地 ISP IP）

# 測試 Anthropic API
curl -x http://192.168.31.1:7890 -s -w "\nHTTP: %{http_code}" \
  -X POST \
  -H "x-api-key: dummy" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}' \
  'https://api.anthropic.com/v1/messages'
# 期望：HTTP 401 + "authentication_error"（不是 000 或 timeout）
```

---

## 🔀 代理模式：Redir vs TUN

| 模式 | 原理 | 客戶端設置 |
|------|------|-----------|
| **Redir 模式**（推薦） | iptables 轉發流量到代理 | Mac 需設定 HTTP 代理 `192.168.31.1:7890` |
| **TUN 模式** | 虛擬網卡接管所有流量 | 客戶端無需任何設置，自動代理 |

### Redir 模式設定（推薦，穩定）

Mac：WiFi → `i` → HTTP 代理 → 開啟 → 填寫
- **地址**：`192.168.31.1`
- **端口**：`7890`

### TUN 模式（可選，全自動）

⚠️ `routing-all: true` 在 AX9000 原廠固件可能造成迴環，**唔建議使用**。

如需開啟 TUN，在 config.yaml 加入：
```yaml
tun:
  enable: true
  stack: system
  auto-route: true
  dns-hijack:
    - 8.8.8.8:53
    - 1.1.1.1:53
  auto-detect-interface: true
```

---

## 📡 管理命令

```bash
# 查看 CrashCore 進程
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "ps | grep CrashCore"

# 查看 ShellCrash 日誌
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "tail -20 /tmp/crash.log"

# Dashboard（瀏覽器打開）
open http://192.168.31.1:9999

# 重啟代理
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "killall CrashCore; sleep 2; /userdisk/shellcrash/CrashCore -d /userdisk/shellcrash -f /tmp/ShellCrash/config.yaml > /tmp/crash.log 2>&1 &"
```

---

## 🔑 關鍵信息速查

| 項目 | 值 |
|------|---|
| 路由器 IP | `192.168.31.1` |
| SSH 密碼 | `YOUR_NEW_SSH_PASSWORD` |
| ShellCrash 目錄 | `/userdisk/shellcrash` |
| 運行配置 | `/tmp/ShellCrash/config.yaml` |
| HTTP 代理端口 | `7890` |
| REDIR 端口 | `7892` |
| Dashboard | `http://192.168.31.1:9999` |

---

## ❓ 常見問題

### Q: 磁盤空間不足？
/userdisk 分區只有 42MB，空間有限。config.yaml 存在 `/tmp`（tmpfs，350MB 空閒，重啟後丢失）。

### Q: 重啟路由器後配置丢失？
是的，因為配置存在 `/tmp`。每次重啟後需要重新生成配置：
```bash
# 重新生成並啟動
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 \
  "/userdisk/shellcrash/CrashCore -d /userdisk/shellcrash -f /tmp/ShellCrash/config.yaml > /tmp/crash.log 2>&1 &"
```

### Q: ShellCrash 提示核心不完整？
```bash
sshpass -p 'YOUR_NEW_SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 << 'ENDSSH'
cd /tmp
curl -kfsSL https://raw.githubusercontent.com/juewuy/ShellCrash/master/CrashCore.tar.gz -o CrashCore.tar.gz
tar -zxf CrashCore.tar.gz -C /userdisk/shellcrash/
ENDSSH
```

### Q: TUN 模式造成迴環？
停用 `routing-all: true`，改用 Redir 模式 + HTTP 代理。

---

## 📚 參考資源

- [ShellCrash GitHub](https://github.com/juewuy/ShellCrash)
- [ShellCrash 常見問題](https://jwsc.eu.org/chang-jian-wen-ti/)
- [xmir-patcher](https://github.com/openwrt-xiaomi/xmir-patcher)
- [Clash Meta 文檔](https://github.com/MetaCubeX/mihomo)
