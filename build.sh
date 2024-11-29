#!/bin/bash

# 安装依赖
pip install -r requirements.txt
pip install pyinstaller

# 使用PyInstaller打包
pyinstaller --onefile \
    --name vps-ip-bot \
    --add-data "config.yaml.example:." \
    --hidden-import telegram \
    --hidden-import yaml \
    --paths src \
    src/bot.py

# 检查构建是否成功
if [ ! -f "dist/vps-ip-bot" ]; then
    echo "构建失败!"
    exit 1
fi

# 移动生成的文件
mv dist/vps-ip-bot .
chmod +x vps-ip-bot