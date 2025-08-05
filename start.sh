#!/bin/bash
set -e

# Memory management settings
export MALLOC_ARENA_MAX=2
export MALLOC_MMAP_THRESHOLD_=131072
export MALLOC_TRIM_THRESHOLD_=131072
export MALLOC_TOP_PAD_=131072

# Rust memory settings for Titan
export RUST_MIN_STACK=8388608  # 8MB stack
export RUST_BACKTRACE=1
export RUST_LOG=info

# Ensure data directories exist
mkdir -p /validator_data/bitcoin /validator_data/titan_data /validator_data/arch_data

# Start Bitcoin Core
echo "Starting Bitcoin Core..."
bitcoind -daemon

# Wait for Bitcoin Core to be ready
echo "Waiting for Bitcoin Core to initialize..."
while ! bitcoin-cli -regtest getblockchaininfo >/dev/null 2>&1; do
    sleep 2
done

# Create wallet if it doesn't exist
if ! bitcoin-cli -regtest listwallets 2>/dev/null | grep -q "arigato_bitcoin_regtest"; then
    if ! ls /validator_data/bitcoin/regtest/wallets/arigato_bitcoin_regtest* >/dev/null 2>&1; then
        bitcoin-cli -regtest createwallet "arigato_bitcoin_regtest"
    else
        bitcoin-cli -regtest loadwallet "arigato_bitcoin_regtest"
    fi
fi

# Generate some blocks for regtest
ADDRESS=$(bitcoin-cli -regtest getnewaddress)
bitcoin-cli -regtest generatetoaddress 101 $ADDRESS

echo "Bitcoin Core ready and initialized"

# Start Titan
echo "Starting Titan..."
cd /validator_data
./titan \
    --bitcoin-rpc-url http://127.0.0.1:18443 \
    --bitcoin-rpc-username Autara-Finance \
    --bitcoin-rpc-password Autara-Finance0 \
    --chain regtest \
    --index-addresses \
    --index-bitcoin-transactions \
    --enable-tcp-subscriptions \
    --data-dir /validator_data/titan_data \
    --main-loop-interval 0 &

TITAN_PID=$!

# Wait for Titan to be ready
echo "Waiting for Titan to initialize..."
while ! curl -s http://127.0.0.1:3030/status >/dev/null 2>&1; do
    sleep 2
done

echo "Titan ready"

# Start Arch Local Validator
echo "Starting Arch Local Validator..."
cd /validator_data/arch_local_validator
./local_validator \
    --data-dir /validator_data/arch_data \
    --network-mode devnet \
    --rpc-bind-ip 0.0.0.0 \
    --rpc-bind-port 9002 \
    --titan-endpoint http://127.0.0.1:3030 &

VALIDATOR_PID=$!

# Wait for validator to be ready
echo "Waiting for Arch Validator to initialize..."
sleep 10

echo "All services started successfully!"
echo "Bitcoin Core RPC: http://localhost:18443"
echo "Titan: http://localhost:3030"
echo "Arch Validator: http://localhost:9002"

# Keep container running and handle shutdown gracefully
cleanup() {
    echo "Shutting down services..."
    kill $VALIDATOR_PID 2>/dev/null || true
    kill $TITAN_PID 2>/dev/null || true
    bitcoin-cli -regtest stop 2>/dev/null || true
    wait
    exit 0
}

trap cleanup SIGTERM SIGINT

# Wait for processes to finish
wait $VALIDATOR_PID