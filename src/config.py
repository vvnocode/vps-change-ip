import os
import yaml
from typing import Dict, Any

def load_config() -> Dict[str, Any]:
    """加载配置文件"""
    # 优先查找当前目录
    config_paths = [
        "config.yaml",  # 当前目录
        os.path.join(os.path.dirname(__file__), "..", "config.yaml"),  # 项目根目录
        "/etc/vps-ip-bot/config.yaml"  # 系统路径
    ]
    
    for config_path in config_paths:
        if os.path.exists(config_path):
            with open(config_path, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
                break
    else:
        raise FileNotFoundError(f"未找到配置文件。请确保以下路径之一存在配置文件: {', '.join(config_paths)}")
        
    required_fields = ['telegram_bot_token', 'telegram_chat_id', 'ip_change_api']
    for field in required_fields:
        if not config.get(field):
            raise ValueError(f"配置文件缺少必要字段: {field}")
            
    return config

config = load_config()