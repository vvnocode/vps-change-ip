# vps-change-ip
自动更改vps的ip。

## 使用

配置定时任务

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