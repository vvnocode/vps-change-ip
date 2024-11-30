from config import config

# 验证用户权限
async def check_user_permission(update):
    if str(update.effective_user.id) not in config['telegram_chat_id'].split(','):
        await update.message.reply_text("未授权的用户")
        return False
    return True