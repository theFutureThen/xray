# 【超详细】十分钟，小白也能科学上网（Vultr部署VPS + 启动Xray服务 + 客户端使用）
> 教您如何在 VPS 上部署一个科学上网服务，安全、快速，还能扫码直接使用！
> 不懂代码？不懂 Linux？没关系！跟着我一步一步来就行！

> 技术点：[xray](https://github.com/XTLS/Xray-core) + [reality](https://github.com/XTLS/REALITY)
> 服务器：[Vultr](https://www.vultr.com/?ref=7039524)

## 准备 VPS（国外服务器）（约 6 分钟）

> 注册 2 分钟，付费 0.5 分钟，部署&等待 2.5 分钟
> 

在开始之前，您需要准备一台国外 VPS。如果没有则需要购买国外 VPS，推荐 [Vultr](https://www.vultr.com/?ref=7039524)，可以按小时计费。（[限时消费\$100送\$300](https://www.vultr.com/?ref=7039524)）

#### 付费

> 支持支付宝，目前最低充值`$10`

![](/screenshot/pay.png)


#### 部署（以 debian 为例）

> 服务器最低消费 `$3.5/月`，连接设备数量不限

注意：选择带 ipv4 的服务器

![](/screenshot/delpoy_0.png)![](/screenshot/delpoy_1.png)![](/screenshot/delpoy_2.png)![](/screenshot/delpoy_3.png)![](/screenshot/delpoy_4.png)

---

## 🔧 安装——VPS 启动服务（约 2 分钟）

- **Windows**，使用 `PowerShell`（系统自带，小白推荐），也可以使用 `xshell` 或 `putty` 等
- **Mac** 或 **Linux**， 使用`终端`（系统自带，小白推荐），也可以使用 `iTerm2` 等

### 第一步：登录 VPS

假设您的 VPS IP 是 `45.77.96.59`，用户名是 `root`，输入以下命令：

```bash
ssh root@45.77.96.59
```

第一次登录会问您是否信任服务器，输入 `yes` 回车即可。

之后将系统给的密码复制过来进行粘贴，粘贴操作是不允许看到密码的，粘贴完直接回车即可。


### 第二步：执行一键安装脚本

复制下面这段命令并粘贴，按回车执行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/theFutureThen/xray/refs/heads/main/install.sh)
```
![](/screenshot/terminal_0.png)

---

### 安装完成后会显示什么？

如果一切顺利，您会看到：

✅ 安装完成

🌐 您的连接地址（一个 `vless://` 开头的链接）

📱 终端二维码，手机可以直接扫码添加

示例截图如下：

![](/screenshot/terminal_1.png)

---

## 使用——下载客户端&启动（约 2 分钟）

推荐使用 **[v2rayN（Windows/Mac OS）](https://github.com/2dust/v2rayn/releases)** 或 **[Shadowrocket（iOS）](https://apps.apple.com/us/app/shadowrocket/id932747118)**、**[v2rayNG（安卓）](https://github.com/2dust/v2rayNG/releases)**

注意：mac os 提示包损坏，请在终端执行
```
sudo xattr -r -d com.apple.quarantine  /Applications/v2rayN.app
```

### 添加方式一：复制链接

将终端显示的 `vless://...` 链接复制粘贴到您的客户端中添加即可。

### 添加方式二：扫码导入

直接打开客户端的二维码扫描功能，对着终端中的二维码扫一扫，自动添加配置。


---

## ❓ 常见问题

**Q1：我从来没用过 Linux，这看得懂吗？**

A：教程写得就是给您这样的朋友看的，复制粘贴命令就能跑，不需要您写代码！

**Q2：脚本包括哪些功能？**

A：包括以下功能：
- 安装 Xray 主程序
- 配置好 Reality（这是一个更隐秘安全的协议）
- 自动生成密钥和用户 ID
- 配置防火墙
- 启用 BBR 加速（让网络更快）
- 最后生成一个连接二维码，手机一扫就能用！

**Q3：可以不用脚本自己动手么？**

A：当然可以，如果您是专业人士，可以参考以下步骤（上述脚本的核心）：
```
# 安装 xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 生成 uuid
xray uuid 
# 471aff3e-215a-4d7e-9cef-9acf96e5df86
# 生成 reality 公钥私钥
xray x25519
# Private key: 2CO4wUWPPutsIaDzV2S6FQ3Xqr6LoAC4cpO5LOPcWVo
# Public key: Rh1r6-IevftPnt3-XUKW_8po0T3RBWsUI9eo1zhfdUU

# 编辑配置
vi /usr/local/etc/xray/config.json
# 粘贴以下内容
{
  "inbounds": [
    {
      "port": 1225,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "471aff3e-215a-4d7e-9cef-9acf96e5df86",
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
          "dest": "www.apple.com:443",
          "xver": 0,
          "serverNames": [
            "www.apple.com"
          ],
          "privateKey": "2CO4wUWPPutsIaDzV2S6FQ3Xqr6LoAC4cpO5LOPcWVo",
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

# 禁用防火墙
ufw disable

# 重启
systemctl restart xray

# 客户端部分
vless://471aff3e-215a-4d7e-9cef-9acf96e5df86@45.77.96.59:1225?flow=xtls-rprx-vision&encryption=none&security=reality&sni=www.apple.com&pbk=Rh1r6-IevftPnt3-XUKW_8po0T3RBWsUI9eo1zhfdUU&fp=chrome#45.77.96.59
```


**Q4：能不能卸载？**

可以。您只需运行：

```bash
bash /usr/local/bin/xray uninstall
```

**Q5: 写作的动力？**

推广 vultr 获取点服务商的佣金

|[链接1：您消费\$10，送我\$10](https://www.vultr.com/?ref=7039524)|[链接2（限时有效）：您消费\$100，送您\$300，送我\$100](https://www.vultr.com/?ref=9643303-9J)|
|-|-|
|![](/screenshot/refer_1.png#pic_center=600*400)|![](/screenshot/refer_2.png#pic_center=600*400)|

---

## ❤️ 最后

这个教程是为完全没有经验的小白朋友写的，希望您能顺利完成部署。
