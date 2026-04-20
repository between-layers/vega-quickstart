# syntax=docker/dockerfile:1
#
# RISC-V VEGA development environment
#
# BUILD:
#   docker build -t vega -f Containerfile .
#
# RUN:
#   docker run --rm -it -v "$(pwd)":/work vega
#
# TODO: host Docker container image on GitHub (ghcr.io), see how CHERIoT does it:
# https://github.com/orgs/CHERIoT-Platform/packages/container/package/devcontainer

ARG RENODE_DEST_BUILDER=/opt/renode/
ARG RENODE_VERSION=1.16.1
ARG RENODE_URL=https://github.com/renode/renode/releases/download/v${RENODE_VERSION}/renode-${RENODE_VERSION}.linux-dotnet.tar.gz

# ============================================================
# Stage 1: Download pre-built Renode runtime
# ============================================================
FROM ubuntu:24.04 AS renode-builder
ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

ARG RENODE_URL

RUN apt-get update && \
    apt-get install -y --no-install-recommends sudo ca-certificates wget

RUN wget ${RENODE_URL} -O /opt/renode.tar.gz

RUN tar -vxf /opt/renode.tar.gz -C /opt

# ============================================================
# Stage 2: Build RISC-V GNU Toolchain (rv32i / newlib)
# ============================================================
FROM ubuntu:24.04 AS riscv-builder
ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/open-isa-org/open-isa.org/releases/download/1.0.0/Toolchain_Linux.tar.gz

RUN mkdir -p /opt/riscv32i && \
    tar xvzf Toolchain_Linux.tar.gz && \
    tar xvzf riscv32-unknown-elf-gcc.tar.gz --strip-components=1 -C /opt/riscv32i && \
    tar xvzf openocd.tar.gz -C /opt/riscv32i/bin

# ============================================================
# Final image
# ============================================================
FROM mcr.microsoft.com/dotnet/runtime:8.0-noble
ENV DEBIAN_FRONTEND=noninteractive TZ=UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo make git vim telnet minicom \
        libmpc-dev libusb-1.0-0 libncurses6 \
        locales wget perl python3 \
    && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure locales \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Renode runtime (from stage 1)
ARG RENODE_DEST_BUILDER
ARG RENODE_VERSION
COPY --from=renode-builder /opt/renode_${RENODE_VERSION}--dotnet/ ${RENODE_DEST_BUILDER}
ENV PATH="${PATH}:${RENODE_DEST_BUILDER}"

# RISC-V toolchain (from stage 2)
COPY --from=riscv-builder /opt/riscv32i /opt/riscv32i
ENV PATH="${PATH}:/opt/riscv32i/bin"

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

RUN existing_user=$(getent passwd $USER_UID | cut -d: -f1) && \
    [ -n "$existing_user" ] && userdel -r "$existing_user" || true && \
    existing_group=$(getent group $USER_GID | cut -d: -f1) && \
    [ -n "$existing_group" ] && groupdel "$existing_group" || true && \
    groupadd --gid $USER_GID $USERNAME && \
    useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

ARG WORKSPACE
ENV WORKSPACE $WORKSPACE
