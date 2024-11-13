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
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        echo "正在下载 $output (尝试 $((retry_count + 1))/$max_retries)..."
        
        # 使用 -f 选项强制下载，-L 跟随重定向，增加超时设置
        if curl -f -L -s --connect-timeout 10 --max-time 30 "$url" -o "$output"; then
            if [ -f "$output" ]; then
                echo "下载 $output 成功"
                return 0
            fi
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            echo "下载失败，等待 3 秒后重试..."
            sleep 3
        fi
    done

    echo "下载 $output 失败（已重试 $max_retries 次）"
    return 1
}

# 下载所需文件
echo "正在下载必要文件..."
FILES_TO_DOWNLOAD=(
    "https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/change_ip_common.sh"
    "https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/change_ip_check.sh"
    "https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/change_ip_scheduled.sh"
    "https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/config.yaml.example"
)
FILES_OUTPUT=(
    "change_ip_common.sh"
    "change_ip_check.sh"
    "change_ip_scheduled.sh"
    "config.yaml.example"
)

for i in "${!FILES_TO_DOWNLOAD[@]}"; do
    if ! download_file "${FILES_TO_DOWNLOAD[$i]}" "${FILES_OUTPUT[$i]}"; then
        echo "错误：无法下载必要文件，安装终止"
        echo "请检查网络连接或访问 https://github.com/vvnocode/vps-change-ip 手动下载文件"
        exit 1
    fi
done

# 处理配置文件
if [ ! -f "config.yaml" ]; then
    echo "未检测到现有配置文件，将使用示例配置..."
    cp config.yaml.example config.yaml
else
    echo "检测到现有配置文件，将保留现有配置..."
fi

# 设置脚本执行权限
chmod +x change_ip_*.sh

# 交互式配置
echo -e "\n=== 配置信息 ==="
read -p "是否要更新配置信息？(y/N): " update_config
if [[ "$update_config" =~ ^[Yy]$ ]]; then
    read -p "请输入Telegram Bot Token: " telegram_bot_token
    read -p "请输入Telegram Chat ID: " telegram_chat_id
    read -p "请输入IP更换API地址: " ip_change_api

    # 验证输入不为空
    if [ -z "$telegram_bot_token" ] || [ -z "$telegram_chat_id" ] || [ -z "$ip_change_api" ]; then
        echo "错误：配置信息不能为空"
        exit 1
    fi

    # 更新配置文件
    echo "更新配置文件..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|^telegram_bot_token: .*|telegram_bot_token: \"$telegram_bot_token\"|" config.yaml
        sed -i '' "s|^telegram_chat_id: .*|telegram_chat_id: \"$telegram_chat_id\"|" config.yaml
        sed -i '' "s|^ip_change_api: .*|ip_change_api: \"$ip_change_api\"|" config.yaml
    else
        # Linux
        sed -i "s|^telegram_bot_token: .*|telegram_bot_token: \"$telegram_bot_token\"|" config.yaml
        sed -i "s|^telegram_chat_id: .*|telegram_chat_id: \"$telegram_chat_id\"|" config.yaml
        sed -i "s|^ip_change_api: .*|ip_change_api: \"$ip_change_api\"|" config.yaml
    fi

    # 验证配置文件更新
    if ! grep -q "$telegram_bot_token" config.yaml || ! grep -q "$telegram_chat_id" config.yaml || ! grep -q "$ip_change_api" config.yaml; then
        echo "错误：配置文件更新失败"
        exit 1
    fi
fi

# 仅更新路径相关的配置
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|^cron_check_script: .*|cron_check_script: \"$INSTALL_DIR/change_ip_check.sh\"|" config.yaml
    sed -i '' "s|^cron_change_script: .*|cron_change_script: \"$INSTALL_DIR/change_ip_scheduled.sh\"|" config.yaml
    sed -i '' "s|^log_file: .*|log_file: \"$INSTALL_DIR/logs/change_ip.log\"|" config.yaml
else
    # Linux
    sed -i "s|^cron_check_script: .*|cron_check_script: \"$INSTALL_DIR/change_ip_check.sh\"|" config.yaml
    sed -i "s|^cron_change_script: .*|cron_change_script: \"$INSTALL_DIR/change_ip_scheduled.sh\"|" config.yaml
    sed -i "s|^log_file: .*|log_file: \"$INSTALL_DIR/logs/change_ip.log\"|" config.yaml
fi

# 配置定时任务
setup_crontab() {
    echo -e "\n=== 验证安装 ==="
    echo "配置定时任务..."
    
    # 创建临时文件
    TEMP_CRON=$(mktemp)
    
    # 获取当前的crontab内容，排除change_ip相关行
    crontab -l 2>/dev/null | grep -v "change_ip" > "$TEMP_CRON" || true
    
    # 确保文件以换行符结尾
    if [ -s "$TEMP_CRON" ] && [ "$(tail -c1 "$TEMP_CRON" | wc -l)" -eq 0 ]; then
        echo "" >> "$TEMP_CRON"
    fi
    
    # 添加新的定时任务
    echo "*/30 * * * * $INSTALL_DIR/change_ip_check.sh" >> "$TEMP_CRON"
    echo "0 6 * * * $INSTALL_DIR/change_ip_scheduled.sh" >> "$TEMP_CRON"
    
    # 应用新的crontab配置
    crontab "$TEMP_CRON"
    
    # 清理临时文件
    rm -f "$TEMP_CRON"
    
    echo "验证定时任务..."
    crontab -l | grep "change_ip"
}

# 调用setup_crontab函数
setup_crontab

# 验证安装
echo -e "\n=== 安装完成！ ==="
echo "安装目录: $INSTALL_DIR"
echo "配置文件: $INSTALL_DIR/config.yaml"
echo "定时任务已配置完成，可以通过 crontab -l 查看"
echo "您可以通过编辑 config.yaml 文件修改配置" 