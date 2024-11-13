# vps-change-ip
自动更改vps的ip。

## 使用

### 使用install.sh安装(推荐)

`bash <(curl -L -s https://raw.githubusercontent.com/vvnocode/vps-change-ip/refs/heads/main/install.sh)`

验证：`crontab -l`

### 手动配置

#### 配置config.yaml

将`config.yaml.example`复制为`config.yaml`，配置文件中需要配置以下内容：

- `telegram_bot_token`：Telegram Bot Token
- `telegram_chat_id`：Telegram Chat ID
- `ip_change_api`：IP更换API
- `log_file`：日志文件路径

#### 配置定时任务
1. `chmod +x change_ip_*.sh`
2. `crontab -e`
3. 配置定时任务，按需配置一个或者多个
	```shell
	# 每30分执行ip检测
	*/30 * * * * /root/change_ip_check.sh
	# 每天6:00执行IP更换
	0 6 * * * /root/change_ip_scheduled.sh
	```

4. 验证
	`crontab -l`