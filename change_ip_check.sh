# IP封锁检测

#!/bin/bash
# change_ip_check.sh
# 引入通用功能模块
source "$(dirname "$0")/change_ip_common.sh"

# 检查当前IP是否被封锁
check_ip_status() {
    local ip_address=$(curl -s ifconfig.me)

    # 检查IP是否被封锁
    if ping -c 5 -W 2 -i 0.2 "www.itdog.cn" | grep -q "100% packet loss"; then
        log_and_notify "check：当前IP ($ip_address) 已被封锁，正在更换IP..."
        change_ip "check："
    else
        log "check：当前IP ($ip_address) 未被封锁。"
    fi
}

# 执行IP检测
check_ip_status
