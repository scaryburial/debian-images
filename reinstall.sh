#!/bin/bash
# ============================================================
#  雷电面板 · 一键重装系统（Debian 12 / 13）
#  用法： bash <(curl -fsSL https://raw.githubusercontent.com/scaryburial/debian-images/main/reinstall.sh)
#
#  ⚠️ 危险：会【完全擦除】目标磁盘数据并重装系统，请务必先确认！
#  装完首次开机会自动安装「雷电面板」，root/SSH 密码默认 Xzc345963。
# ============================================================
set -e
[ "$(id -u)" = "0" ] || { echo "请用 root 运行"; exit 1; }

REPO_RAW="https://raw.githubusercontent.com/scaryburial/debian-images/main"
PANEL_INSTALL="https://raw.githubusercontent.com/scaryburial/leidian-panel/main/install.sh"
ROOT_PASS="Xzc345963"

echo "============================================================"
echo " 一键重装系统（会清空整盘数据！）"
echo "   1) Debian 13 (Trixie)    [默认 · 30 秒后自动选择]"
echo "   2) Debian 12 (Bookworm)"
echo "============================================================"
ANS=""
read -t 30 -p "请选择要安装的系统 [1/2]（默认 1 = Debian 13）: " ANS || true
case "$ANS" in
  2) VER="12" ;;
  *) VER="13" ;;
esac

case "$VER" in
  12)
    KERNEL_URL="https://mirrors.tuna.tsinghua.edu.cn/debian/dists/bookworm/main/installer-amd64/current/images/netboot/debian-installer/amd64"
    PRESEED_URL="${REPO_RAW}/preseed-12.cfg"
    ;;
  *)
    KERNEL_URL="https://mirrors.tuna.tsinghua.edu.cn/debian/dists/stable/main/installer-amd64/current/images/netboot/debian-installer/amd64"
    PRESEED_URL="${REPO_RAW}/preseed-13.cfg"
    ;;
esac

echo "> 已选择：Debian $VER"

# --- 目标磁盘自动探测 ---
DISK="$(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}' | head -1)"
[ -n "$DISK" ] || { echo "未找到磁盘，退出"; exit 1; }

echo "------------------------------------------------------------"
echo " ⚠️  即将【完全擦除】磁盘 ${DISK} 并重装 Debian ${VER}"
echo "     装完后 root/SSH 密码：${ROOT_PASS}"
echo "     首次开机会自动安装雷电面板。"
echo "------------------------------------------------------------"
read -p "确认无误请输入 yes 继续（其它任意键取消）: " OK
[ "$OK" = "yes" ] || { echo "已取消。"; exit 1; }

# --- 依赖 ---
export DEBIAN_FRONTEND=noninteractive
if ! command -v kexec >/dev/null 2>&1; then
  echo "> 安装 kexec-tools…"
  (apt-get update -y && apt-get install -y kexec-tools) || { echo "安装 kexec-tools 失败"; exit 1; }
fi

# --- 下载安装内核 ---
mkdir -p /tmp/debi && cd /tmp/debi
echo "> 下载安装内核…"
curl -fL -o linux    "${KERNEL_URL}/linux"
curl -fL -o initrd.gz "${KERNEL_URL}/initrd.gz"

# --- kexec 引导进入自动安装 ---
CMDLINE="auto=true priority=critical preseed/url=${PRESEED_URL} partman-auto/disk=${DISK} net.ifnames=0 biosdevname=0 console=tty0 console=ttyS0,115200"
echo "> kexec 引导：$CMDLINE"
kexec -l ./linux --initrd=./initrd.gz --command-line="$CMDLINE"

echo "> 3 秒后用 kexec 直接启动安装内核（约 10~20 分钟）。请通过商家控制台观察进度。"
sleep 3
# 必须用 kexec -e 直接引导已加载的安装内核；普通 reboot 会回到旧系统。
kexec -e
# 若上面的 kexec -e 未能接管（某些 VPS 会忽略），退回到普通重启：
systemctl reboot || reboot
