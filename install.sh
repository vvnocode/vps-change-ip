#!/bin/bash

# 创建日志目录
mkdir -p logs

# 设置脚本执行权限
chmod +x change_ip_*.sh

# 配置 crontab
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

echo "安装完成！"
echo "请检查配置文件 config.yaml 并填写必要的配置项" 