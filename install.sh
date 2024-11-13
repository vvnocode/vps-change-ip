#!/bin/bash

echo "=== VPS IP更换工具安装 ==="

# 获取当前绝对路径
CURRENT_DIR=$(pwd)
INSTALL_DIR="$CURRENT_DIR/vps-change-ip"

# 创建工作目录
echo "创建工作目录: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR/logs"
cd "$INSTALL_DIR"

# 下载文件函数
download_file() {
    local url=$1
    local output=$2
    if ! curl -s "$url" -o "$output"; then
        echo "下载 $output 失败"
        return 1
    fi
    if [ ! -f "$output" ]; then
        echo "$output 文件不存在"
        return 1
    fi
    echo "下载 $output 成功"
    return 0
}

# 下载所需文件
echo "正在下载必要文件..."
download_file "https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/change_ip_common.sh" "change_ip_common.sh" || exit 1
download_file "https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/change_ip_check.sh" "change_ip_check.sh" || exit 1
download_file "https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/change_ip_scheduled.sh" "change_ip_scheduled.sh" || exit 1
download_file "https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/config.yaml.example" "config.yaml" || exit 1

# 设置脚本执行权限
chmod +x change_ip_*.sh

# 交互式配置
echo -e "\n=== 配置信息 ==="
read -p "请输入Telegram Bot Token: " telegram_bot_token
read -p "请输入Telegram Chat ID: " telegram_chat_id
read -p "请输入IP更换API地址: " ip_change_api

# 验证输入不为空
if [ -z "$telegram_bot_token" ] || [ -z "$telegram_chat_id" ] || [ -z "$ip_change_api" ]; then
    echo "错误：配置信息不能为空"
    exit 1
fi

# 在更新配置之前添加检查
if [ ! -f "config.yaml" ]; then
    echo "错误：找不到配置文件 config.yaml"
    exit 1
fi

# 确保文件可写
if [ ! -w "config.yaml" ]; then
    echo "错误：配置文件没有写入权限"
    exit 1
fi

# 更新配置文件
echo "更新配置文件..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|^cron_check_script: .*|cron_check_script: \"$INSTALL_DIR/change_ip_check.sh\"|" config.yaml
    sed -i '' "s|^cron_change_script: .*|cron_change_script: \"$INSTALL_DIR/change_ip_scheduled.sh\"|" config.yaml
    sed -i '' "s|^log_file: .*|log_file: \"$INSTALL_DIR/logs/change_ip.log\"|" config.yaml
    sed -i '' "s|^telegram_bot_token: .*|telegram_bot_token: \"$telegram_bot_token\"|" config.yaml
    sed -i '' "s|^telegram_chat_id: .*|telegram_chat_id: \"$telegram_chat_id\"|" config.yaml
    sed -i '' "s|^ip_change_api: .*|ip_change_api: \"$ip_change_api\"|" config.yaml
else
    # Linux
    sed -i "s|^cron_check_script: .*|cron_check_script: \"$INSTALL_DIR/change_ip_check.sh\"|" config.yaml
    sed -i "s|^cron_change_script: .*|cron_change_script: \"$INSTALL_DIR/change_ip_scheduled.sh\"|" config.yaml
    sed -i "s|^log_file: .*|log_file: \"$INSTALL_DIR/logs/change_ip.log\"|" config.yaml
    sed -i "s|^telegram_bot_token: .*|telegram_bot_token: \"$telegram_bot_token\"|" config.yaml
    sed -i "s|^telegram_chat_id: .*|telegram_chat_id: \"$telegram_chat_id\"|" config.yaml
    sed -i "s|^ip_change_api: .*|ip_change_api: \"$ip_change_api\"|" config.yaml
fi

# 验证配置文件更新
if ! grep -q "$telegram_bot_token" config.yaml || ! grep -q "$telegram_chat_id" config.yaml || ! grep -q "$ip_change_api" config.yaml; then
    echo "错误：配置文件更新失败"
    exit 1
fi

# 配置 crontab
echo "正在配置定时任务..."
crontab -l > mycron 2>/dev/null || echo "" > mycron
check_schedule=$(grep "^cron_check_schedule:" config.yaml | cut -d'"' -f2)
check_script=$(grep "^cron_check_script:" config.yaml | cut -d'"' -f2)
change_schedule=$(grep "^cron_change_schedule:" config.yaml | cut -d'"' -f2)
change_script=$(grep "^cron_change_script:" config.yaml | cut -d'"' -f2)

# 验证定时任务配置
if [ -z "$check_schedule" ] || [ -z "$check_script" ] || [ -z "$change_schedule" ] || [ -z "$change_script" ]; then
    echo "错误：获取定时任务配置失败"
    exit 1
fi

# 添加定时任务
echo "$check_schedule $check_script" >> mycron
echo "$change_schedule $change_script" >> mycron

# 安装新的crontab
if ! crontab mycron; then
    echo "错误：安装定时任务失败"
    rm mycron
    exit 1
fi
rm mycron

# 验证安装
echo -e "\n=== 验证安装 ==="
if [ ! -f "config.yaml" ]; then
    echo "错误：配置文件不存在"
    exit 1
fi

echo "验证定时任务..."
crontab -l | grep "change_ip" || { echo "错误：定时任务未设置成功"; exit 1; }

echo -e "\n=== 安装完成！ ==="
echo "安装目录: $INSTALL_DIR"
echo "配置文件: $INSTALL_DIR/config.yaml"
echo "定时任务已配置完成，可以通过 crontab -l 查看"
echo "您可以通过编辑 config.yaml 文件修改配置" 