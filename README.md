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
echo -e 'qwerty66\nqwerty66' | passwd root

# 3. 下載並安裝 ShellCrash
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 << 'ENDSSH'
mkdir -p /userdisk/shellcrash
cd /tmp
curl -kfsSL https://raw.githubusercontent.com/juewuy/ShellCrash/master/ShellCrash.tar.gz -o ShellCrash.tar.gz
tar -zxf ShellCrash.tar.gz -C /userdisk/shellcrash/
echo 'export CRASHDIR=/userdisk/shellcrash' >> /etc/profile
echo 'alias crash=/userdisk/shellcrash/menu.sh' >> /etc/profile
ENDSSH

# 4. 啟動 ShellCrash（核心：meta）
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "/userdisk/shellcrash/start.sh"

# 5. 複製配置（見下方配置章節）
```

---

## 📋 完整流程圖

```
1. 解鎖 SSH（xmir-patcher connect5）
       ↓
2. SSH 進入路由器
       ↓
3. 安裝 ShellCrash
       ↓
4. 配置訂閱 / 節點
       ↓
5. 配置分流規則（AI 白名單）
       ↓
6. 選擇代理模式
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
echo -e 'qwerty66\nqwerty66' | passwd root

# 之後用新密碼登入
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1
```

---

## 📦 Step 3：安裝 ShellCrash

ShellCrash 係一個純 Shell 腳本，不需要 opkg，直接下載二進制核心。

```bash
# 建立目錄
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "mkdir -p /userdisk/shellcrash"

# 下載 ShellCrash
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 << 'ENDSSH'
cd /tmp
curl -kfsSL https://raw.githubusercontent.com/juewuy/ShellCrash/master/ShellCrash.tar.gz -o ShellCrash.tar.gz
tar -zxf ShellCrash.tar.gz -C /userdisk/shellcrash/
ENDSSH

# 配置環境變量
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "echo 'export CRASHDIR=/userdisk/shellcrash' >> /etc/profile"

# 啟動
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "/userdisk/shellcrash/start.sh"
```

### 驗證安裝
```bash
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "ps | grep CrashCore"
# 應看到類似：1232m S /tmp/ShellCrash/CrashCore
```

---

## 🌐 Step 4：配置訂閱 / 節點

### 方式一：在路由器上手動添加節點

```bash
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "/userdisk/shellcrash/menu.sh"
# 選擇：6 - 配置文件管理 → 1 - 添加節點 → 粘貼 VLESS URL
```

### 方式二：直接寫入配置（推薦）

```bash
# VLESS 節點信息
# 提供商：hl13893j
# 協議：VLESS + WebSocket + TLS
# 伺服器：jp.xlin.eu.cc:443
# UUID：9158ed39-7953-492f-80b7-531c5fa3ceeb
# Path：/

sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "cat > /tmp/ShellCrash/config.yaml" < config.yaml
```

### 方式三：訂閱 URL（在 ShellCrash 界面操作）
```
# 訂閱 URL（在 ShellCrash 界面粘貼）
https://cfnew.agooxo.workers.dev/bf25a7b8-1f52-4be9-93f5-623a878b37e9/sub
```

---

## 🔀 Step 5：配置分流規則

### 兩種模式

| 模式 | 原理 | 客戶端設置 |
|------|------|-----------|
| **Redir 模式**（推薦） | iptables 轉發 TCP 443 流量到代理 | Mac 需設定 HTTP 代理 `192.168.31.1:7890` |
| **TUN 模式** | 虛擬網卡接管所有流量 | 客戶端無需任何設置，自動代理 |

### 推薦：Redir 模式（簡單穩定）

客戶端設定 HTTP 代理：
- **地址**：`192.168.31.1`
- **端口**：`7890`
- Mac：WiFi → `i` → HTTP 代理 → 開啟 → 填寫

### TUN 模式（可選，全自動）

如果想要 Mac 完全自動代理（唔使設定代理）：

```yaml
# config.yaml 加入：
tun:
  enable: true
  stack: system
  auto-route: true
  dns-hijack:
    - 8.8.8.8:53
    - 1.1.1.1:53
  auto-detect-interface: true
```

⚠️ `routing-all: true` 在 AX9000 原廠固件上可能造成迴環，**唔建議使用**。

---

## ✅ 驗證代理是否正常

### 錯誤方式
- ❌ 用 IP 查詢網站（如 whatismyip.com.tw）— 返回嘅 IP 可能係 DNS 負載均衡結果
- ❌ Clash Dashboard `history: []` 空 — 短連接 HTTP 請求唔記入 history
- ❌ Cloudflare JS Challenge 頁面 — 唔係地區封鎖

### 正確方式
```bash
# 在 Mac Terminal 執行（需要設定 HTTP 代理或開啟 TUN）
# ✅ Anthropic API — 401 = 成功連接，只有 key 無效
curl -x http://192.168.31.1:7890 -s -w "\nHTTP: %{http_code}" \
  -X POST \
  -H "x-api-key: dummy" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}' \
  'https://api.anthropic.com/v1/messages'
# 期望：HTTP 401 + "authentication_error"

# ✅ OpenAI API
curl -x http://192.168.31.1:7890 -k -s -w "\nHTTP: %{http_code}" \
  -H "Authorization: Bearer dummy" \
  'https://api.openai.com/v1/models'
# 期望：HTTP 401 "Incorrect API key provided"

# ✅ ChatGPT 網頁
curl -x http://192.168.31.1:7890 -sL https://chatgpt.com -o /dev/null -w "HTTP: %{http_code}\n"
```

---

## 📡 管理命令

```bash
# 查看 CrashCore 進程
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "ps | grep CrashCore"

# 查看 ShellCrash 日誌
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "tail -20 /tmp/ShellCrash/ShellCrash.log"

# 查看 Clash 實時日誌（需要開啟 debug 模式）
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "cat /tmp/ShellCrash/crashcore.log | grep -E 'DIRECT|代理' | tail -10"

# Dashboard（瀏覽器打開）
open http://192.168.31.1:9999

# 重啟代理
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "killall CrashCore; sleep 2; /tmp/ShellCrash/CrashCore -d /userdisk/shellcrash -f /tmp/ShellCrash/config.yaml &"

# 測試 API 是否走代理（在 Mac terminal）
curl -x http://192.168.31.1:7890 -s https://api.anthropic.com -o /dev/null -w "HTTP: %{http_code}\n"
```

---

## 🔑 關鍵信息速查

| 項目 | 值 |
|------|---|
| 路由器 IP | `192.168.31.1` |
| SSH 密碼 | `qwerty66` |
| ShellCrash 目錄 | `/userdisk/shellcrash` |
| 運行配置 | `/tmp/ShellCrash/config.yaml` |
| HTTP 代理端口 | `7890` |
| REDIR 端口 | `7892` |
| Dashboard | `http://192.168.31.1:9999` |
| TUN 設備 | `Meta`（28.0.0.0/30） |
| 路由表 | `table 2022` |

---

## ❓ 常見問題

### Q: ShellCrash 提示核心不完整？
```bash
# 重新下載核心
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1
cd /tmp/ShellCrash
curl -kfsSL https://raw.githubusercontent.com/juewuy/ShellCrash/master/CrashCore.tar.gz -o CrashCore.tar.gz
tar -zxf CrashCore.tar.gz
```

### Q: TUN 模式造成迴環？
停用 `routing-all: true`，改用 Redir 模式 + HTTP 代理。

### Q: 訂閱更新後節點没了？
每次重啟路由器後，需重新拷貝配置：
```bash
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "cp /userdisk/shellcrash/yamls/config.yaml /tmp/ShellCrash/config.yaml; killall CrashCore; sleep 1; /tmp/ShellCrash/CrashCore -d /userdisk/shellcrash -f /tmp/ShellCrash/config.yaml &"
```

---

## 📚 參考資源

- [ShellCrash GitHub](https://github.com/juewuy/ShellCrash)
- [ShellCrash 常見問題](https://jwsc.eu.org/chang-jian-wen-ti/)
- [xmir-patcher](https://github.com/openwrt-xiaomi/xmir-patcher)
- [Clash Meta 文檔](https://github.com/MetaCubeX/mihomo)
