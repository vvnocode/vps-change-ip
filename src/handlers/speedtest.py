import speedtest
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
        s = speedtest.Speedtest()
        servers = s.get_servers()
        best_server = s.get_best_server()
        
        # 构建节点列表(显示所有节点)
        server_list = []
        for distance, server_group in sorted(servers.items()):
            for server in server_group:
                server_list.append({
                    'id': server['id'],
                    'name': server['name'],
                    'sponsor': server['sponsor'],
                    'distance': distance
                })
        
        # 构建内联键盘
        keyboard = []
        for server in server_list:
            keyboard.append([InlineKeyboardButton(
                f"{server['name']} - {server['sponsor']} ({server['distance']:.2f}km)", 
                callback_data=f"speedtest_{server['id']}"
            )])
        
        # 添加最佳服务器选项
        keyboard.insert(0, [InlineKeyboardButton(
            f"🌟 推荐节点: {best_server['name']} - {best_server['sponsor']}", 
            callback_data=f"speedtest_{best_server['id']}"
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
    
    server_id = int(query.data.split("_")[1])
    await query.edit_message_text(f"正在使用节点 {server_id} 进行测速...\n这可能需要几分钟时间...")
    
    try:
        s = speedtest.Speedtest()
        s.get_servers([server_id])
        
        await query.edit_message_text(f"正在测试下载速度...")
        s.download()
        
        await query.edit_message_text(f"正在测试上传速度...")
        s.upload()
        
        results = s.results.dict()
        share_url = s.results.share()  # 获取分享链接
        
        # 格式化结果
        message = f"""📊 测速结果:

🏢 测速节点: {results['server']['sponsor']} ({results['server']['name']})
🌍 位置: {results['server']['country']}

⬇️ 下载速度: {results['download']/1_000_000:.2f} Mbps
⬆️ 上传速度: {results['upload']/1_000_000:.2f} Mbps
📶 延迟: {results['ping']:.2f} ms

🔗 分享链接: {share_url}"""

        await query.edit_message_text(message)
        
    except Exception as e:
        logger.error(f"测速失败: {str(e)}")
        await query.edit_message_text(f"测速失败: {str(e)}")