#!/bin/bash

# 引入通用功能模块
source change_ip_common.sh

# 从JSON响应中提取字段
parse_json() {
    local json="$1"
    local field="$2"
    echo "$json" | grep -o "\"$field\":\"[^\"]*\"" | cut -d'"' -f4
}

# 获取更新
get_updates() {
    local offset=$1
    echo "telegram_bot_token: $TELEGRAM_BOT_TOKEN" >> "$LOG_FILE"
    local response=$(curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getUpdates?offset=$offset&timeout=60")
    # 添加调试日志
    echo "$(date): 获取更新响应: $response" >> "$LOG_FILE"
    echo "$response"
}

# 处理消息
process_message() {
    local update="$1"
    
    # 添加日志记录
    echo "收到更新: $update" >> "$LOG_FILE"
    
    # 提取chat_id和消息文本
    local chat_id=$(echo "$update" | grep -o '"chat":{"id":[0-9]*' | grep -o '[0-9]*')
    local from_id=$(echo "$update" | grep -o '"from":{"id":[0-9]*' | grep -o '[0-9]*')
    local text=$(parse_json "$update" "text")
    local update_id=$(echo "$update" | grep -o '"update_id":[0-9]*' | grep -o '[0-9]*')

    # 记录提取的信息
    echo "Chat ID: $chat_id, From ID: $from_id, Text: $text" >> "$LOG_FILE"

    # 只处理指定from_id的消息
    if [ "$from_id" = "$TELEGRAM_CHAT_ID" ]; then
        case "$text" in
            "/changeip"|"换IP")
                echo "执行换IP命令" >> "$LOG_FILE"
                # 确保change_ip函数存在
                if type change_ip >/dev/null 2>&1; then
                    change_ip "manual" || echo "换IP失败" >> "$LOG_FILE"
                    # 发送结果消息回telegram
                    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                        -d "chat_id=$chat_id" \
                        -d "text=IP更换操作已执行"
                else
                    echo "change_ip函数未找到" >> "$LOG_FILE"
                    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                        -d "chat_id=$chat_id" \
                        -d "text=系统错误：换IP功能未正确配置"
                fi
                ;;
        esac
    else
        echo "无效的发送者ID: $from_id" >> "$LOG_FILE"
    fi
}

# 主循环
main() {
    local offset=0
    
    # 确保日志目录存在
    mkdir -p "$(dirname "$LOG_FILE")"
    
    echo "$(date): 机器人启动，Token: ${TELEGRAM_BOT_TOKEN:0:10}..." >> "$LOG_FILE"
    echo "$(date): 监听的Chat ID: $TELEGRAM_CHAT_ID" >> "$LOG_FILE"
    
    while true; do
        echo "$(date): 开始获取更新，offset=$offset" >> "$LOG_FILE"
        local response=$(get_updates "$offset")
        
        # 检查是否有新消息
        if echo "$response" | grep -q '"ok":true' && echo "$response" | grep -q '"result":\['; then
            echo "$(date): 收到新消息" >> "$LOG_FILE"
            # 使用临时文件存储结果
            echo "$response" | grep -o '{[^}]*}' | while read -r update; do
                echo "$(date): 处理消息: $update" >> "$LOG_FILE"
                new_offset=$(process_message "$update")
                if [ ! -z "$new_offset" ]; then
                    offset=$((new_offset + 1))
                    echo "$offset" > /tmp/change_ip_offset
                    echo "$(date): 更新 offset 为 $offset" >> "$LOG_FILE"
                fi
            done
            
            # 读取新的offset
            if [ -f /tmp/change_ip_offset ]; then
                offset=$(cat /tmp/change_ip_offset)
                rm /tmp/change_ip_offset
            fi
        else
            echo "$(date): 没有新消息或获取失败: $response" >> "$LOG_FILE"
        fi
        
        sleep 1
    done
}

# 启动机器人
main 