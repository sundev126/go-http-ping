# go-http-ping

一个极简 HTTP 探活服务。访问 `/ping` 返回纯文本 `ok`。

## 本地运行

```bash
go run . -ip 127.0.0.1 -port 47986
curl http://127.0.0.1:47986/ping

# 自定义返回内容
go run . -ip 127.0.0.1 -port 47986 -response "pong"
```

参数：

- `-ip`：监听 IP，默认 `0.0.0.0`
- `-port`：监听端口，默认 `47986`，有效范围 `1-65535`
- `-response`：访问 `/ping` 时返回的内容，默认 `ok`

## 构建

安装 [Task](https://taskfile.dev/) 后执行：

```bash
task
```

该命令在 `dist/` 下生成：

- `go-http-ping-linux-amd64`
- `go-http-ping-windows-amd64.exe`

也可分别执行 `task build:linux` 或 `task build:windows`。

## 发布

推送任意 Git tag 后，GitHub Actions 会自动构建 Linux amd64 和 Windows
amd64 程序，创建对应的 GitHub Release，并上传两个构建产物：

```bash
git tag v1.0.0
git push origin v1.0.0
```

## systemd 部署

在 Linux amd64 系统上可使用一键安装脚本安装最新 Release，并自动创建及
启动 systemd 服务：

```bash
curl -fsSL https://raw.githubusercontent.com/sundev126/go-http-ping/main/deploy/install.sh | sudo bash
```

如需安装指定版本：

```bash
curl -fsSL https://raw.githubusercontent.com/sundev126/go-http-ping/main/deploy/install.sh | sudo VERSION=v1.0.0 bash
```

程序默认安装到 `/opt/go-http-ping/go-http-ping`，监听
`0.0.0.0:47986`。安装完成后可通过以下命令检查：

```bash
systemctl status go-http-ping
curl http://127.0.0.1:47986/ping
```

一键卸载服务、程序及专用系统用户：

```bash
curl -fsSL https://raw.githubusercontent.com/sundev126/go-http-ping/main/deploy/uninstall.sh | sudo bash
```

也可以手动部署：

```bash
sudo useradd --system --user-group --no-create-home --shell /usr/sbin/nologin go-http-ping
sudo install -d -m 0755 /opt/go-http-ping
sudo install -m 0755 dist/go-http-ping-linux-amd64 /opt/go-http-ping/go-http-ping
sudo install -m 0644 deploy/go-http-ping.service /etc/systemd/system/go-http-ping.service
sudo systemctl daemon-reload
sudo systemctl enable --now go-http-ping
```

如需修改监听地址或端口，编辑 service 文件中的 `ExecStart`，然后运行：

```bash
sudo systemctl daemon-reload
sudo systemctl restart go-http-ping
```
