# vps-change-ip
通过 Telegram Bot 管理和更换 VPS 的 IP 地址。
[项目地址](https://github.com/vvnocode/vps-change-ip)

## 功能特点
- 通过 Telegram Bot 远程操控
- 检测 IP 是否被封锁
- 一键更换 VPS IP 地址
- 检查 IP 质量（支持流媒体解锁检测）
- 多重风险评估（SCAMALYTICS/ipapi/Cloudflare）
- 网络延迟测试（支持自定义目标和参数）
- 使用speedtest-cli进行测速

## 功能截图

![](https://s1.locimg.com/2024/12/01/d96620e9dbfc4.png)
![](https://s1.locimg.com/2024/11/30/cf6d303bb8f8d.png)
![](https://s1.locimg.com/2024/11/30/467ca6e7a1756.png)
![](https://s1.locimg.com/2024/12/01/c1bcdfc43452b.png)
![](https://s1.locimg.com/2024/12/01/6b6e93ca8e9e7.png)
![](https://s1.locimg.com/2024/12/01/2d24313b0d0f2.jpg)
![](https://s1.locimg.com/2024/12/01/b23bd456f0b25.jpg)

## 使用

### 前置操作

- 获取Telegram Bot Token和Chat ID
- 一定要在服务器上运行一次`bash <(curl -Ls IP.Check.Place)`，因为该脚本需要手动输入y才能继续

### 使用install.sh安装(推荐)

1. 运行一键安装脚本
```bash
bash <(curl -L -s https://raw.githubusercontent.com/vvnocode/vps-change-ip/main/install.sh)
```
2. 根据提示输入Telegram Bot Token和Chat ID
3. 更换API接口为可选项

### 手动修改配置文件

安装完成后可以手动修改配置文件，修改完成后需要重启服务：`systemctl restart vps-ip-bot`

配置文件位于 `/etc/vps-ip-bot/config.yaml`，示例：
```yaml
# Telegram配置
telegram_bot_token: ""  # 你的Telegram Bot Token
telegram_chat_id: ""    # 授权的Telegram用户ID, 多个用户ID用逗号分隔

# IP更换配置
ip_check_cmd: "curl -s api-ipv4.ip.sb/ip"       # IP检查命令
ip_check_api: ""       # IP检查API地址，idc提供。如果为空则使用ip_check_cmd
ip_change_api: ""       # IP更换API地址，idc提供。
ip_change_interval: 2  # IP更换最小间隔(分钟)

# Ping配置
ping_target: "1.1.1.1"  # 默认ping目标
ping_count: 10         # ping次数
```

### Telegram Bot 命令
- `/start` - 显示帮助信息
- `/check` - 检查当前IP是否被封锁
- `/change` - 手动更换IP地址
- `/quality` - 检查IP质量（含流媒体解锁检测）
- `/ping` - 测试网络延迟。支持自定义参数，例如：`/ping 8.8.8.8 -c 5`
- `/speedtest` - 测试网络速度
### 服务管理
```bash
# 启动服务
systemctl start vps-ip-bot

# 停止服务
systemctl stop vps-ip-bot

# 重启服务
systemctl restart vps-ip-bot

# 查看服务状态
systemctl status vps-ip-bot
```

## 开发

1. 克隆项目:
```shell
git clone https://github.com/vvnocode/vps-change-ip.git
cd vps-change-ip
```

2. 创建并激活虚拟环境:
```shell
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# 或
.\venv\Scripts\activate  # Windows
```

3. 安装依赖:
```shell
pip install -r requirements.txt
```

4. 本地开发运行:
```shell
python src/bot.py
```

## 常见问题

### 1. 如何获取 Telegram Bot Token？
1. 在 Telegram 中找到 @BotFather
2. 发送 `/newbot` 命令
3. 按照提示设置 bot 名称
4. 获取 bot token

### 2. 如何获取 Chat ID？
1. 在 Telegram 中找到 @userinfobot
2. 发送任意消息
3. 机器人会返回你的 Chat ID

### 3. 如何卸载？
```bash
bash <(curl -L -s https://raw.githubusercontent.com/vvnocode/vps-change-ip/refs/heads/main/install.sh) uninstall
```

## 贡献指南
欢迎提交 Pull Request 或 Issue 来帮助改进项目。

## 许可证
MIT License