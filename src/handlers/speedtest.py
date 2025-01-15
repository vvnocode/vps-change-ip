import subprocess
import json
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import ContextTypes
from handlers.user_check import check_user_permission
from utils.logger import logger

async def speedtest_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """处理 speedtest 命令"""
    if not await check_user_permission(update):
        return
    
    user_id = update.effective_user.id
    user_name = update.effective_user.username
    full_name = update.effective_user.full_name
    logger.info(f"收到 speedtest 命令，用户ID: {user_id}，用户名: {user_name}，全名: {full_name}")
    
    await update.message.reply_text("正在获取测速节点列表...")
    
    try:
        # 获取服务器列表
        result = subprocess.run(['speedtest', '-L', '--format=json'], 
                              capture_output=True, text=True, timeout=30)
        servers = json.loads(result.stdout)['servers']
        
        # 构建内联键盘
        keyboard = []
        for server in servers:
            keyboard.append([InlineKeyboardButton(
                f"{server['name']} - {server['location']} - {server['country']}", 
                callback_data=f"speedtest_{server['id']}"
            )])
        
        # 添加自动选择选项
        keyboard.insert(0, [InlineKeyboardButton(
            "🌟 自动选择最佳节点", 
            callback_data="speedtest_auto"
        )])
        
        reply_markup = InlineKeyboardMarkup(keyboard)
        
        await update.message.reply_text(
            "请选择测速节点:",
            reply_markup=reply_markup
        )
        
    except Exception as e:
        await update.message.reply_text(f"获取测速节点失败: {str(e)}")

async def speedtest_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """处理测速节点选择回调"""
    query = update.callback_query
    await query.answer()
    
    if not query.data.startswith("speedtest_"):
        return
    
    server_id = query.data.split("_")[1]
    
    # 构建命令
    cmd = ['speedtest', '--format=json']
    if server_id != 'auto':
        cmd.extend(['-s', server_id])
    
    await query.edit_message_text("正在进行测速...\n这可能需要几分钟时间...")
    
    try:
        # 首先尝试执行测速
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            
            # 检查是否需要接受许可
            if "Do you accept the license?" in result.stdout:
                # 如果需要接受许可，重新运行命令并自动输入YES
                process = subprocess.Popen(
                    cmd,
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True
                )
                output, error = process.communicate(input="YES\n")
                
                # 再次执行测速命令获取实际结果
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            
            # 尝试解析JSON
            try:
                data = json.loads(result.stdout)
            except json.JSONDecodeError:
                await query.edit_message_text(f"测速结果解析失败。原始输出：\n{result.stdout[:3000]}")
                return
                
            # 格式化结果
            message = f"""📊 测速结果:

🏢 测速节点: ({data['server']['location']}) ({data['server']['name']})
🌍 位置: ({data['server']['country']})

⬇️ 下载速度: {data['download']['bandwidth']/125000:.2f} Mbps
⬆️ 上传速度: {data['upload']['bandwidth']/125000:.2f} Mbps
📶 延迟: {data['ping']['latency']:.2f} ms

🔗 结果链接: {data.get('result', {}).get('url', 'N/A')}"""

            await query.edit_message_text(message)
            
        except subprocess.TimeoutExpired:
            await query.edit_message_text("测速超时，请稍后重试")
        except Exception as e:
            error_message = f"测速过程出错: {str(e)}"
            if hasattr(e, 'output'):
                error_message += f"\n输出: {e.output}"
            await query.edit_message_text(error_message)
    except Exception as e:
        logger.error(f"测速失败: {str(e)}")
        await query.edit_message_text(f"测速失败: {str(e)}")