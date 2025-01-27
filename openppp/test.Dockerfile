# 准备最终镜像
FROM ghcr.io/rebecca554owen/openppp2:env AS builder

# 设置工作目录为/opt
WORKDIR /opt

# 设置版本号和架构
ARG VERSION=latest
RUN ARCH=$(uname -m) && \
    BITS=$(getconf LONG_BIT) && \
    if [ "$ARCH" = "x86_64" ] && [ "$BITS" = "64" ]; then \
        ARCH_NORMAL="linux-amd64"; \
        ARCH_IO="linux-amd64-io-uring"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        ARCH_NORMAL="linux-aarch64"; \
        ARCH_IO="linux-aarch64-io-uring"; \
    elif [ "$ARCH" = "armv7l" ]; then \
        ARCH_NORMAL="linux-armv7l"; \
        ARCH_IO=""; \
    else \
        echo "不支持的架构: ${ARCH} 位数: ${BITS}"; \
        exit 1; \
    fi && \
    apt-get update && apt-get install -y wget && \
    # 下载正常版本
    if [ "$VERSION" = "latest" ]; then \
        wget "https://github.com/rebecca554owen/toys/releases/latest/download/openppp2-${ARCH_NORMAL}.zip" -O "/opt/openppp2-normal.zip"; \
    else \
        wget "https://github.com/rebecca554owen/toys/releases/download/${VERSION}/openppp2-${ARCH_NORMAL}.zip" -O "/opt/openppp2-normal.zip"; \
    fi && \
    # 如果存在io版本则下载
    if [ -n "$ARCH_IO" ]; then \
        if [ "$VERSION" = "latest" ]; then \
            wget "https://github.com/rebecca554owen/toys/releases/latest/download/openppp2-${ARCH_IO}.zip" -O "/opt/openppp2-io.zip" || echo "io版本不存在，跳过下载"; \
        else \
            wget "https://github.com/rebecca554owen/toys/releases/download/${VERSION}/openppp2-${ARCH_IO}.zip" -O "/opt/openppp2-io.zip" || echo "io版本不存在，跳过下载"; \
        fi; \
    fi

# 解压并配置可执行文件
RUN unzip /opt/openppp2-normal.zip -d /opt/ && \
    rm /opt/openppp2-normal.zip && \
    # 如果存在io版本且是有效的 ZIP 文件，则解压
    if [ -f "/opt/openppp2-io.zip" ]; then \
        if file "/opt/openppp2-io.zip" | grep -q "Zip archive data"; then \
            unzip /opt/openppp2-io.zip -d /opt/io/ && \
            rm -f /opt/openppp2-io.zip; \
        else \
            echo "openppp2-io.zip 不是有效的 ZIP 文件，删除它"; \
            rm -f /opt/openppp2-io.zip; \
        fi; \
    else \
        echo "openppp2-io.zip 不存在，跳过解压"; \
    fi && \
    chmod +x /opt/ppp && \
    if [ -f "/opt/io/ppp" ]; then \
        chmod +x /opt/io/ppp; \
    fi

ENV USE_IO=false

# 创建入口脚本
RUN echo '#!/bin/sh\n\
echo "检查IO版本可用性..."\n\
if [ -f /opt/io/ppp ] && [ "$USE_IO" = "true" ]; then\n\
    echo "检测到IO版本且USE_IO=true，使用IO版本启动"\n\
    exec /opt/io/ppp "$@"\n\
else\n\
    echo "使用标准版本启动"\n\
    exec /opt/ppp "$@"\n\
fi' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

# 设置入口点
ENTRYPOINT ["/entrypoint.sh"]
