#!/bin/bash

# 安装依赖
pip install -r requirements.txt
pip install pyinstaller

# 使用PyInstaller打包
pyinstaller --onefile \
    --add-data "config.yaml:." \
    --hidden-import telegram \
    --hidden-import yaml \
    src/bot.py

# 移动生成的文件
mv dist/bot vps-ip-bot
chmod +x vps-ip-bot 