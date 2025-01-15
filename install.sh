#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 定义安装目录
INSTALL_DIR="/etc/vps-ip-bot"
REPO_URL="https://github.com/vvnocode/vps-change-ip"
BINARY_URL="$REPO_URL/releases/latest/download/vps-ip-bot"
CONFIG_URL="$REPO_URL/raw/main/config.yaml.example"
SPEEDTEST_INSTALL_URL="$REPO_URL/raw/main/install_speedtest.sh"

# 卸载函数
uninstall() {
    echo -e "${RED}=== VPS IP更换工具卸载 ===${NC}"
    
    # 停止并删除服务
    if [ -f "/etc/systemd/system/vps-ip-bot.service" ]; then
        echo "停止并删除服务..."
        systemctl stop vps-ip-bot
        systemctl disable vps-ip-bot
        rm -f /etc/systemd/system/vps-ip-bot.service
        systemctl daemon-reload
    fi
    
    # 询问是否删除配置文件
    echo -e "\n是否保留配置文件？"
    echo "1) 是 - 保留所有文件"
    echo "2) 否 - 删除所有文件"
    read -p "请选择 [1/2] (默认: 1): " keep_config
    keep_config=${keep_config:-1}
    
    case $keep_config in
        1)
            echo "保留配置文件..."
            rm -f "$INSTALL_DIR/vps-ip-bot"
            echo "仅删除了程序文件，配置文件保留在: $INSTALL_DIR"
            ;;
        2)
            echo "删除所有文件..."
            rm -rf "$INSTALL_DIR"
            echo "所有文件已删除"
            ;;
        *)
            echo "无效的选择，将默认保留配置文件"
            rm -f "$INSTALL_DIR/vps-ip-bot"
            ;;
    esac
    
    echo -e "${GREEN}卸载完成！${NC}"
    exit 0
}

# 安装函数
install() {
    echo -e "${GREEN}=== VPS IP更换工具安装 ===${NC}"
    
    # 下载并安装 speedtest-cli
    echo "下载并安装 speedtest-cli..."
    if ! curl -L -o "/tmp/install_speedtest.sh" "$SPEEDTEST_INSTALL_URL"; then
        echo -e "${RED}下载 speedtest 安装脚本失败${NC}"
        echo "继续安装其他组件..."
    else
        chmod +x "/tmp/install_speedtest.sh"
        if ! bash "/tmp/install_speedtest.sh"; then
            echo -e "${RED}安装 speedtest-cli 失败${NC}"
            echo "继续安装其他组件..."
        fi
        rm -f "/tmp/install_speedtest.sh"
    fi
    
    # 如果服务正在运行，先停止它
    if systemctl is-active --quiet vps-ip-bot; then
        echo "停止现有服务..."
        systemctl stop vps-ip-bot
    fi
    
    echo "创建工作目录..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/logs"
    
    echo "下载程序文件..."
    if ! curl -L -o "$INSTALL_DIR/vps-ip-bot" "$BINARY_URL"; then
        echo -e "${RED}下载程序文件失败${NC}"
        exit 1
    fi
    chmod +x "$INSTALL_DIR/vps-ip-bot"
    
    # 下载配置文件
    echo "下载配置文件..."
    if [ ! -f "$INSTALL_DIR/config.yaml" ]; then
        if ! curl -L -o "$INSTALL_DIR/config.yaml" "$CONFIG_URL"; then
            echo -e "${RED}下载配置文件失败${NC}"
            exit 1
        fi
    fi
    
    # 创建systemd服务
    cat > /etc/systemd/system/vps-ip-bot.service << EOF
[Unit]
Description=VPS IP Change Bot
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/vps-ip-bot
WorkingDirectory=$INSTALL_DIR
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    
    # 重载systemd
    systemctl daemon-reload
    
    # 配置向导
    echo -e "\n${GREEN}=== 配置信息 ===${NC}"
    read -p "是否现在配置Bot? (y/N): " configure_now
    if [[ "$configure_now" =~ ^[Yy]$ ]]; then
        read -p "请输入Telegram Bot Token: " bot_token
        read -p "请输入Telegram Chat ID, 多个用户ID用逗号分隔: " chat_id
        read -p "请输入IP更换API地址，idc提供。如果为空则无法使用更换IP功能: " ip_api
        
        # 更新配置文件
        sed -i "s|^telegram_bot_token:.*|telegram_bot_token: \"$bot_token\"|" "$INSTALL_DIR/config.yaml"
        sed -i "s|^telegram_chat_id:.*|telegram_chat_id: \"$chat_id\"|" "$INSTALL_DIR/config.yaml"
        sed -i "s|^ip_change_api:.*|ip_change_api: \"$ip_api\"|" "$INSTALL_DIR/config.yaml"
    fi
    
    # 启动服务
    echo "启动服务..."
    systemctl enable vps-ip-bot
    systemctl start vps-ip-bot
    
    echo -e "\n${GREEN}=== 安装完成! ===${NC}"
    echo "配置文件位置: $INSTALL_DIR/config.yaml"
    echo "日志文件位置: $INSTALL_DIR/logs/bot.log"
    echo "使用以下命令管理服务:"
    echo "systemctl start/stop/restart vps-ip-bot"
}

# 主程序
case "$1" in
    uninstall)
        uninstall
        ;;
    *)
        install
        ;;
esac 
# 重载systemd
systemctl daemon-reload 