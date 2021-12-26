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

# ################################ #
#  MobileCoin Consensus Validator  #
# ################################ #
FROM ubuntu:18.04 AS consensus

#
# This builds a slim runtime container based on Ubuntu 18.04 LTS for distribution of a MobileCoin Consensus Validator.
#
SHELL ["/bin/bash", "-c"]

RUN apt-get update -q -q && \
 apt-get upgrade --yes && \
 apt-get install --yes \
   gpg \
   wget \
   && \
 rm -rf /var/cache/apt && \
 rm -rf /var/lib/apt/lists/*

# Install SGX Ubuntu/Debian Repo
RUN source /etc/os-release && \
	wget "https://download.01.org/intel-sgx/sgx-linux/2.15/distro/ubuntu${VERSION_ID}-server/sgx_linux_x64_driver_2.11.0_2d2b795.bin" && \
	wget "https://download.01.org/intel-sgx/sgx-linux/2.15/distro/ubuntu${VERSION_ID}-server/sgx_linux_x64_sdk_2.15.100.3.bin" && \
	echo "deb [arch=amd64 signed-by=/usr/local/share/apt-keyrings/intel-sgx-archive-keyring.gpg] https://download.01.org/intel-sgx/sgx_repo/ubuntu/ ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/intel-sgx.list

RUN mkdir -p /usr/local/share/apt-keyrings && \
	wget -O /tmp/intel-sgx-deb.key https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key && \
	gpg -v --no-default-keyring --keyring /tmp/intel-sgx-archive-keyring.gpg \
		--import /tmp/intel-sgx-deb.key && \
	gpg -v --no-default-keyring --keyring /tmp/intel-sgx-archive-keyring.gpg \
		--export --output /usr/local/share/apt-keyrings/intel-sgx-archive-keyring.gpg && \
	rm /tmp/intel-sgx-archive-keyring.gpg && \
	rm /tmp/intel-sgx-deb.key

# Update OS and install deps
#
# - All of these are runtime dependencies of both aesm_service and mobilenode.
# - This is run as a one-off in order to reduce the number of layers in the resulting image
#
RUN apt-get update -q -q && \
 apt-get upgrade --yes && \
 apt-get install --yes \
  build-essential \
  ca-certificates \
  cmake \
  gettext \
  libc6 \
  libcurl4 \
  libgcc-7-dev \
  libgcc1 \
  libnghttp2-14 \
  libprotobuf-c1 \
  libprotobuf10 \
  libstdc++6 \
  libsgx-uae-service \
  rsync \
  sgx-aesm-service \
  supervisor \
  tar \
  zlib1g \
  && \
 rm -rf /var/cache/apt && \
 rm -rf /var/lib/apt/lists/*

# Add grpc_health_probe for healthcheck/liveness probes
RUN GRPC_HEALTH_PROBE_VERSION=v0.3.2 && \
    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
    chmod +x /bin/grpc_health_probe

WORKDIR /

COPY --from=builder target/release/libconsensus-enclave.signed.so /usr/bin/
COPY --from=builder target/release/consensus-service /usr/bin/
COPY --from=builder target/release/ledger-distribution /usr/bin/
COPY --from=builder target/release/mc-admin-http-gateway /usr/bin/
COPY --from=builder target/release/mc-ledger-migration /usr/bin/
COPY --from=builder target/release/mc-util-grpc-admin-tool /usr/bin/

# Q: Why not use NODE_LEDGER_DIR here?
# A: The ENV dictates where the app actually looks, and the ARG sets
#    the default ENV value, but the origin_data install dir should
#    remain constant, and image builds may make that location their
#    default. -- jmc
# ARG ORIGIN_DATA_DIR
# COPY ${ORIGIN_DATA_DIR}/ledger /var/lib/mobilecoin/origin_data

COPY ops/entrypoints/consensus_validator.sh /usr/bin/entrypoint.sh

# Set default NODE_LEDGER_DIR to use ORIGIN_DATA_DIR, but override if docker run if intent is to preserve origin
ENV NODE_LEDGER_DIR "/var/lib/mobilecoin/origin_data"

# Put arg and env configuration at the end when possible to improve use of docker layer caching
ENV NODE_MANAGEMENT_PORT 8000
ENV NODE_CLIENT_PORT 3223
ENV NODE_CONSENSUS_PORT 8443
ARG BRANCH
ENV BRANCH "${BRANCH}"
#ARG AWS_ACCESS_KEY_ID
#ENV AWS_ACCESS_KEY_ID "${AWS_ACCESS_KEY_ID}"
#ARG AWS_SECRET_ACCESS_KEY
#ENV AWS_SECRET_ACCESS_KEY "${AWS_SECRET_ACCESS_KEY}"
#ARG AWS_PATH
#ENV AWS_PATH "${AWS_PATH}"
ENV RUST_LOG "debug"
ENV RUST_BACKTRACE "full"
ENV RUST_LOG_STYLE "never"

EXPOSE $NODE_CLIENT_PORT
EXPOSE $NODE_CONSENSUS_PORT
EXPOSE $NODE_MANAGEMENT_PORT

ENTRYPOINT ["entrypoint.sh"]
