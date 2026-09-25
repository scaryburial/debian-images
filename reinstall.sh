#!/bin/bash
# ============================================================
#  雷电面板 · 一键重装系统（Debian 12 / 13）
#  bash <(curl -fsSL https://cdn.jsdelivr.net/gh/scaryburial/debian-images@main/reinstall.sh)
#
#  ⚠️ 会【完全擦除】目标磁盘数据。装完自动安装雷电面板，
#     root/SSH 密码默认 Xzc345963。
#  引导方式：优先 kexec -e，失败则退回 GRUB 一次性启动。
# ============================================================
set -e
[ "$(id -u)" = "0" ] || { echo "请用 root 运行"; exit 1; }

CLOUD_BASE="https://cdn.jsdelivr.net/gh/scaryburial/debian-images@main"   # 国内更易访问
RAW_BASE="https://raw.githubusercontent.com/scaryburial/debian-images/main"

echo "============================================================"
echo " 一键重装系统（会清空整盘数据！）"
echo "   1) Debian 13 (Trixie)    [默认 · 30 秒后自动选择]"
echo "   2) Debian 12 (Bookworm)"
echo "============================================================"
ANS=""
read -t 30 -p "请选择要安装的系统 [1/2]（默认 1 = Debian 13）: " ANS || true
case "$ANS" in
  2) VER="12"; SUITE="bookworm" ;;
  *) VER="13"; SUITE="stable" ;;
esac

# 内核镜像多源（依次尝试）
KERNEL_MIRRORS=(
  "https://mirrors.tuna.tsinghua.edu.cn/debian/dists/${SUITE}/main/installer-amd64/current/images/netboot/debian-installer/amd64"
  "https://mirrors.huaweicloud.com/debian/dists/${SUITE}/main/installer-amd64/current/images/netboot/debian-installer/amd64"
  "https://mirrors.ustc.edu.cn/debian/dists/${SUITE}/main/installer-amd64/current/images/netboot/debian-installer/amd64"
  "https://deb.debian.org/debian/dists/${SUITE}/main/installer-amd64/current/images/netboot/debian-installer/amd64"
)
# preseed 地址（CDN 优先，raw 兜底）
PRESEED_CDN="${CLOUD_BASE}/preseed-${VER}.cfg"
PRESEED_RAW="${RAW_BASE}/preseed-${VER}.cfg"

echo "> 已选择：Debian $VER"

# --- 目标磁盘 ---
echo "> 检测到的磁盘："
lsblk -dpno NAME,SIZE,TYPE | awk '$3=="disk"{print "    "$1"  "$2}'
DISK="$(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}' | head -1)"
[ -n "$DISK" ] || { echo "未找到磁盘，退出"; exit 1; }

echo "------------------------------------------------------------"
echo " ⚠️  即将【完全擦除】磁盘 ${DISK} 并重装 Debian ${VER}"
echo "     装完后 root/SSH 密码：Xzc345963；首次开机自动装雷电面板。"
echo "------------------------------------------------------------"
read -p "确认无误请输入 yes 继续（其它任意键取消）: " OK
[ "$OK" = "yes" ] || { echo "已取消。"; exit 1; }

# --- 预检：preseed 可达 ---
echo "> 预检 preseed 可达性…"
PRESEED=""
for u in "$PRESEED_CDN" "$PRESEED_RAW"; do
  if curl -fsSL --connect-timeout 15 -o /tmp/debi-preseed.cfg "$u" 2>/dev/null && [ -s /tmp/debi-preseed.cfg ]; then
    PRESEED="$u"; echo "  preseed OK: $u"; break
  fi
  echo "  preseed 不可用: $u"
done
[ -n "$PRESEED" ] || { echo "! 无法获取 preseed（CDN 与 raw 均失败）。可稍后重试，或用商家“自定义ISO/网络安装”手动装。"; exit 1; }

# --- 依赖 ---
export DEBIAN_FRONTEND=noninteractive
command -v curl >/dev/null 2>&1 || (apt-get update -y && apt-get install -y curl)

# --- 下载安装内核（多源） ---
mkdir -p /tmp/debi && cd /tmp/debi
got=0
for m in "${KERNEL_MIRRORS[@]}"; do
  echo "> 尝试镜像: $m"
  if curl -fL --connect-timeout 15 --retry 2 -o linux "$m/linux" && curl -fL --connect-timeout 15 --retry 2 -o initrd.gz "$m/initrd.gz"; then
    got=1; echo "  下载完成"; break
  fi
done
[ "$got" = 1 ] || { echo "! 安装内核下载失败，退出。"; exit 1; }

CMDLINE="auto=true priority=critical preseed/url=${PRESEED} partman-auto/disk=${DISK} net.ifnames=0 biosdevname=0 console=tty0 console=ttyS0,115200"

# --- DRYRUN：只做预检，不改动系统 ---
if [ "${DRYRUN:-0}" = "1" ]; then
  echo "> DRYRUN：预检通过（preseed 与内核均可获取，目标磁盘 ）。未做任何改动。"
  echo "  去掉 DRYRUN=1 即可正式执行。"
  exit 0
fi

# --- 方式一：kexec 直接引导 ---
if ! command -v kexec >/dev/null 2>&1; then
  echo "> 安装 kexec-tools…"; (apt-get update -y && apt-get install -y kexec-tools) || true
fi
if command -v kexec >/dev/null 2>&1; then
  echo "> 尝试 kexec -l 加载安装内核…"
  if kexec -l /tmp/debi/linux --initrd=/tmp/debi/initrd.gz --command-line="$CMDLINE"; then
    echo "> 加载成功。3 秒后用 kexec -e 直接启动安装内核…"
    sleep 3
    # kexec -e 成功则不再返回（直接进入安装器）
    kexec -e && true
    echo "! kexec -e 返回（可能被本机忽略），改走 GRUB 兜底。"
  else
    echo "! kexec -l 失败，改走 GRUB 兜底。"
  fi
else
  echo "! 无 kexec，改走 GRUB 兜底。"
fi

# --- 方式二：GRUB 一次性启动兜底 ---
echo "> GRUB 兜底：写入安装内核并设置下次启动项…"
if [ -d /boot ] && (command -v update-grub >/dev/null 2>&1 || command -v grub-mkconfig >/dev/null 2>&1); then
  cp -f /tmp/debi/linux /boot/debi-linux
  cp -f /tmp/debi/initrd.gz /boot/debi-initrd.gz
  cat > /etc/grub.d/40_custom <<GRUB
#!/bin/sh
exec tail -n +3 \$0
menuentry "Debian Installer (auto)" {
    linux /boot/debi-linux $CMDLINE
    initrd /boot/debi-initrd.gz
}
GRUB
  chmod +x /etc/grub.d/40_custom
  (command -v update-grub >/dev/null 2>&1 && update-grub) || grub-mkconfig -o /boot/grub/grub.cfg
  if command -v grub-reboot >/dev/null 2>&1; then
    grub-reboot "Debian Installer (auto)" && echo "> 已设置一次性启动项，3 秒后重启进入安装器…" && sleep 3 && reboot
    exit 0
  fi
fi

echo "! 两种引导方式都不可用（无 kexec 且无 GRUB）。未做任何改动，系统保持原样。"
echo "  可在商家控制台用『网络安装 / 自定义ISO』手动安装。"
exit 1
