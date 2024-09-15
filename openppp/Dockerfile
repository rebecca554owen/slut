# 使用Ubuntu 24.04 作为基础镜像
FROM ubuntu:24.04 AS builder

# 阻止交互式提示
ARG DEBIAN_FRONTEND=noninteractive

# 设置工作目录
WORKDIR /env

# 更新系统并安装必要的构建工具和库
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    clang \
    cmake \
    curl \
    g++ \
    gcc \
    gdb \
    git \
    libicu-dev \
    libkrb5-dev \
    libssl-dev \
    libunwind8 \
    net-tools \
    openssl \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

# 设置Boost版本号变量
ARG BOOST_VERSION=1.86.0

# 下载并构建Boost
RUN BOOST_VERSION_UNDERSCORE=$(echo ${BOOST_VERSION} | sed 's/\./_/g') \
    && curl -L https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_UNDERSCORE}.tar.bz2 -o boost_${BOOST_VERSION_UNDERSCORE}.tar.bz2 \
    && tar xjf boost_${BOOST_VERSION_UNDERSCORE}.tar.bz2 \
    && rm boost_${BOOST_VERSION_UNDERSCORE}.tar.bz2 \
    && mv boost_${BOOST_VERSION_UNDERSCORE} boost \
    && cd boost \
    && ./bootstrap.sh \
    && ./b2 cxxflags=-fPIC \
    && cd ..

# 设置jemalloc版本号变量
ARG JEMALLOC_VERSION=5.3.0

# 下载并构建jemalloc
RUN curl -L https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2 -o jemalloc-${JEMALLOC_VERSION}.tar.bz2 \
    && tar xjf jemalloc-${JEMALLOC_VERSION}.tar.bz2 \
    && rm jemalloc-${JEMALLOC_VERSION}.tar.bz2 \
    && mv jemalloc-${JEMALLOC_VERSION} jemalloc \
    && cd jemalloc \
    && ./autogen.sh --with-jemalloc-prefix=je_ \
    && make -j$(nproc) \
    && cd ..

# 设置OpenSSL版本号变量
ARG OPENSSL_VERSION=3.3.2

# 下载并构建OpenSSL
RUN curl -L https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz -o openssl-${OPENSSL_VERSION}.tar.gz \
    && tar zxvf openssl-${OPENSSL_VERSION}.tar.gz \
    && rm openssl-${OPENSSL_VERSION}.tar.gz \
    && mv openssl-${OPENSSL_VERSION} openssl \
    && cd openssl \
    && ./Configure \
    && make -j$(nproc) \
    && cd ..

ENV THIRD_PARTY_LIBRARY_DIR=/env

# 克隆openppp2仓库，并构建openppp2
RUN git clone --depth=1 https://github.com/liulilittle/openppp2.git $THIRD_PARTY_LIBRARY_DIR/openppp2 && \
    sed -i 's|SET(THIRD_PARTY_LIBRARY_DIR /root/dev)|SET(THIRD_PARTY_LIBRARY_DIR '"$THIRD_PARTY_LIBRARY_DIR"')|' $THIRD_PARTY_LIBRARY_DIR/openppp2/CMakeLists.txt && \
    cd $THIRD_PARTY_LIBRARY_DIR/openppp2 && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    chmod +x ../bin/ppp

# 准备最终镜像 22.04 23.10
FROM ubuntu:latest
# 设置工作目录
WORKDIR /openppp2
# 复制构建好的应用到最终镜像
COPY --from=builder /env/openppp2/bin /openppp2
# 安装运行时依赖，并配置系统环境
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl dnsutils iptables iproute2 iputils-ping lsof net-tools netperf tzdata unzip vim && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    rm -rf /var/lib/apt/lists/*

# 设置启动脚本为容器启动时运行的命令
ENTRYPOINT ["/openppp2/ppp"]
