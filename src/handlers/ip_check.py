from telegram import Update
from telegram.ext import ContextTypes
from utils.network import check_ip_blocked
from handlers.user_check import check_user_permission
from utils.logger import logger

async def check_ip_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """检查IP状态的命令处理器"""
    
    # 验证用户权限
    if not await check_user_permission(update):
        return
    
    user_id = update.effective_user.id
    logger.info(f"收到 check 命令，用户ID: {user_id}")
    
    await update.message.reply_text(
        text="正在检查IP状态..."
    )
    
    try:
        is_blocked, current_ip = check_ip_blocked()
        
        if is_blocked:
            await update.message.reply_text(
                text=f"当前IP ({current_ip}) 已被封锁\n"
                f"使用 /change 命令更换IP"
            )
        else:
            await update.message.reply_text(
                text=f"当前IP ({current_ip}) 状态正常"
            )
    except Exception as e:
        await update.message.reply_text(
            text=f"检查IP状态时出错: {str(e)}"
        ) 