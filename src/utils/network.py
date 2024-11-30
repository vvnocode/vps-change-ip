import requests
import logging
import subprocess
from typing import Tuple
from config import config
from utils.logger import logger

def get_current_ip() -> str:
    """获取当前IP地址"""
    try:
        if config['ip_check_api']:
            response = requests.get(config['ip_check_api'], timeout=10)
        else:
            cmd = config['ip_check_cmd']
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            response = result.stdout.strip()
        return response
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

def change_ip(api_url: str) -> str:
    """更换IP地址"""
    try:
        cmd = "curl -s " + api_url
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        response = result.stdout.strip()
        return response
    except Exception as e:
        logger.error(f"更换IP失败: {str(e)}")
        return None 