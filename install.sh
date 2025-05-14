#!/bin/bash

set -e

# ========== 彩色输出 ==========
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

PORT=1225
SNI="www.apple.com"

# 检查并安装 curl
if ! command -v curl >/dev/null 2>&1; then
  echo -e "${YELLOW}curl 未安装，尝试安装...${RESET}"
  if [ -f /etc/debian_version ]; then
    apt update -y >/dev/null 2>&1
    apt install -y curl >/dev/null 2>&1
  elif [ -f /etc/redhat-release ]; then
    yum install -y curl >/dev/null 2>&1
  else
    echo -e "${RED}未知系统，请手动安装 curl${RESET}"
    exit 1
  fi
fi

echo -e "${GREEN}==> 安装 Xray...${RESET}"
bash -c "$(curl -fsSL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

echo -e "${GREEN}==> 生成 UUID...${RESET}"
UUID=$(xray uuid)

echo -e "${GREEN}==> 生成 Reality 密钥对...${RESET}"
KEY_OUTPUT=$(xray x25519)
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | grep "Private key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Public key" | awk '{print $3}')

IP=$(curl -s https://api.ipify.org)

echo -e "${GREEN}==> 写入配置文件...${RESET}"
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

echo -e "${GREEN}==> 配置防火墙...${RESET}"

# Ubuntu/Debian: ufw
if command -v ufw >/dev/null 2>&1; then
  ufw allow $PORT/tcp >/dev/null 2>&1
  ufw reload >/dev/null 2>&1

# CentOS/RHEL: firewalld
elif systemctl is-active firewalld >/dev/null 2>&1; then
  firewall-cmd --permanent --add-port=$PORT/tcp >/dev/null 2>&1
  firewall-cmd --reload >/dev/null 2>&1

# fallback: iptables
elif command -v iptables >/dev/null 2>&1; then
  iptables -C INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
fi

echo -e "${GREEN}==> 重启 Xray 服务...${RESET}"
systemctl restart xray

# 构造链接
VLESS_LINK="vless://$UUID@$IP:$PORT?flow=xtls-rprx-vision&encryption=none&security=reality&sni=$SNI&pbk=$PUBLIC_KEY&fp=chrome#$IP"

# 安装 qrencode（静默）
if ! command -v qrencode >/dev/null 2>&1; then
  echo -e "${GREEN}==> 安装 qrencode 生成二维码...${RESET}"
  if [ -f /etc/debian_version ]; then
    apt update -y >/dev/null 2>&1
    apt install -y qrencode >/dev/null 2>&1 || echo -e "${RED}❌ 安装 qrencode 失败${RESET}"
  elif [ -f /etc/redhat-release ]; then
    yum install -y epel-release >/dev/null 2>&1
    yum install -y qrencode >/dev/null 2>&1 || echo -e "${RED}❌ 安装 qrencode 失败${RESET}"
  fi
fi

# 清屏再输出结果
clear
echo -e "${CYAN}✅ 安装完成${RESET}"
echo
echo -e "${YELLOW}你的 VLESS Reality 链接如下：${RESET}"
echo "$VLESS_LINK"
echo

# 输出二维码
if command -v qrencode >/dev/null 2>&1; then
  echo -e "${BLUE}📱 扫码导入配置：${RESET}"
  qrencode -t ANSIUTF8 "$VLESS_LINK"
else
  echo -e "${YELLOW}⚠️ 未安装 qrencode，无法生成二维码${RESET}"
fi
