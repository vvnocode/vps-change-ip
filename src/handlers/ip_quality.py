import subprocess
import re
from telegram import Update
from telegram.ext import ContextTypes
from handlers.user_check import check_user_permission
from utils.logger import logger
command = "yes y | curl -Ls IP.Check.Place | bash"

def clean_ansi_codes(text):
    """清理 ANSI 转义序列"""
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', text)

def run_command_and_collect_data(command):
    """运行命令并收集输出数据"""
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        shell=True
    )
    
    output_lines = []
    while True:
        line = process.stdout.readline()
        if not line:
            break
            
        try:
            line_str = line.decode('utf-8')
        except UnicodeDecodeError:
            try:
                line_str = line.decode('latin-1')
            except UnicodeDecodeError:
                continue
                
        clean_line = clean_ansi_codes(line_str)
        print('\r' + clean_line, end='', flush=True)
        output_lines.append(clean_line.strip())
    
    process.stdout.close()
    process.wait()
    print()
    return output_lines

def parse_ip_check_result(output_lines):
    """解析IP检测结果的关键信息"""
    result = {
        'ip': '',
        'location': '',
        'risk_scores': {},
        'streaming': {},
        'basic_info': {}
    }
    
    streaming_data = False
    service_status = {}
    regions_queue = []  # 使用列表作为队列存储地区
    methods_queue = []  # 使用列表作为队列存储方式
    
    for line in output_lines:
        # 提取IP地址
        if 'IP质量体检报告(Lite)：' in line:
            ip_match = re.search(r'IP质量体检报告\(Lite\)：(\d+\.\d+\.\*\.\*)', line)
            if ip_match:
                result['ip'] = ip_match.group(1)
        
        # 提取风险评分
        if 'SCAMALYTICS：' in line:
            match = re.search(r'SCAMALYTICS：\s+(\d+\|\w+风险)', line)
            if match:
                result['risk_scores']['SCAMALYTICS'] = match.group(1)
        elif 'ipapi：' in line:
            match = re.search(r'ipapi：\s+([\d.]+%\|\w+风险)', line)
            if match:
                result['risk_scores']['ipapi'] = match.group(1)
        elif 'Cloudflare：' in line:
            match = re.search(r'Cloudflare：\s+(\d+\|\w+风险)', line)
            if match:
                result['risk_scores']['Cloudflare'] = match.group(1)
        
        # 检测流媒体部分
        if '五、流媒体及AI服务解锁检测' in line:
            streaming_data = True
            continue
        elif '六、' in line:
            streaming_data = False
            
        if streaming_data:
            if '状态：' in line:
                statuses = line.split()[1:]
                for i, status in enumerate(statuses):
                    service_status[i] = status
            elif '地区：' in line:
                regions = line.split()[1:]
                regions_queue = [r for r in regions if r.strip()]  # 存储非空地区
            elif '方式：' in line:
                methods = line.split()[1:]
                methods_queue = [m for m in methods if m.strip()]  # 存储非空方式
            elif '服务商：' in line:
                services = line.split()[1:]
                for i, service in enumerate(services):
                    result['streaming'][service] = ''
    
    # 修改合并服务信息的逻辑
    for service_name in result['streaming'].keys():
        idx = list(result['streaming'].keys()).index(service_name)
        status = service_status.get(idx, '')
        
        if status in ['失败', '屏蔽']:
            service_info = status
        else:
            service_info = status
            # 如果有可用的地区，取出第一个
            if regions_queue:
                service_info += f"-{regions_queue.pop(0)}"
            # 如果有可用的方式，取出第一个
            if methods_queue:
                service_info += f"-{methods_queue.pop(0)}"
            
        result['streaming'][service_name] = service_info
    
    return result

def format_telegram_message(parsed_data):
    """格式化Telegram消息"""
    message = f"""
📍 IP: {parsed_data['ip']}
    
🛡️ 风险评估:
- SCAMALYTICS: {parsed_data['risk_scores'].get('SCAMALYTICS', 'N/A')}
- ipapi: {parsed_data['risk_scores'].get('ipapi', 'N/A')}
- Cloudflare: {parsed_data['risk_scores'].get('Cloudflare', 'N/A')}

🎬 流媒体解锁状态:"""

    for service, info in parsed_data['streaming'].items():
        status = info.split('-')[0] if '-' in info else info
        emoji = '✅' if status == '解锁' else '❌'
        message += f"\n{emoji} {service}：{info}"
    
    return message.strip()

async def get_telegram_send_message():
    output_lines = run_command_and_collect_data(command)
    parsed_data = parse_ip_check_result(output_lines)
    return format_telegram_message(parsed_data)

async def ip_quality_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """检查IP质量的命令处理器"""
    # 验证用户权限
    if not await check_user_permission(update):
        return
    
    user_id = update.effective_user.id
    user_name = update.effective_user.username
    full_name = update.effective_user.full_name
    logger.info(f"收到 quality 命令，用户ID: {user_id}，用户名: {user_name}，全名: {full_name}")
    
    await update.message.reply_text("正在检测IP质量...")

    message = await get_telegram_send_message()
    await update.message.reply_text(text=message)