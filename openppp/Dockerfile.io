# 使用提前构建的 openppp2 镜像作为基础镜像
FROM rebecca554owen/openppp2:build

# 复制本地的 install.sh 到容器的 /tmp 目录
COPY openppp/install.sh /tmp/install.sh

# 合并所有的 RUN 指令为一个，以减少层数
RUN apt-get update && \
    apt-get install -y ca-certificates curl unzip && \
    update-ca-certificates && \
    chmod +x /tmp/install.sh && \
    sh /tmp/install.sh && \
    rm -rf /tmp/install.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 设置启动时的默认入口脚本
ENTRYPOINT ["/openppp2/entrypoint.sh"]
