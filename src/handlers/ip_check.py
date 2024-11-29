from telegram import Update
from telegram.ext import ContextTypes
from utils.network import check_ip_blocked
from config import load_config

async def check_ip_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """检查IP状态的命令处理器"""
    config = load_config()
    
    # 验证用户权限
    if str(update.effective_user.id) != config['telegram_chat_id']:
        await update.message.reply_text("未授权的用户")
        return
        
    await update.message.reply_text("正在检查IP状态...")
    
    try:
        is_blocked, current_ip = check_ip_blocked()
        
        if is_blocked:
            await update.message.reply_text(
                f"当前IP ({current_ip}) 已被封锁\n"
                f"使用 /change 命令更换IP"
            )
        else:
            await update.message.reply_text(
                f"当前IP ({current_ip}) 状态正常"
            )
    except Exception as e:
        await update.message.reply_text(f"检查IP状态时出错: {str(e)}") 