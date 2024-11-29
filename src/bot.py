#!/usr/bin/env python3
import logging
from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes
from config import config
from handlers.ip_check import check_ip_status
from handlers.ip_change import change_ip_handler

# 设置日志
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO
)
logger = logging.getLogger(__name__)

class VPSChangeIPBot:
    def __init__(self):
        self.config = config
        print(f"Bot Token: {self.config['telegram_bot_token']}")
        print(f"Chat ID: {self.config['telegram_chat_id']}")
        self.app = None
        
    async def start(self, update: Update, context):
        """处理/start命令"""
        logger.info(f"收到 start 命令，用户ID: {update.effective_user.id}")
        user_id = update.effective_user.id
        if str(user_id) != self.config["telegram_chat_id"]:
            logger.warning(f"未授权用户尝试访问，用户ID: {user_id}")
            await update.message.reply_text("未授权的用户")
            return
            
        await update.message.reply_text(
            "欢迎使用VPS IP更换工具\n"
            "/check - 检查当前IP状态\n"
            "/change - 手动更换IP"
        )

    def run(self):
        """运行机器人"""
        logger.info("机器人开始初始化...")
        self.app = ApplicationBuilder().token(self.config["telegram_bot_token"]).build()
        
        # 添加命令处理器
        logger.info("注册命令处理器...")
        self.app.add_handler(CommandHandler("start", self.start))
        self.app.add_handler(CommandHandler("check", check_ip_status))
        self.app.add_handler(CommandHandler("change", change_ip_handler))
        
        # 启动机器人
        logger.info("机器人开始运行...")
        self.app.run_polling()

def main():
    """主函数"""
    bot = VPSChangeIPBot()
    bot.run()

if __name__ == "__main__":
    main() 