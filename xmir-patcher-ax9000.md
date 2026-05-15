# AX9000 ShellCrash 完整攻略

> 原廠 ROM 1.0.140 stable → SSH 解鎖 → ShellCrash 安裝，科學上網完全指南

## 📖 總覽

| 項目 | 內容 |
|------|------|
| 設備 | 小米 AX9000（IPQ8072A）|
| 固件 | 原廠穩定版 1.0.140 |
| SSH 解鎖 | xmir-patcher connect5 |
| 代理工具 | ShellCrash (Clash Meta) |
| 是否刷機 | ❌ 原廠 ROM |
| 訂閱 | VLESS WebSocket TLS |

## 🔄 完整流程

```
1. 解鎖 SSH（xmir-patcher connect5）
       ↓
2. SSH 進入路由器，改密碼
       ↓
3. 安裝 ShellCrash
       ↓
4. 配置 VLESS 節點 + AI 分流規則
       ↓
5. 選擇模式（Redir HTTP 代理 或 TUN 透明代理）
       ↓
6. 驗證（ChatGPT / Claude API）
```

## 🔓 SSH 解鎖（xmir-patcher）

### Mac 安裝依賴
```bash
brew install cmake libssh2
```

### 下載並運行
```bash
cd /tmp
curl -sL "https://github.com/openwrt-xiaomi/xmir-patcher/archive/refs/heads/main.zip" -o xmir.zip
unzip -o xmir.zip && cd xmir-patcher-main
./venv/bin/python3 menu.py
```

### 選擇
- 選項 **2** — connect5（smartcontroller）
- 輸入密碼：**root** + Web 管理密碼

### 驗證
```bash
sshpass -p 'root' ssh -o StrictHostKeyChecking=no root@192.168.31.1 "uname -a"
```

## 🔐 SSH 進入並改密碼

```bash
# 第一次 SSH（舊密碼 root）
sshpass -p 'root' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1

# 改密碼
echo -e 'qwerty66\nqwerty66' | passwd root

# 之後用新密碼
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1
```

## 📦 安裝 ShellCrash

```bash
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 << 'ENDSSH'
mkdir -p /userdisk/shellcrash
cd /tmp
curl -kfsSL https://raw.githubusercontent.com/juewuy/ShellCrash/master/ShellCrash.tar.gz -o ShellCrash.tar.gz
tar -zxf ShellCrash.tar.gz -C /userdisk/shellcrash/
echo 'export CRASHDIR=/userdisk/shellcrash' >> /etc/profile
ENDSSH

# 啟動
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "/userdisk/shellcrash/start.sh"

# 驗證
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "ps | grep CrashCore"
```

## ⚙️ 配置節點 + 分流

### 完整配置（粘貼到 `/tmp/ShellCrash/config.yaml`）

```yaml
mixed-port: 7890
redir-port: 7892
tproxy-port: 7893
allow-lan: true
mode: rule
log-level: debug
ipv6: false
external-controller: :9999

dns:
  enable: true
  listen: :1053
  ipv6: false
  enhanced-mode: fake-ip
  fake-ip-range: 28.0.0.0/8
  nameserver: [ 223.5.5.5, 1.2.4.8, 127.0.0.1 ]
  fallback: [ 8.8.8.8, 1.1.1.1 ]
  fallback-filter:
    geoip: true
    geoip-code: CN

proxies:
  - name: hl13893j
    type: vless
    server: jp.xlin.eu.cc
    port: 443
    uuid: 9158ed39-7953-492f-80b7-531c5fa3ceeb
    network: ws
    tls: true
    sni: jp.xlin.eu.cc
    skip-cert-verify: false
    udp: true
    xudp: true
    ws-opts:
      path: "/"
      headers:
        Host: jp.xlin.eu.cc

proxy-groups:
  - name: 代理
    type: select
    proxies:
      - hl13893j

rules:
  # Anthropic
  - DOMAIN-SUFFIX,anthropic.com,代理
  - DOMAIN-SUFFIX,api.anthropic.com,代理
  - DOMAIN-SUFFIX,claude.ai,代理
  - DOMAIN-SUFFIX,platform.claude.ai,代理
  - DOMAIN-SUFFIX,code.claude.ai,代理
  # OpenAI
  - DOMAIN-SUFFIX,openai.com,代理
  - DOMAIN-SUFFIX,chatgpt.com,代理
  - DOMAIN-SUFFIX,api.openai.com,代理
  # Google AI
  - DOMAIN-SUFFIX,googleapis.com,代理
  - DOMAIN-SUFFIX,ai.google.dev,代理
  - DOMAIN-SUFFIX,makersuite.google.com,代理
  # 關鍵字
  - DOMAIN-KEYWORD,chatgpt,代理
  - DOMAIN-KEYWORD,claude,代理
  - DOMAIN-KEYWORD,anthropic,代理
  - DOMAIN-KEYWORD,openai,代理
  - DOMAIN-KEYWORD,google-ai,代理
  - DOMAIN-KEYWORD,gemini,代理
  # 默認
  - GEOIP,CN,DIRECT
  - MATCH,DIRECT
```

### 寫入配置
```bash
# 在 Mac 本地創建配置文件，然後 SSH 寫入
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "cat > /tmp/ShellCrash/config.yaml" < config.yaml

# 重啟代理
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1 "killall CrashCore; sleep 2; /tmp/ShellCrash/CrashCore -d /userdisk/shellcrash -f /tmp/ShellCrash/config.yaml &"
```

## 🌐 兩種代理模式

### 模式一：Redir（HTTP 代理）✅ 推薦

ShellCrash 自動配置 iptables，將 LAN 客戶端 TCP 443 流量轉發到 7892。

**Mac 設定 HTTP 代理：**
- 地址：`192.168.31.1`
- 端口：`7890`

```bash
# 驗證（在 Mac terminal）
curl -x http://192.168.31.1:7890 -s -w "\nHTTP: %{http_code}" \
  -H "x-api-key: dummy" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}' \
  'https://api.anthropic.com/v1/messages'
# 期望：HTTP 401 + authentication_error
```

### 模式二：TUN（透明代理）

接管所有流量，客戶端無需設定代理。

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

⚠️ **重要**：`routing-all: true` 在 AX9000 原廠固件會造成迴環，**唔建議使用**。

## ✅ 驗證

```bash
# 在 Mac terminal 執行
# ✅ ChatGPT
curl -x http://192.168.31.1:7890 -sL https://chatgpt.com -o /dev/null -w "HTTP: %{http_code}\n"

# ✅ Claude API
curl -x http://192.168.31.1:7890 -s -w "\nHTTP: %{http_code}" \
  -H "x-api-key: dummy" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-3-5-sonnet-20241022","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}' \
  'https://api.anthropic.com/v1/messages'

# ✅ OpenAI API
curl -x http://192.168.31.1:7890 -k -s -w "\nHTTP: %{http_code}" \
  -H "Authorization: Bearer dummy" \
  'https://api.openai.com/v1/models'
```

## 📡 管理命令

```bash
# SSH 進入路由器
sshpass -p 'qwerty66' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@192.168.31.1

# 查看進程
ps | grep CrashCore

# 查看 ShellCrash 日誌
tail -20 /tmp/ShellCrash/ShellCrash.log

# 查看 Clash 實時日誌
tail -f /tmp/ShellCrash/crashcore.log | grep -E 'DIRECT|代理'

# 重啟代理
killall CrashCore; sleep 2; /tmp/ShellCrash/CrashCore -d /userdisk/shellcrash -f /tmp/ShellCrash/config.yaml &

# Dashboard
open http://192.168.31.1:9999
```

## 🔑 關鍵信息

| 項目 | 值 |
|------|---|
| 路由器 IP | `192.168.31.1` |
| SSH 密碼 | `qwerty66` |
| ShellCrash 目錄 | `/userdisk/shellcrash` |
| 運行配置 | `/tmp/ShellCrash/config.yaml` |
| HTTP 代理 | `192.168.31.1:7890` |
| REDIR 端口 | `7892` |
| Dashboard | `http://192.168.31.1:9999` |
| TUN 設備 | `Meta`（28.0.0.0/30）|

## 📚 參考資源

- [GitHub Repo](https://github.com/whypuss/ax9000-shellcrash)
- [ShellCrash GitHub](https://github.com/juewuy/ShellCrash)
- [ShellCrash 常見問題](https://jwsc.eu.org/chang-jian-wen-ti/)
- [xmir-patcher](https://github.com/openwrt-xiaomi/xmir-patcher)
- [Clash Meta 文檔](https://github.com/MetaCubeX/mihomo)
