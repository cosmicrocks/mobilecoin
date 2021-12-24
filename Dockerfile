FROM gcr.io/mobilenode-211420/builder-install:1_24 AS builder

ENV PATH /root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/intel/sgxsdk/bin:/opt/intel/sgxsdk/bin/x64
ENV RUST_BACKTRACE full

ENV SGX_MODE "HW"
ENV IAS_MODE "DEV"
ENV NETWORK "cd"
ENV DOCKER_OWNER "mobilecoin"
ENV CONSENSUS_NODE_DOCKER_REPO "node_hw"
ENV MOBILECOIND_DOCKER_REPO "mobilecoind"
ENV BOOTSTRAP_TOOLS_DOCKER_REPO "bootstrap-tools"
ENV TAG_VERSION "0.0.1"

COPY . .
RUN cargo build --release
RUN cargo build --release -p mc-mobilecoind --no-default-features
