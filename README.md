# Debian 12 / 13 标准安装镜像

本仓库提供 **Debian 官方标准安装镜像（netinst 网络安装版）**，方便自用/国内下载。
镜像均来自 Debian 官方 [cdimage.debian.org](https://cdimage.debian.org/)，未做任何修改。

## 下载
到本仓库 **[Releases](https://github.com/scaryburial/debian-images/releases)** 下载（含 `.sha512` 校验；另附官方 `SHA512SUMS.12/13`）：

| 版本 | 文件 | 大小 |
|---|---|---|
| Debian 13 (Trixie) | `debian-13.7.0-amd64-netinst.iso` | 约 756 MB |
| Debian 12 (Bookworm) | `debian-12.11.0-amd64-netinst.iso` | 约 670 MB |

> netinst = **网络安装版**：体积小，安装时需联网从 Debian 源拉取软件。
> 完整 DVD / 其它架构请到官方 cdimage 下载。

## 校验
```bash
sha512sum -c debian-13.7.0-amd64-netinst.iso.sha512
# 或用官方清单（只校验已下载的文件）
sha512sum -c SHA512SUMS.13 --ignore-missing
```

## 校验值（SHA512）
```
0921d8b297c63ac458d8a06f87cd4c353f751eb5fe30fd0d839ca09c0833d1d9934b02ee14bbd0c0ec4f8917dde793957801ae1af3c8122cdf28dde8f3c3e0da  debian-12.11.0-amd64-netinst.iso
ef04d0276850d70e4aaec0b55003628660e9631b26e35215a70ab3c8c707294a4b12731bc73c75a932902f703a7c278310ca99df28d6b36fb06d5618d8d0f678  debian-13.7.0-amd64-netinst.iso
```

## 说明
- 官方源：https://cdimage.debian.org/
- 仅作镜像分发，版权归 Debian 项目所有，遵循其许可。

---

## 一键重装系统（Debian 12 / 13）

在**目标服务器**上以 root 运行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/scaryburial/debian-images/main/reinstall.sh)
```

- 弹出菜单选择 **Debian 13（默认，30 秒无操作自动选它）** 或 **Debian 12**。
- 自动下载安装内核（netinst），用 kexec 引导进入**全自动安装**。
- 装完后：**root / SSH 密码 = `Xzc345963`**，并在**首次开机自动安装雷电面板**。

> ⚠️ **高风险**：本脚本会**完全擦除目标磁盘数据**并重装系统。
> - 需要服务器（VPS）支持 **kexec**；不同商家（KVM/OpenVZ 等）表现不同。
> - **请务必先在一台测试机上验证**，并确保有商家控制台可救急。
> - 运行时会要求输入 `yes` 二次确认。
