#!/usr/bin/env python3
from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes, CallbackQueryHandler
from config import config
from handlers.ip_check import check_ip_status
from handlers.ip_change import change_ip_handler
from handlers.ip_quality import ip_quality_handler
from handlers.user_check import check_user_permission
from utils.logger import logger
from handlers.ping import ping_handler
from handlers.speedtest import speedtest_handler, speedtest_callback

class VPSChangeIPBot:
    def __init__(self):
        self.app = None
        
    async def start(self, update: Update, context: ContextTypes.DEFAULT_TYPE):
        """处理/start命令"""

        # 验证用户权限
        if not await check_user_permission(update):
            return
        
        user_id = update.effective_user.id
        user_name = update.effective_user.username
        full_name = update.effective_user.full_name
        logger.info(f"收到 start 命令，用户ID: {user_id}，用户名: {user_name}，全名: {full_name}")
            
        # 回复用户
        await update.message.reply_text(
            text="欢迎使用VPS IP更换工具\n"
            "/check - 检查当前IP状态\n"
            "/change - 手动更换IP\n"
            "/quality - 检查IP质量\n"
            "/ping - 测试网络延迟。默认目标为1.1.1.1，可运行ping自定义命令如 /ping 8.8.8.8 -c 10\n"
            "/speedtest - 测试网络速度"
        )

    def run(self):
        """运行机器人"""
        logger.info("机器人开始初始化...")
        self.app = ApplicationBuilder().token(config["telegram_bot_token"]).build()
        
        # 添加命令处理器
        logger.info("注册命令处理器...")
        self.app.add_handler(CommandHandler("start", self.start))
        self.app.add_handler(CommandHandler("check", check_ip_status))
        self.app.add_handler(CommandHandler("change", change_ip_handler))
        self.app.add_handler(CommandHandler("quality", ip_quality_handler))
        self.app.add_handler(CommandHandler("ping", ping_handler))
        self.app.add_handler(CommandHandler("speedtest", speedtest_handler))
        self.app.add_handler(CallbackQueryHandler(speedtest_callback, pattern="^speedtest_"))
        # 启动机器人
        logger.info("机器人开始运行...")
        self.app.run_polling()

def main():
    """主函数"""
    bot = VPSChangeIPBot()
    bot.run()

if __name__ == "__main__":
    main() 