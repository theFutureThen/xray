#!/bin/bash

set -e

PORT=1225
SNI="www.apple.com"

# 检查并安装 curl
if ! command -v curl >/dev/null 2>&1; then
  echo "curl 未安装，尝试安装..."
  if [ -f /etc/debian_version ]; then
    apt update && apt install -y curl
  elif [ -f /etc/redhat-release ]; then
    yum install -y curl
  else
    echo "未知系统，请手动安装 curl"
    exit 1
  fi
fi

echo "安装 Xray..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

echo "生成 UUID..."
UUID=$(xray uuid)

echo "生成 Reality 密钥对..."
KEY_OUTPUT=$(xray x25519)
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "Private key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Public key" | awk '{print $3}')

# 获取公网 IP
IP=$(curl -s https://api.ipify.org)

echo "写入配置文件..."

CONFIG_PATH="/usr/local/etc/xray/config.json"

cat > "$CONFIG_PATH" <<EOF
{
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "$SNI:443",
          "xver": 0,
          "serverNames": [
            "$SNI"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            ""
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private",
          "geoip:cn"
        ],
        "outboundTag": "block"
      }
    ]
  },
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ]
}
EOF

echo "配置文件写入完成: $CONFIG_PATH"

echo "配置防火墙..."

# Ubuntu/Debian: ufw
if command -v ufw >/dev/null 2>&1; then
  echo "检测到 ufw，放行 $PORT/tcp..."
  ufw allow $PORT/tcp
  ufw reload

# CentOS/RHEL: firewalld
elif systemctl is-active firewalld >/dev/null 2>&1; then
  echo "检测到 firewalld，放行 $PORT/tcp..."
  firewall-cmd --permanent --add-port=$PORT/tcp
  firewall-cmd --reload

# fallback: iptables
elif command -v iptables >/dev/null 2>&1; then
  echo "使用 iptables 放行 $PORT/tcp..."
  iptables -C INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
else
  echo "未检测到已知防火墙系统，请手动确保端口 $PORT 已放行"
fi

echo "重启 Xray 服务..."
systemctl restart xray

VLESS_LINK="vless://$UUID@$IP:$PORT?flow=xtls-rprx-vision&encryption=none&security=reality&sni=$SNI&pbk=$PUBLIC_KEY&fp=chrome#$IP"

echo "✅ 安装完成"
echo "你的 VLESS Reality 链接如下："
echo "$VLESS_LINK"
