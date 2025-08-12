### Arch local devnet node (Docker)
One-container stack for local development:
- Bitcoin Core (regtest)
- Titan indexer
- Arch Local Validator

The container auto-initializes regtest (creates wallet, mines 101 blocks) and exposes the services on your host.

### Compatibility
- Containers are linux/amd64.
- Supported hosts:
  - Linux x86_64 (Docker Engine)
  - macOS (Apple Silicon or Intel) with Docker Desktop (amd64 emulation is used automatically)
  - Windows 11/10 with WSL2 + Docker Desktop
- Not supported: native ARM Linux (aarch64) or other architectures without amd64 emulation.

### Prerequisites
- Docker (Engine 20.10+ or Desktop 4.x+)
- Docker Compose v2 (`docker compose`)
- Open ports: 18443, 3030, 9002
- Recommended: ≥8 GB RAM available, ≥10 GB free disk

### Option A — Run prebuilt image (fastest)
```bash
docker pull --platform linux/amd64 baptisteeb/arigato-node:latest
docker run -d \
  --platform linux/amd64 \
  --name autara-arch-local-node \
  -p 18443:18443 -p 3030:3030 -p 9002:9002 \
  -v autara_arch_local_validator_data:/validator_data \
  baptisteeb/arigato-node:latest
```

### Option B — Build locally
```bash
docker compose build
docker compose up -d
```

### Component versions and build date
- Bitcoin Core: pinned to v28.0 (see `Dockerfile`)
- Titan: built from `saturnbtc/Titan` at image build time (HEAD) - rune-indexer 0.1.0
- Arch Local Validator: latest release at image build time (HEAD) - local_validator 0.5.5

Get exact versions from a running container inside the docker:
```bash
# Bitcoin Core
bitcoind -version

# Titan (tries --version, falls back to first help line)
/validator_data/titan --version

# Arch Local Validator
/validator_data/arch_local_validator/local_validator --version

# Image build timestamp (UTC)
docker inspect -f '{{.Created}}' arch-local-validator-node | sed 's/T/ /; s/\.\{0,\}Z$//'
```

### Stop and cleanup
```bash
# If using Compose
docker compose down -v

# If using the prebuilt image directly
docker rm -f arch-local-node
```

### Defaults and ports
- Bitcoin RPC (regtest): `localhost:18443`
- Titan API: `localhost:3030`
- Arch Validator RPC: `localhost:9002`
- Data persisted in Docker volume: `arch_local_validator_data`
- Dev-only Bitcoin RPC creds (see `bitcoin.conf`): user `Autara-Finance`, password `Autara-Finance0`

Note: This setup is for local development/regtest only and is not intended for production.