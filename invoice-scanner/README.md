# 发票扫码助手

手机扫描发票二维码，自动识别发票号码、金额、日期，支持导出 Excel。

## 功能

- **扫码识别** — 手机摄像头扫描发票二维码，自动解析发票号码、金额、开票日期
- **重复检测** — 根据发票号码判重，重复发票弹窗确认是否保存
- **本地缓存** — 数据存储在手机浏览器 localStorage，刷新页面不丢失
- **导出 Excel** — 一键导出为 `.xlsx` 文件，包含发票号码、金额、开票日期三列
- **单条删除 / 一键清空** — 灵活管理发票列表
- **公网访问** — 通过 Cloudflare Tunnel 免费获取 HTTPS 公网地址，手机直接访问

## 快速启动

### 方式一：一键启动（推荐）

```bash
cd invoice-scanner
bash start.sh
```

脚本会自动创建虚拟环境、安装依赖、启动 Flask 服务和公网隧道。

### 方式二：手动启动

```bash
cd invoice-scanner

# 创建虚拟环境并安装依赖（首次）
python3 -m venv venv
source venv/bin/activate
python -m pip install -r requirements.txt

# 启动服务
python app.py
```

服务启动后，本地访问：`http://localhost:5000`

### 方式三：服务器生产启动

```bash
cd invoice-scanner
python3 -m venv venv
./venv/bin/python -m pip install -r requirements.txt
bash scripts/run_server.sh
```

这条命令会用 Gunicorn 在 `127.0.0.1:5000` 启动，适合放在 Nginx 后面。

## 获取公网访问地址

项目目录下已包含 `cloudflared` 可执行文件，无需额外安装。

**启动隧道（新开一个终端）：**

```bash
cd invoice-scanner
./cloudflared tunnel --url http://localhost:5000
```

终端会输出类似以下内容：

```
Your quick Tunnel has been created! Visit it at:
https://xxx-yyy-zzz.trycloudflare.com
```

复制这个 HTTPS 地址，在手机浏览器（Safari / Chrome）中打开即可使用。

**注意事项：**
- 地址自带 HTTPS，iOS Safari 可以正常调用摄像头
- 不需要域名、不需要注册账号，完全免费
- 每次重启 `cloudflared` 会生成新的随机地址
- 只要不关闭 `cloudflared` 进程，地址就一直有效

## iOS 导出说明

iOS Safari 会在页面内预览 Excel 文件（而不是直接下载）。查看预览后：
- 点击右上角 **分享按钮** → 选择 **"用 WPS 打开"** 或 **"存储到文件"**

Android 浏览器会直接触发下载。

## 技术栈

| 组件 | 说明 |
|------|------|
| Flask | Python 轻量 Web 框架，提供页面和 Excel 导出接口 |
| html5-qrcode | 前端二维码识别库，手机本地解码 |
| Tailwind CSS | CSS 框架（CDN 引入） |
| openpyxl | Python Excel 文件生成库 |
| Cloudflare Tunnel | 免费公网隧道，提供 HTTPS 访问 |

## 服务器部署（Nginx + 域名）

如果准备把项目迁到服务器，并通过正式域名访问，推荐结构：

```text
域名
  -> Nginx
  -> 127.0.0.1:5000
  -> Gunicorn
  -> Flask app
```

### 需要准备什么

- 一台 Linux 服务器（推荐 Ubuntu）
- 域名已经解析到服务器公网 IP
- 服务器已安装：`python3`、`python3-venv`、`nginx`、`git`
- 后续如需 HTTPS，可再安装 `certbot`

### 仓库里已经提供的生产部署文件

- `scripts/run_server.sh`：生产启动脚本，运行 Gunicorn
- `deploy/server.env.example`：环境变量示例
- `deploy/invoice-scanner.service.example`：systemd 服务示例
- `deploy/nginx.invoice-scanner.conf.example`：Nginx 配置示例

### 部署步骤示例

```bash
cd /home/ubuntu
git clone https://github.com/freezeaa/freeze-project.git
cd freeze-project/invoice-scanner
python3 -m venv venv
./venv/bin/python -m pip install -r requirements.txt
cp deploy/server.env.example deploy/server.env
bash scripts/run_server.sh
```

### systemd 示例

把 `deploy/invoice-scanner.service.example` 复制到：

```bash
/etc/systemd/system/invoice-scanner.service
```

然后按实际部署目录修改里面的路径，再执行：

```bash
sudo systemctl daemon-reload
sudo systemctl enable invoice-scanner
sudo systemctl start invoice-scanner
sudo systemctl status invoice-scanner
```

### Nginx 示例

把 `deploy/nginx.invoice-scanner.conf.example` 复制到服务器，例如：

```bash
/etc/nginx/sites-available/invoice-scanner.conf
```

按你的正式域名把下面这项改掉：

```text
server_name invoice.example.com;
```

然后启用并重载：

```bash
sudo ln -s /etc/nginx/sites-available/invoice-scanner.conf /etc/nginx/sites-enabled/invoice-scanner.conf
sudo nginx -t
sudo systemctl reload nginx
```

### 后续如果要启 HTTPS

等域名解析已经生效后，可执行：

```bash
sudo certbot --nginx -d invoice.example.com
```

它会自动签证书并改好 Nginx 的 443 配置。

### 本地还能不能继续跑

可以。本地仍然继续用：

```bash
bash start.sh
```

也就是说：
- `start.sh` 继续服务本地开发 + Tunnel
- `scripts/run_server.sh` 专门服务服务器生产环境

## 导出文件定时清理

项目包含导出文件清理脚本，用于每天自动清理 `static/exports/`，只保留最新 20 个导出文件。

### 手动执行

```bash
cd invoice-scanner
bash scripts/run_cleanup.sh
```

### 系统 cron 配置示例

```cron
0 0 * * * /Users/jiebin.yu/test-yu/freeze-project/invoice-scanner/scripts/run_cleanup.sh >/dev/null 2>&1
```

### 后续如果迁移到云服务器，怎么改

只需要修改 cron 里这一段脚本绝对路径：

```cron
/Users/jiebin.yu/test-yu/freeze-project/invoice-scanner/scripts/run_cleanup.sh
```

比如项目以后部署到云服务器目录：

```cron
0 0 * * * /home/ubuntu/freeze-project/invoice-scanner/scripts/run_cleanup.sh >/dev/null 2>&1
```

`run_cleanup.sh` 会自动定位项目目录，并优先使用项目自己的 `venv/bin/python`，所以通常不需要再改脚本内部逻辑。

## 项目结构

```
invoice-scanner/
├── app.py                 # Flask 后端
├── templates/
│   └── index.html         # 前端页面
├── static/
│   └── exports/           # 导出的 Excel 文件
├── scripts/
│   ├── cleanup_exports.py # 清理导出文件，只保留最新 20 个
│   ├── run_cleanup.sh     # cron 调用入口脚本
│   └── run_server.sh      # Gunicorn 生产启动脚本
├── deploy/
│   ├── server.env.example                 # 服务器环境变量示例
│   ├── invoice-scanner.service.example    # systemd 示例
│   └── nginx.invoice-scanner.conf.example # Nginx 示例
├── cloudflared            # Cloudflare Tunnel 可执行文件
├── start.sh               # 一键启动脚本
├── requirements.txt       # Python 依赖
├── scanner.log            # 扫描日志（自动生成）
└── README.md
```
