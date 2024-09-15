#!/bin/sh

# 获取系统架构信息
ARCH=$(uname -m)
echo "平台: ${ARCH}"

# 获取系统位数
BITS=$(getconf LONG_BIT)

# 根据架构信息设置下载路径
if [ "$ARCH" = "x86_64" ] && [ "$BITS" = "64" ]; then
  echo "架构: linux/amd64"
  ARCH="linux-amd64"
  DOWNLOAD_URL="https://github.com/liulilittle/openppp2/releases/latest/download/openppp2-linux-amd64-io-uring.zip"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
  echo "架构: linux/arm64"
  ARCH="linux-aarch64"
  DOWNLOAD_URL="https://github.com/liulilittle/openppp2/releases/latest/download/openppp2-linux-aarch64-io-uring.zip"
else
  echo "不支持的架构: ${ARCH} 位数: ${BITS}"
  exit 1
fi

echo "下载地址: ${DOWNLOAD_URL}"

# 下载最新的发布包到 /tmp
curl -L "$DOWNLOAD_URL" -o "/tmp/ppp.zip"

# 检查下载是否成功
if [ $? -ne 0 ]; then
  echo "下载失败，请检查下载链接或网络连接。"
  exit 1
fi

# 解压并安装到 /tmp
unzip /tmp/ppp.zip -d /tmp/

# 检查解压是否成功
if [ $? -ne 0 ]; then
  echo "解压失败，请检查压缩包是否完整。"
  exit 1
fi

# 确保 /openppp2 目录存在
if [ ! -d "/openppp2" ]; then
  mkdir /openppp2
  echo "/openppp2 目录已创建。"
fi

# 如果 /openppp2/ppp 文件存在，进行覆盖提示
if [ -f "/openppp2/ppp" ]; then
  echo "/openppp2/ppp 文件已存在，将进行覆盖。"
fi

# 将解压后的 ppp 文件复制到 /openppp2，强制覆盖已存在的文件
cp -f /tmp/ppp /openppp2/ppp

# 检查复制是否成功
if [ $? -ne 0 ]; then
  echo "复制文件失败，请检查目录权限。"
  exit 1
fi

# 赋予 ppp 可执行权限
chmod +x /openppp2/ppp

echo "ppp 已成功安装到 /openppp2/ppp"

# 删除临时文件
rm -rf /tmp/*

echo "安装完成，临时文件已删除。"
