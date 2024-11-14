#!/bin/bash

# 引入通用功能模块
source "$(dirname "$0")/change_ip_common.sh"

# 从JSON响应中提取字段
parse_json() {
    local json="$1"
    local field="$2"
    echo "$json" | grep -o "\"$field\":\"[^\"]*\"" | cut -d'"' -f4
}

# 获取更新
get_updates() {
    local offset=$1
    curl -s "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getUpdates?offset=$offset&timeout=60"
}

# 处理消息
process_message() {
    local update="$1"
    
    # 提取chat_id和消息文本
    local chat_id=$(echo "$update" | grep -o '"chat":{"id":[0-9]*' | grep -o '[0-9]*')
    local text=$(parse_json "$update" "text")
    local update_id=$(echo "$update" | grep -o '"update_id":[0-9]*' | grep -o '[0-9]*')

    # 只处理指定chat_id的消息
    if [ "$chat_id" = "$TELEGRAM_CHAT_ID" ]; then
        case "$text" in
            "/changeip" | "换IP")
                change_ip "manual："
                ;;
        esac
    fi
    
    echo "$update_id"
}

# 主循环
main() {
    local offset=0
    
    while true; do
        local response=$(get_updates "$offset")
        
        # 检查是否有新消息
        if echo "$response" | grep -q '"ok":true' && echo "$response" | grep -q '"result":\['; then
            # 使用临时文件存储结果
            echo "$response" | grep -o '{[^}]*}' | while read -r update; do
                new_offset=$(process_message "$update")
                if [ ! -z "$new_offset" ]; then
                    offset=$((new_offset + 1))
                    echo "$offset" > /tmp/change_ip_offset
                fi
            done
            
            # 读取新的offset
            if [ -f /tmp/change_ip_offset ]; then
                offset=$(cat /tmp/change_ip_offset)
                rm /tmp/change_ip_offset
            fi
        fi
        
        sleep 1
    done
}

# 启动机器人
main 