from telegram import Update
from telegram.ext import ContextTypes
from utils.network import change_ip, get_current_ip
from config import config
import time
import os
from handlers.user_check import check_user_permission
from utils.logger import logger

# 添加获取上次更换时间的函数
def get_last_change_time() -> float:
    """获取上次更换IP的时间戳"""
    timestamp_file = "/tmp/last_ip_change.txt"
    if os.path.exists(timestamp_file):
        with open(timestamp_file, "r") as f:
            return float(f.read().strip())
    return 0

# 添加更新更换时间的函数
def update_last_change_time():
    """更新最后更换IP的时间戳"""
    timestamp_file = "/tmp/last_ip_change.txt"
    with open(timestamp_file, "w") as f:
        f.write(str(time.time()))

async def change_ip_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """更换IP的命令处理器"""
    
    # 验证用户权限
    if not await check_user_permission(update):
        return
    
    user_id = update.effective_user.id
    user_name = update.effective_user.username
    full_name = update.effective_user.full_name
    logger.info(f"收到 change 命令，用户ID: {user_id}，用户名: {user_name}，全名: {full_name}")

    # 检查是否配置了 ip_change_api
    if not config.get('ip_change_api'):
        await update.message.reply_text(
            "未配置 IP 更换 API，无法使用更换 IP 功能\n"
            "请在配置文件中设置 ip_change_api"
        )
        return
    
    # 检查更换间隔
    interval = config.get('ip_change_interval', 2) # 默认1分钟
    last_change = get_last_change_time()
    current_time = time.time()
    time_diff = (current_time - last_change) / 60  # 转换为分钟
    if time_diff < interval:
        remaining = int(interval - time_diff)
        await update.message.reply_text(
            f"距离上次更换IP时间不足{interval}分钟\n"
            f"请等待{remaining}分钟后再试"
        )
        return
        
    await update.message.reply_text(
        text="正在更换IP..."
    )
    
    try:
        old_ip = get_current_ip()
        
        # 调用API更换IP
        new_ip = change_ip(config['ip_change_api'])
        if new_ip:
            # 更新最后更换时间
            update_last_change_time()

            if old_ip != new_ip:
                await notify_ip_change_success(update, old_ip, new_ip)
            else:
                await update.message.reply_text("IP更换可能未成功,新旧IP相同")
        else:
            # 再次校验IP是否更换成功
            time.sleep(10)
            new_ip = get_current_ip()
            if old_ip != new_ip:
                await notify_ip_change_success(update, old_ip, new_ip)
            else:
                await update.message.reply_text("IP更换失败,请检查API")
    except Exception as e:
        await update.message.reply_text(
            text=f"更换IP时出错: {str(e)}"
        ) 

async def notify_ip_change_success(update: Update, old_ip, new_ip):
    """通知IP更换成功"""
    await update.message.reply_text(
        f"IP更换成功!\n"
        f"旧IP: {old_ip}\n"
        f"新IP: {new_ip}"
    )