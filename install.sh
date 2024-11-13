#!/bin/bash

echo "=== VPS IP更换工具安装 ==="

# 获取当前绝对路径
CURRENT_DIR=$(pwd)
INSTALL_DIR="$CURRENT_DIR/vps-change-ip"

# 创建工作目录
echo "创建工作目录: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR/logs"
cd "$INSTALL_DIR"

# 下载所需文件
echo "正在下载必要文件..."
curl -s https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/change_ip_common.sh -o change_ip_common.sh
curl -s https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/change_ip_check.sh -o change_ip_check.sh
curl -s https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/change_ip_scheduled.sh -o change_ip_scheduled.sh
curl -s https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/config.yaml -o config.yaml

# 设置脚本执行权限
chmod +x change_ip_*.sh

# 交互式配置
echo -e "\n=== 配置信息 ==="
read -p "请输入Telegram Bot Token: " telegram_bot_token
read -p "请输入Telegram Chat ID: " telegram_chat_id
read -p "请输入IP更换API地址: " ip_change_api

# 更新配置文件
sed -i "s|^cron_check_script: .*|cron_check_script: \"$INSTALL_DIR/change_ip_check.sh\"|" config.yaml
sed -i "s|^cron_change_script: .*|cron_change_script: \"$INSTALL_DIR/change_ip_scheduled.sh\"|" config.yaml
sed -i "s|^log_file: .*|log_file: \"$INSTALL_DIR/logs/change_ip.log\"|" config.yaml
sed -i "s/^telegram_bot_token: .*/telegram_bot_token: \"$telegram_bot_token\"/" config.yaml
sed -i "s/^telegram_chat_id: .*/telegram_chat_id: \"$telegram_chat_id\"/" config.yaml
sed -i "s/^ip_change_api: .*/ip_change_api: \"$ip_change_api\"/" config.yaml

# 配置 crontab
echo "正在配置定时任务..."
crontab -l > mycron
check_schedule=$(grep "^cron_check_schedule:" config.yaml | cut -d'"' -f2)
check_script=$(grep "^cron_check_script:" config.yaml | cut -d'"' -f2)
change_schedule=$(grep "^cron_change_schedule:" config.yaml | cut -d'"' -f2)
change_script=$(grep "^cron_change_script:" config.yaml | cut -d'"' -f2)

# 添加定时任务
echo "$check_schedule $check_script" >> mycron
echo "$change_schedule $change_script" >> mycron

# 安装新的crontab并清理临时文件
crontab mycron
rm mycron

echo -e "\n=== 安装完成！ ==="
echo "安装目录: $INSTALL_DIR"
echo "配置文件: $INSTALL_DIR/config.yaml"
echo "定时任务已配置完成"
echo "您可以通过编辑 config.yaml 文件修改配置" 