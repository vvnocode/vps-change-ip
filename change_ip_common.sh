#!/bin/bash
# 通用功能模块
# change_ip_common.sh
# 全局变量
TELEGRAM_BOT_TOKEN=""          # 替换为你的Telegram Bot Token
TELEGRAM_CHAT_ID=""            # 替换为你的Telegram Chat ID
IP_CHANGE_API=""               # 替换为实际的换IP API
TELEGRAM_API_URL="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"
LOG_FILE="change_ip.log" # 日志文件

# 读取配置文件
CONFIG_FILE="$(dirname "$0")/config.yaml"

# 解析配置文件中的变量
TELEGRAM_BOT_TOKEN=$(grep "^telegram_bot_token:" $CONFIG_FILE | cut -d'"' -f2)
TELEGRAM_CHAT_ID=$(grep "^telegram_chat_id:" $CONFIG_FILE | cut -d'"' -f2)
IP_CHANGE_API=$(grep "^ip_change_api:" $CONFIG_FILE | cut -d'"' -f2)
LOG_FILE=$(grep "^log_file:" $CONFIG_FILE | cut -d'"' -f2)

# 构建Telegram API URL
TELEGRAM_API_URL="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"

# 获取当前时间 (格式: yyyy-MM-dd HH:mm:ss)
current_timestamp() {
    echo "$(date +"%Y-%m-%d %H:%M:%S")"
}

# 打印日志
log() {
    local message="$1"
    local timestamp=$(current_timestamp)
    local formatted_message="[$timestamp] $message"

    # 写入日志文件
    echo "$formatted_message" | tee -a "$LOG_FILE"
}

# 发送到Telegram
notify() {
    local message="$1"
    local timestamp=$(current_timestamp)
    local formatted_message="[$timestamp] $message"

    # 发送消息到Telegram并记录结果
    local response
    response=$(curl -s -X POST "$TELEGRAM_API_URL" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$formatted_message" 2>&1)
    
    # 检查curl是否成功执行
    if [ $? -ne 0 ]; then
        echo "[$timestamp] Telegram通知发送失败: curl执行错误" >> "$LOG_FILE"
        return 1
    fi

    # 检查Telegram API响应
    if ! echo "$response" | grep -q '"ok":true'; then
        echo "[$timestamp] Telegram通知发送失败: $response" >> "$LOG_FILE"
        return 1
    fi

    echo "[$timestamp] Telegram通知发送成功" >> "$LOG_FILE"
    return 0
}

# 换IP操作
change_ip() {
	local prefix="$1"
    curl -s "$IP_CHANGE_API" > /dev/null
    ip_address=$(curl -s ifconfig.me)
    log_and_notify "${prefix}当前IP已经更换为($ip_address)。"
}

# 打印日志并发送到Telegram
log_and_notify() {
    local message="$1"
    log "$message"
    if ! notify "$message"; then
        log "警告：Telegram通知发送失败"
    fi
}