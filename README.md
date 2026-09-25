# Debian 12 / 13 标准安装镜像

本仓库提供 **Debian 官方标准安装镜像（netinst 网络安装版）**，方便自用/国内下载。
镜像均来自 Debian 官方 [cdimage.debian.org](https://cdimage.debian.org/)，未做任何修改。

## 📥 下载
到本仓库 **[Releases](https://github.com/scaryburial/debian-images/releases/tag/debian-12.11.0_13.7.0)** 下载（含 `.sha512` 校验；另附官方 `SHA512SUMS.12/13`）：

| 版本 | 文件 | 大小 |
|---|---|---|
| Debian 13 (Trixie) | `debian-13.7.0-amd64-netinst.iso` | 约 756 MB |
| Debian 12 (Bookworm) | `debian-12.11.0-amd64-netinst.iso` | 约 670 MB |

> netinst = **网络安装版**：体积小，安装时需联网从 Debian 源拉取软件。
> 完整 DVD / 其它架构请到官方 cdimage 下载。

## ✅ 校验
```bash
sha512sum -c debian-13.7.0-amd64-netinst.iso.sha512
# 或用官方清单
sha512sum -c SHA512SUMS --ignore-missing
```

## ℹ️ 说明
- 官方源：https://cdimage.debian.org/
- 仅作镜像分发，版权归 Debian 项目所有，遵循其许可。

## 🔑 校验值（SHA512）

