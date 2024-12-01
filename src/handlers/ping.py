import subprocess
import re
from telegram import Update
from telegram.ext import ContextTypes
from handlers.user_check import check_user_permission
from config import config
from utils.logger import logger

async def ping_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """处理 ping 命令"""
    # 验证用户权限
    if not await check_user_permission(update):
        return
    
    user_id = update.effective_user.id
    user_name = update.effective_user.username
    full_name = update.effective_user.full_name
    logger.info(f"收到 ping 命令，用户ID: {user_id}，用户名: {user_name}，全名: {full_name}")
    
    # 获取默认值
    target = config.get('ping_target', '1.1.1.1')
    count = config.get('ping_count', 10)
    
    # 解析参数
    if context.args:
        args = context.args
        i = 0
        while i < len(args):
            if args[i] == '-c':
                if i + 1 < len(args) and args[i + 1].isdigit():
                    count = int(args[i + 1])
                    i += 2
                else:
                    await update.message.reply_text("无效的 -c 参数，使用默认值")
                    i += 1
            else:
                # 不是 -c 参数，则视为目标地址
                target = args[i]
                i += 1
    
    # 验证 count 范围
    if count < 1:
        count = 1
    elif count > 100:  # 设置最大限制以防止滥用
        count = 100
        await update.message.reply_text("Ping 次数已限制为最大值 100")
    
    await update.message.reply_text(f"正在 ping {target} ({count} 次)...")
    
    try:
        # 执行ping命令
        result = subprocess.run(
            ['ping', '-c', str(count), target],
            capture_output=True,
            text=True,
            timeout=300
        )
        
        # 解析输出
        output = result.stdout
        
        # 提取关键信息
        stats_match = re.search(r'(\d+) packets transmitted, (\d+) received, (\d+)% packet loss', output)
        rtt_match = re.search(r'min/avg/max/mdev = ([\d.]+)/([\d.]+)/([\d.]+)/([\d.]+)', output)
        
        if stats_match and rtt_match:
            transmitted, received, loss = stats_match.groups()
            min_rtt, avg_rtt, max_rtt, mdev = rtt_match.groups()
            
            message = f"""📍 Ping 结果 ({target}):

📊 统计信息:
• 发送: {transmitted}
• 接收: {received}
• 丢包率: {loss}%

⏱️ 延迟:
• 最小: {min_rtt} ms
• 平均: {avg_rtt} ms
• 最大: {max_rtt} ms
• 抖动: {mdev} ms
"""
        else:
            message = output
            
        await update.message.reply_text(message)
        
    except subprocess.TimeoutExpired:
        await update.message.reply_text("Ping 超时")
    except Exception as e:
        await update.message.reply_text(f"执行 ping 时出错: {str(e)}")