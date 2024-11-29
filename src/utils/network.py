import requests
import logging
import subprocess
from typing import Tuple
from config import config

logger = logging.getLogger(__name__)

def get_current_ip() -> str:
    """获取当前IP地址"""
    try:
        response = requests.get(config['ip_check_api'], timeout=10)
        return response.text.strip()
    except Exception as e:
        logger.error(f"获取IP地址失败: {str(e)}")
        raise

def check_ip_blocked() -> Tuple[bool, str]:
    """检查IP是否被封锁"""
    ip = get_current_ip()
    
    try:
        result = subprocess.run(
            ['ping', '-c', '5', '-W', '2', '-i', '0.2', 'www.itdog.cn'],
            capture_output=True,
            text=True
        )
        is_blocked = "100% packet loss" in result.stdout
        return is_blocked, ip
    except Exception as e:
        logger.error(f"检查IP状态失败: {str(e)}")
        raise

def change_ip(api_url: str) -> bool:
    """更换IP地址"""
    try:
        response = requests.get(api_url, timeout=30)
        return response.status_code == 200
    except Exception as e:
        logger.error(f"更换IP失败: {str(e)}")
        raise 