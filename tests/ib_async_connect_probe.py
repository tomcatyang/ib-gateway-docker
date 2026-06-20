#!/usr/bin/env python3
"""使用 ib_async 验证 IB Gateway API 连接。

脚本只建立 API 连接并请求服务器时间，不会订阅行情，也不会提交订单。
"""

from __future__ import annotations

import argparse
import socket
import sys
import time
from dataclasses import dataclass


@dataclass(frozen=True)
class ProbeConfig:
    """连接探测参数。"""

    host: str
    port: int
    client_id: int
    timeout: float
    readonly: bool
    raw_handshake: bool


def parse_args() -> ProbeConfig:
    """解析命令行参数。"""

    parser = argparse.ArgumentParser(description="Probe IB Gateway with ib_async.")
    parser.add_argument("--host", default="127.0.0.1", help="IB Gateway host")
    parser.add_argument("--port", type=int, default=4002, help="IB Gateway API port")
    parser.add_argument("--client-id", type=int, default=9901, help="IB API clientId")
    parser.add_argument("--timeout", type=float, default=15.0, help="Connect timeout seconds")
    parser.add_argument(
        "--readonly",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Connect with IB readonly flag",
    )
    parser.add_argument(
        "--raw-handshake",
        action="store_true",
        help="Also send a low-level IB API handshake before ib_async connect",
    )
    args = parser.parse_args()
    return ProbeConfig(
        host=args.host,
        port=args.port,
        client_id=args.client_id,
        timeout=args.timeout,
        readonly=args.readonly,
        raw_handshake=args.raw_handshake,
    )


def run_raw_handshake(config: ProbeConfig) -> None:
    """发送 ib_async 相同格式的底层握手，辅助判断是否卡在 API 协议层。"""

    try:
        from ib_async import Client
    except ImportError as exc:
        raise RuntimeError("缺少 ib_async，请在仓库根目录使用 uv run 执行本脚本") from exc

    version = b"v%d..%d" % (Client.MinClientVersion, Client.MaxClientVersion)
    payload = b"API\0" + len(version).to_bytes(4, "big") + version
    print(f"raw_handshake_version={version.decode()}")

    sock = socket.socket()
    sock.settimeout(config.timeout)
    try:
        sock.connect((config.host, config.port))
        print(f"raw_tcp_connected host={config.host} port={config.port}")
        sock.sendall(payload)
        time.sleep(1)
        data = sock.recv(4096)
        print(f"raw_recv={data!r}")
    finally:
        sock.close()


def run_ib_async_probe(config: ProbeConfig) -> None:
    """通过 ib_async 连接 IB Gateway 并请求服务器时间。"""

    try:
        from ib_async import IB
    except ImportError as exc:
        raise RuntimeError("缺少 ib_async，请在仓库根目录使用 uv run 执行本脚本") from exc

    ib = IB()
    try:
        print(
            "ib_async_connect_start "
            f"host={config.host} port={config.port} client_id={config.client_id} "
            f"readonly={config.readonly} timeout={config.timeout}"
        )
        ib.connect(
            config.host,
            config.port,
            clientId=config.client_id,
            timeout=config.timeout,
            readonly=config.readonly,
        )
        print(f"ib_async_connected={ib.isConnected()}")

        # 服务器时间是最小只读请求，可验证 API 握手和请求响应链路。
        server_time = ib.reqCurrentTime()
        print(f"server_time={server_time}")
    finally:
        if ib.isConnected():
            ib.disconnect()
            print("ib_async_disconnected=true")


def main() -> int:
    """脚本入口。"""

    config = parse_args()
    try:
        if config.raw_handshake:
            run_raw_handshake(config)
        run_ib_async_probe(config)
    except Exception as exc:
        print(f"probe_failed type={type(exc).__name__} error={exc!r}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
