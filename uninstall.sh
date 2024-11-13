#!/bin/bash

echo "=== VPS IP更换工具卸载 ==="

# 删除crontab任务
remove_crontab() {
    echo "正在删除定时任务..."
    # 获取当前的crontab内容
    crontab -l > crontab.tmp
    # 删除包含change_ip的行
    sed -i.bak '/change_ip/d' crontab.tmp
    # 应用新的crontab配置
    crontab crontab.tmp
    # 清理临时文件
    rm -f crontab.tmp crontab.tmp.bak
    echo "定时任务已删除"
}

# 获取安装目录
CURRENT_DIR=$(pwd)
INSTALL_DIR="$CURRENT_DIR/vps-change-ip"

# 如果不在安装目录中，尝试使用默认路径
if [ ! -d "$INSTALL_DIR" ]; then
    INSTALL_DIR="/root/vps-change-ip"
fi

# 删除定时任务
remove_crontab

# 如果安装目录存在，询问是否删除
if [ -d "$INSTALL_DIR" ]; then
    echo -e "\n是否保留配置文件？"
    echo "1) 是 - 保留所有文件"
    echo "2) 否 - 删除所有文件"
    read -p "请选择 [1/2] (默认: 1): " keep_config
    keep_config=${keep_config:-1}

    case $keep_config in
        1)
            echo "保留所有文件..."
            echo "仅删除了定时任务，您可以随时重新配置定时任务"
            ;;
        2)
            echo "删除所有文件..."
            rm -rf "$INSTALL_DIR"
            echo "安装目录已删除"
            ;;
        *)
            echo "无效的选择，将默认保留所有文件"
            ;;
    esac

    if [ "$keep_config" = "1" ]; then
        echo "所有文件已保留在: $INSTALL_DIR"
    fi
else
    echo "未找到安装目录，仅删除了定时任务"
fi

echo -e "\n卸载完成！" 