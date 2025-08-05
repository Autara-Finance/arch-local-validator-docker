FROM debian:bookworm-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV RUST_LOG=info
ENV PATH="/root/.cargo/bin:$PATH"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    automake autotools-dev bsdmainutils build-essential \
    clang gcc git libboost-dev libboost-filesystem-dev \
    libboost-system-dev libevent-dev \
    libminiupnpc-dev libnatpmp-dev libsqlite3-dev libtool \
    libzmq3-dev pkg-config python3 curl ca-certificates libssl-dev \
    libjemalloc2 libjemalloc-dev&& \
    rm -rf /var/lib/apt/lists/*

# Set jemalloc as default allocator
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$HOME/.cargo/env" && \
    rustup install nightly && \
    rustup default nightly

# Create working directories
RUN mkdir -p /validator_data/

# Build Bitcoin Core
WORKDIR /validator_data
RUN git clone https://github.com/bitcoin/bitcoin.git && \
    cd bitcoin && \
    git checkout v28.0 && \
    ./autogen.sh && \
    ./configure \
    --disable-wallet-tool \
    --disable-tests \
    --disable-bench \
    --disable-gui \
    --disable-zmq \
    --without-miniupnpc \
    --without-natpmp \
    --with-incompatible-bdb \
    --enable-reduce-exports \
    --disable-ccache && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf bitcoin

# Build Titan
RUN git clone https://github.com/saturnbtc/Titan.git && \
    cd Titan && \
    cargo build --release -Znext-lockfile-bump && \
    cd .. && \
    mv Titan/target/release/titan titan && rm -rf Titan

# Download Arch Local Validator
RUN mkdir -p /validator_data/arch_local_validator && \
    cd /validator_data/arch_local_validator && \
    curl -LO "https://github.com/Arch-Network/arch-node/releases/latest/download/local_validator-x86_64-unknown-linux-gnu" && \
    chmod +x local_validator-x86_64-unknown-linux-gnu && \
    mv local_validator-x86_64-unknown-linux-gnu local_validator

# Copy configuration files
COPY start.sh /start.sh
RUN chmod +x /start.sh

COPY bitcoin.conf /root/.bitcoin/bitcoin.conf
# Expose ports
EXPOSE 18443 3030 9002

# Run the startup script
CMD ["/start.sh"]