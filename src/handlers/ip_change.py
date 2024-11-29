from telegram import Update
from telegram.ext import ContextTypes
from utils.network import change_ip, get_current_ip
from handlers.ip_quality import IPQualityChecker
from config import load_config

async def change_ip_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """更换IP的命令处理器"""
    config = load_config()
    
    # 验证用户权限
    if str(update.effective_user.id) != config['telegram_chat_id']:
        await update.message.reply_text("未授权的用户")
        return
        
    await update.message.reply_text("正在更换IP...")
    
    try:
        old_ip = get_current_ip()
        
        # 调用API更换IP
        if change_ip(config['ip_change_api']):
            # 等待IP更换完成
            new_ip = get_current_ip()
            
            if old_ip != new_ip:
                await update.message.reply_text(
                    f"IP更换成功!\n"
                    f"旧IP: {old_ip}\n"
                    f"新IP: {new_ip}"
                )
                
                # 检查IP质量
                checker = IPQualityChecker(
                    check_script=config.get('ip_check_script'),
                    screenshot_path=config.get('ip_check_screenshot_path', '/tmp/ip_check.png')
                )
                
                success, screenshot_path, error_msg = checker.check()
                
                if success:
                    await update.message.reply_photo(
                        photo=open(screenshot_path, 'rb'),
                        caption="IP检查结果"
                    )
                    checker.cleanup()
                elif error_msg:
                    await update.message.reply_text(f"IP检查失败: {error_msg}")
            else:
                await update.message.reply_text("IP更换可能未成功,新旧IP相同")
        else:
            await update.message.reply_text("IP更换失败,请检查API")
    except Exception as e:
        await update.message.reply_text(f"更换IP时出错: {str(e)}") 