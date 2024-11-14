#!/bin/bash
# 定时更改IP
# change_ip_scheduled.sh

# 引入通用功能模块
source "$(dirname "$0")/change_ip_common.sh"

# 执行定时换IP任务
change_ip "scheduled："
