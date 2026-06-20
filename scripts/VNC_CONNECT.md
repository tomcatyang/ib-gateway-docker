# IB Gateway VNC 连接说明

本文记录本项目 `ib-gateway-docker` 的 VNC 连接方式，用于进入 IBKR Gateway 图形界面检查 API 设置和未处理弹窗。

## 当前端口映射

`docker-compose.yml` 将 VNC 只绑定到服务器本机 localhost：

```text
127.0.0.1:5900 -> container:5900
```

因此不要直接从本地电脑连接 `服务器IP:5900`。如果 Docker 运行在远程服务器上，需要先建立 SSH 隧道。

## 查看 VNC 密码

VNC 密码来自 `.env`：

```bash
cd /home/dev/high-freq-trade-sys/ib-gateway-docker
grep '^VNC_SERVER_PASSWORD=' .env
```

如果该变量为空，VNC 服务不会启动。

## 本地电脑通过 SSH 隧道连接

在本地电脑打开一个终端，执行：

```bash
ssh -L 5900:127.0.0.1:5900 dev@服务器IP
```

如果使用 root 登录：

```bash
ssh -L 5900:127.0.0.1:5900 root@服务器IP
```

如果 SSH 使用自定义端口，例如 `2222`：

```bash
ssh -p 2222 -L 5900:127.0.0.1:5900 dev@服务器IP
```

保持这个 SSH 窗口打开，然后在本地 VNC Viewer 中连接：

```text
127.0.0.1:5900
```

或：

```text
localhost:5900
```

如果本地 `5900` 已被占用，可改用本地 `5901`：

```bash
ssh -L 5901:127.0.0.1:5900 dev@服务器IP
```

然后 VNC Viewer 连接：

```text
127.0.0.1:5901
```

## 服务端状态检查

在服务器上确认容器和 VNC 端口：

```bash
cd /home/dev/high-freq-trade-sys/ib-gateway-docker
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
timeout 2 bash -c '</dev/tcp/127.0.0.1/5900' && echo 'host vnc open'
```

在容器内确认 `x11vnc` 和 `Xvfb`：

```bash
docker exec algo-trader-ib-gateway-1 bash -lc \
  'ps -ef | grep -E "x11vnc|Xvfb" | grep -v grep'
```

确认 VNC 协议握手：

```bash
python - <<'PY'
import socket

s = socket.socket()
s.settimeout(3)
s.connect(("127.0.0.1", 5900))
print(repr(s.recv(64)))
s.close()
PY
```

正常会看到类似：

```text
b'RFB 003.008\n'
```

## 常见问题

- 直接连接 `服务器IP:5900` 失败：当前端口只绑定 `127.0.0.1`，需要 SSH 隧道。
- VNC Viewer 显示 connection refused：检查 SSH 隧道是否保持打开，或本地端口是否被占用。
- VNC Viewer 显示 authentication failed：检查 `.env` 中的 `VNC_SERVER_PASSWORD`。
- 本地 `5900` 被占用：使用 `ssh -L 5901:127.0.0.1:5900 ...`，VNC Viewer 连接 `127.0.0.1:5901`。

## IB Gateway API 检查项

进入 VNC 后，重点检查 IBKR Gateway：

- 是否存在未处理弹窗，例如 Warning、Incoming connection、API connection、Pending Tasks。
- 打开 `Configure` / `Global Configuration`，进入 `API -> Settings`。
- 确认 `Enable ActiveX and Socket Clients` 已勾选。
- paper 模式 Socket port 应为 `4002`。
- `Read-Only API` 不建议勾选，后续交易系统需要下单。
- Trusted IPs 至少包含 `127.0.0.1`。
- 保存配置时点击 `Apply` 和 `OK`。

