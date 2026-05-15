#!/bin/bash
#===============================================================================
# AX9000 ShellCrash 一鍵安裝腳本
# 用途：在小米 AX9000 原廠固件上安裝 ShellCrash + 配置 VLESS 節點
# 作者：agooxo
#===============================================================================

set -e

# 顏色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 參數
ROUTER_IP="${ROUTER_IP:-192.168.31.1}"
SSH_PASS="${SSH_PASS:-root}"           # 初始 SSH 密碼（解鎖後）
NEW_PASS="${NEW_PASS:-YOUR_NEW_SSH_PASSWORD}"       # 新 SSH 密碼
CRASHDIR="${CRASHDIR:-/userdisk/shellcrash}"

echo -e "${GREEN}=== AX9000 ShellCrash 安裝腳本 ===${NC}"
echo "路由器: $ROUTER_IP"
echo "ShellCrash 目錄: $CRASHDIR"

#-------------------------------------------------------------------------------
# 檢查依賴
#-------------------------------------------------------------------------------
check_deps() {
    echo -e "\n${YELLOW}[1/6] 檢查依賴...${NC}"
    for cmd in sshpass curl; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}缺少 $cmd，請先安裝：brew install $cmd${NC}"
            exit 1
        fi
    done
    echo -e "${GREEN}依賴檢查通過${NC}"
}

#-------------------------------------------------------------------------------
# 解鎖 SSH（xmir-patcher）
#-------------------------------------------------------------------------------
unlock_ssh() {
    echo -e "\n${YELLOW}[2/6] 解鎖 SSH...${NC}"
    echo -e "${RED}請手動運行以下命令來解鎖 SSH：${NC}"
    echo ""
    echo "  cd /tmp"
    echo "  curl -sL 'https://github.com/openwrt-xiaomi/xmir-patcher/archive/refs/heads/main.zip' -o xmir.zip"
    echo "  unzip -o xmir.zip && cd xmir-patcher-main"
    echo "  ./venv/bin/python3 menu.py"
    echo ""
    echo "選擇選項 2 (connect5)，輸入密碼: root"
    echo ""
    read -p "解鎖完成後按 Enter 繼續..."
}

#-------------------------------------------------------------------------------
# 測試 SSH 連接
#-------------------------------------------------------------------------------
test_ssh() {
    echo -e "\n${YELLOW}[3/6] 測試 SSH 連接...${NC}"
    if sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@"$ROUTER_IP" "echo ok" 2>/dev/null | grep -q ok; then
        echo -e "${GREEN}SSH 連接成功${NC}"
    else
        echo -e "${RED}SSH 連接失敗，請確認 SSH 已解鎖${NC}"
        exit 1
    fi
}

#-------------------------------------------------------------------------------
# 安裝 ShellCrash
#-------------------------------------------------------------------------------
install_shellcrash() {
    echo -e "\n${YELLOW}[4/6] 安裝 ShellCrash...${NC}"

    # SSH 命令
    SSH_CMD="sshpass -p '$SSH_PASS' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@$ROUTER_IP"

    # 建立目錄
    eval "$SSH_CMD" "mkdir -p $CRASHDIR"

    # 下載 ShellCrash
    echo "下載 ShellCrash..."
    eval "$SSH_CMD" "cd /tmp && curl -kfsSL https://raw.githubusercontent.com/juewuy/ShellCrash/master/ShellCrash.tar.gz -o ShellCrash.tar.gz && tar -zxf ShellCrash.tar.gz -C $CRASHDIR/"

    # 配置環境變量
    eval "$SSH_CMD" "echo 'export CRASHDIR=$CRASHDIR' >> /etc/profile"
    eval "$SSH_CMD" "echo 'alias crash=$CRASHDIR/menu.sh' >> /etc/profile"

    echo -e "${GREEN}ShellCrash 安裝完成${NC}"
}

#-------------------------------------------------------------------------------
# 配置節點
#-------------------------------------------------------------------------------
config_node() {
    echo -e "\n${YELLOW}[5/6] 配置節點...${NC}"
    echo ""
    echo "請選擇配置方式："
    echo "  1) 粘貼 VLESS URL（推薦）"
    echo "  2) 使用訂閱 URL"
    echo "  3) 手動編輯 config.yaml"
    read -p "選擇 [1-3]: " choice

    case $choice in
        1)
            echo "請粘貼 VLESS URL（格式：vless://...）:"
            read -r VLESS_URL
            echo -e "${YELLOW}節點配置完成，請手動在 ShellCrash 界面添加節點${NC}"
            ;;
        2)
            echo "請粘貼訂閱 URL:"
            read -r SUB_URL
            echo -e "${YELLOW}訂閱配置完成，請手動在 ShellCrash 界面添加訂閱${NC}"
            ;;
        3)
            echo -e "${YELLOW}請編輯 config.yaml.example 並上傳到 /tmp/ShellCrash/config.yaml${NC}"
            ;;
    esac
}

#-------------------------------------------------------------------------------
# 啟動並驗證
#-------------------------------------------------------------------------------
start_and_verify() {
    echo -e "\n${YELLOW}[6/6] 啟動並驗證...${NC}"

    SSH_CMD="sshpass -p '$SSH_PASS' ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=+ssh-rsa root@$ROUTER_IP"

    # 啟動
    eval "$SSH_CMD" "$CRASHDIR/start.sh"

    # 等待啟動
    sleep 3

    # 檢查進程
    if eval "$SSH_CMD" "ps | grep CrashCore | grep -v grep" | grep -q CrashCore; then
        echo -e "${GREEN}ShellCrash 啟動成功！${NC}"
    else
        echo -e "${RED}ShellCrash 啟動失敗，請檢查日誌${NC}"
    fi

    echo ""
    echo -e "${GREEN}=== 安裝完成 ===${NC}"
    echo ""
    echo "Dashboard: http://$ROUTER_IP:9999"
    echo "HTTP 代理: $ROUTER_IP:7890"
    echo ""
    echo "如使用 Redir 模式，請在客戶端設定 HTTP 代理"
    echo "如使用 TUN 模式，請在 config.yaml 開啟 TUN 設置"
}

#-------------------------------------------------------------------------------
# 主流程
#-------------------------------------------------------------------------------
check_deps
unlock_ssh
test_ssh
install_shellcrash
config_node
start_and_verify
