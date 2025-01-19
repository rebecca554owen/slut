FROM ghcr.io/rebecca554owen/openppp2:base AS boost-builder

# 设置工作目录与base镜像一致
WORKDIR /opt

# 设置Boost版本号变量
ARG BOOST_VERSION=1.86.0

# 下载并构建Boost
RUN BOOST_VERSION_UNDERSCORE=$(echo ${BOOST_VERSION} | sed 's/\./_/g') \
    && curl -L https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_UNDERSCORE}.tar.bz2 -o boost_${BOOST_VERSION_UNDERSCORE}.tar.bz2 \
    && tar xjf boost_${BOOST_VERSION_UNDERSCORE}.tar.bz2 \
    && rm boost_${BOOST_VERSION_UNDERSCORE}.tar.bz2 \
    && mv boost_${BOOST_VERSION_UNDERSCORE} boost \
    && cd boost \
    && ./bootstrap.sh \
    && ./b2 cxxflags=-fPIC \
    && cd ..