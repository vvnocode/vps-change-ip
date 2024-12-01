from config import config
from utils.logger import logger

# 验证用户权限
async def check_user_permission(update):
    # 获取用户ID
    user_id = update.effective_user.id
    user_name = update.effective_user.username
    full_name = update.effective_user.full_name
    # 检查用户是否在授权列表中
    if str(user_id) not in config['telegram_chat_id'].split(','):
        logger.warning(f"未授权的用户尝试访问，用户ID: {user_id}，用户名: {user_name}，全名: {full_name}")
        await update.message.reply_text(f"未授权的用户")
        return False
    # 授权用户
    return True
