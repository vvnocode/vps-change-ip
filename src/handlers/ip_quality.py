import subprocess
import re
from telegram import Update
from telegram.ext import ContextTypes

command = "curl -Ls IP.Check.Place | bash"

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
    service_region = {}
    service_method = {}
    
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
                for i, region in enumerate(regions):
                    service_region[i] = region if region else ''
            elif '方式：' in line:
                methods = line.split()[1:]
                for i, method in enumerate(methods):
                    service_method[i] = method if method else ''
            elif '服务商：' in line:
                services = line.split()[1:]
                for i, service in enumerate(services):
                    result['streaming'][service] = {
                        'status': '',
                        'region': '',
                        'method': ''
                    }
    
    # 合并服务信息
    for service_name in result['streaming'].keys():
        idx = list(result['streaming'].keys()).index(service_name)
        status = service_status.get(idx, '')
        region = service_region.get(idx, '')
        method = service_method.get(idx, '')
        
        service_info = status
        if region and region != '':
            service_info += f"-{region}"
        if method and method != '':
            service_info += f"-{method}"
            
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

def get_telegram_send_message():
    output_lines = run_command_and_collect_data(command)
    parsed_data = parse_ip_check_result(output_lines)
    return format_telegram_message(parsed_data)

async def ip_quality_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """检查IP质量的命令处理器"""
    message = get_telegram_send_message()
    await update.message.reply_text(message)