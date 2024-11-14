#!/bin/bash

# 引入通用功能模块
source change_ip_common.sh

# 获取最新的未读消息
get_latest_updates() {
    local offset="$1"
    local response=$(curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getUpdates?offset=$offset")
    echo "$response" >> "$LOG_FILE"
    
    if ! echo "$response" | grep -q '"ok":true'; then
        echo "$(date): 获取更新失败: $response" >> "$LOG_FILE"
        return 1
    fi
    
    echo "$response"
}

# 处理消息
process_message() {
    local message="$1"
    
    # 提取消息信息
    local chat_id=$(echo "$message" | jq -r '.chat.id')
    local from_id=$(echo "$message" | jq -r '.from.id')
    local text=$(echo "$message" | jq -r '.text')
    
    # 只处理来自指定用户的消息
    if [ "$from_id" = "$TELEGRAM_CHAT_ID" ]; then
        case "$text" in
            "/changeip"|"换IP"|"换ip"|"换Ip"|"换iP")
                echo "$(date): 收到换IP命令 from user $from_id" >> "$LOG_FILE"
                if type change_ip >/dev/null 2>&1; then 
                    change_ip "manual" || echo "$(date): 换IP失败" >> "$LOG_FILE"
                else
                    echo "$(date): change_ip函数未找到" >> "$LOG_FILE"
                    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                        -d "chat_id=$chat_id" \
                        -d "text=系统错误：换IP功能未正确配置"
                fi
                ;;
        esac
    fi
}

# 获取最新的update_id
get_last_update_id() {
    local updates="$1"
    echo "$updates" | jq '.result[-1].update_id // 0'
}

# 读取上次处理的update_id
get_stored_update_id() {
    local offset=$(yq eval '.last_update_id // 0' "$CONFIG_FILE")
    echo "${offset:-0}"  # 如果读取失败返回0
}

# 保存最新的update_id
save_update_id() {
    local update_id="$1"
    # 使用临时文件避免并发写入问题
    local tmp_file="${CONFIG_FILE}.tmp"
    
    yq eval ".last_update_id = $update_id" "$CONFIG_FILE" > "$tmp_file" && \
    mv "$tmp_file" "$CONFIG_FILE"
    
    if [ $? -ne 0 ]; then
        echo "$(date): 保存update_id失败" >> "$LOG_FILE"
        return 1
    fi
}

# 主循环
main() {
    # 从配置文件读取上次的update_id
    local last_update_id=$(get_stored_update_id)
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "$(date): 机器人启动，从update_id=${last_update_id}开始" >> "$LOG_FILE"
    
    while true; do
        local updates=$(get_latest_updates $((last_update_id + 1)))
        if [ $? -eq 0 ]; then
            local current_update_id=$(get_last_update_id "$updates")
            
            if [ "$current_update_id" -gt "$last_update_id" ]; then
                echo "$updates" | jq -c '.result[].message' | while read -r message; do
                    if [ ! -z "$message" ]; then
                        process_message "$message"
                    fi
                done
                last_update_id=$current_update_id
                # 保存最新的update_id到配置文件
                save_update_id "$last_update_id"
            fi
        fi
        
        sleep 1
    done
}

# 启动机器人
main