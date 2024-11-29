import os
import yaml
from typing import Dict, Any

def load_config() -> Dict[str, Any]:
    """加载配置文件"""
    config_path = "/etc/vps-ip-bot/config.yaml"
    
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"配置文件不存在: {config_path}")
        
    with open(config_path, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)
        
    required_fields = ['telegram_bot_token', 'telegram_chat_id', 'ip_change_api']
    for field in required_fields:
        if not config.get(field):
            raise ValueError(f"配置文件缺少必要字段: {field}")
            
    return config 

config = load_config()