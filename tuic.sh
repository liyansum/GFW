#!/usr/bin/env bash

if [[ ! -d /opt/tuic ]]; then
    echo "创建文件夹"
    mkdir -p /opt/tuic && cd /opt/tuic
else
    echo "文件夹已存在 🎉 "
    cd /opt/tuic
fi

OS_ARCH=$(arch)
if [[ ${OS_ARCH} == "x86_64" || ${OS_ARCH} == "x64" || ${OS_ARCH} == "amd64" ]]; then
    OS_ARCH="x86_64"
    echo "当前系统架构为 ${OS_ARCH}"
elif [[ ${OS_ARCH} == "aarch64" || ${OS_ARCH} == "aarch64" ]]; then
    OS_ARCH="aarch64"
    echo "当前系统架构为 ${OS_ARCH}"
else
    OS_ARCH="amd64"
    echo "检测系统架构失败，使用默认架构: ${OS_ARCH}"
fi

echo "正在下载tuic..."
if [[ -f /opt/tuic/tuic ]]; then
    echo "tuic已存在 🎉"
else
    echo "正在下载tuic..."
    wget https://github.com/EAimTY/tuic/releases/download/0.8.5/tuic-server-0.8.5-${OS_ARCH}-linux-gnu -O tuic && chmod +x tuic
fi

echo "正在创建配置文件..."

if [[ -f /opt/tuic/config.json ]]; then

    echo "配置文件已存在🎉"
else
    echo "正在创建配置文件"

    read -p "请输入密码:(默认123456) " password

    read -p "请输入端口:(默认11443)" port

    cat >/opt/tuic/config.json <<EOF
{
    "port": ${port:-11443},
    "token": ["${password:-123456}"],
    "certificate": "/opt/tuic/cert.pem",
    "private_key": "/opt/tuic/key.pem",
    "ip": "0.0.0.0",
    "congestion_controller": "bbr",
    "alpn": ["h3"]
}
EOF

    cat >/lib/systemd/system/tuic.service <<EOF
[Unit]
Description=Delicately-TUICed high-performance proxy built on top of the QUIC protocol
Documentation=https://github.com/EAimTY/tuic
After=network.target

[Service]
User=root
WorkingDirectory=/opt/tuic
ExecStart=/opt/tuic/tuic -c config.json
Restart=on-failure
RestartPreventExitStatus=1
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

fi
echo "正在启动tuic..."
systemctl daemon-reload
systemctl start tuic

echo "开机自启动..."
systemctl enable tuic

echo "tuic 安装完成 🎉 🎉 🎉 "
echo "请将证书cert.pem，key.pem放于/opt/tuic或自行修改证书路径"
echo "放置后使用systemctl命令重启tuic服务"
