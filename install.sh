#!/bin/bash

echo "=== VPS IP更换工具安装 ==="

# 获取当前绝对路径
CURRENT_DIR=$(pwd)
INSTALL_DIR="/usr/local/vps-ip-bot"
CONFIG_DIR="/etc/vps-ip-bot"

# 创建必要目录
echo "创建工作目录..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR/logs"

# 下载二进制文件
echo "下载程序文件..."
BINARY_URL="https://github.com/your-repo/releases/latest/download/vps-ip-bot"
curl -L -o "$INSTALL_DIR/vps-ip-bot" "$BINARY_URL"
chmod +x "$INSTALL_DIR/vps-ip-bot"

# 下载配置文件模板
echo "下载配置文件..."
CONFIG_URL="https://raw.githubusercontent.com/your-repo/main/config.yaml.example" 
curl -L -o "$CONFIG_DIR/config.yaml.example" "$CONFIG_URL"

# 处理配置文件
if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    cp "$CONFIG_DIR/config.yaml.example" "$CONFIG_DIR/config.yaml"
fi

# 创建systemd服务
cat > /etc/systemd/system/vps-ip-bot.service << EOF
[Unit]
Description=VPS IP Change Bot
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/vps-ip-bot
WorkingDirectory=$CONFIG_DIR
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 重载systemd
systemctl daemon-reload

# 配置向导
echo -e "\n=== 配置信息 ==="
read -p "是否现在配置Bot? (y/N): " configure_now
if [[ "$configure_now" =~ ^[Yy]$ ]]; then
    read -p "请输入Telegram Bot Token: " bot_token
    read -p "请输入Telegram Chat ID: " chat_id
    read -p "请输入IP更换API地址: " ip_api
    
    # 更新配置文件
    sed -i "s|^telegram_bot_token:.*|telegram_bot_token: \"$bot_token\"|" "$CONFIG_DIR/config.yaml"
    sed -i "s|^telegram_chat_id:.*|telegram_chat_id: \"$chat_id\"|" "$CONFIG_DIR/config.yaml"
    sed -i "s|^ip_change_api:.*|ip_change_api: \"$ip_api\"|" "$CONFIG_DIR/config.yaml"
fi

# 启动服务
echo "启动服务..."
systemctl enable vps-ip-bot
systemctl start vps-ip-bot

echo -e "\n=== 安装完成! ==="
echo "配置文件位置: $CONFIG_DIR/config.yaml"
echo "日志文件位置: $CONFIG_DIR/logs/bot.log"
echo "使用以下命令管理服务:"
echo "systemctl start/stop/restart vps-ip-bot" 