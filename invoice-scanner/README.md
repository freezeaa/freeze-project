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
pip install -r requirements.txt

# 启动服务
python3 app.py
```

服务启动后，本地访问：`http://localhost:5000`

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

## 项目结构

```
invoice-scanner/
├── app.py                 # Flask 后端
├── templates/
│   └── index.html         # 前端页面
├── static/
│   └── exports/           # 导出的 Excel 文件
├── cloudflared            # Cloudflare Tunnel 可执行文件
├── start.sh               # 一键启动脚本
├── requirements.txt       # Python 依赖
├── scanner.log            # 扫描日志（自动生成）
└── README.md
```
