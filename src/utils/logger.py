from loguru import logger
import sys
import os

# 创建logs目录
if not os.path.exists("logs"):
    os.makedirs("logs")

# 配置日志格式
fmt = "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <2}</level> | <magenta>{thread.name}</magenta> | <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>"

# 移除默认的控制台处理器
logger.remove()

# 添加控制台输出
logger.add(
    sys.stdout,
    format=fmt,
    level=os.getenv("LOG_LEVEL", "INFO"),  # 从环境变量获取日志级别
    colorize=True
)

# 添加文件输出
logger.add(
    "logs/bot.log",
    format=fmt,
    level=os.getenv("LOG_LEVEL", "INFO"),
    rotation="1 day",    
    retention="7 days",  
    compression="zip",   
    encoding="utf-8",
    enqueue=True  # 启用异步写入
) 