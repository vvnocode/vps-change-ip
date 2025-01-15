#!/bin/bash

# 检测操作系统类型
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
    else
        OS=$(uname -s)
    fi
}

# Ubuntu/Debian 安装函数
install_debian() {
    echo "正在安装 Speedtest CLI (Ubuntu/Debian)..."
    # 清理旧版本
    sudo rm -f /etc/apt/sources.list.d/speedtest.list
    sudo apt-get update
    sudo apt-get remove -y speedtest speedtest-cli

    # 安装新版本
    sudo apt-get install -y curl
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    sudo apt-get install -y speedtest
}

# Fedora/CentOS/RHEL 安装函数
install_redhat() {
    echo "正在安装 Speedtest CLI (Fedora/CentOS/RHEL)..."
    # 清理旧版本
    sudo rm -f /etc/yum.repos.d/bintray-ookla-rhel.repo
    sudo yum remove -y speedtest
    rpm -qa | grep speedtest | xargs -I {} sudo yum -y remove {}

    # 安装新版本
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash
    sudo yum install -y speedtest
}

# FreeBSD 安装函数
install_freebsd() {
    echo "正在安装 Speedtest CLI (FreeBSD)..."
    sudo pkg update && sudo pkg install -y libidn2 ca_root_nss
    sudo pkg remove -y speedtest

    # 检测 FreeBSD 版本
    version=$(freebsd-version | cut -d '.' -f1)
    if [ "$version" = "12" ]; then
        sudo pkg add "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-freebsd12-x86_64.pkg"
    elif [ "$version" = "13" ]; then
        sudo pkg add "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-freebsd13-x86_64.pkg"
    else
        echo "不支持的 FreeBSD 版本"
        exit 1
    fi
}

# 主函数
main() {
    detect_os
    case "$OS" in
        *Ubuntu*|*Debian*)
            install_debian
            ;;
        *Fedora*|*CentOS*|*Red*Hat*)
            install_redhat
            ;;
        *FreeBSD*)
            install_freebsd
            ;;
        *)
            echo "不支持的操作系统: $OS"
            exit 1
            ;;
    esac

    echo "Speedtest CLI 安装完成！"
    echo "运行 'speedtest' 命令来测试网速"
}

main