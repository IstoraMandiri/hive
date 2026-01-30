#!/bin/bash

# Startup script to initialize and boot a Besu ETC peer instance.
#
# This script assumes the following files:
#  - `genesis.json` file is located at /genesis.json (mandatory)
#
# This script assumes the following environment variables:
#
#  - HIVE_BOOTNODE             enode URL of the remote bootstrap node
#  - HIVE_NETWORK_ID           network ID number to use for the eth protocol
#  - HIVE_CHAIN_ID             chain ID (61 for ETC mainnet)
#  - HIVE_NODETYPE             sync and pruning selector (archive, full, light)
#
# ETC Forks:
#
#  - HIVE_FORK_HOMESTEAD       block number for Homestead transition
#  - HIVE_FORK_TANGERINE       block number for TangerineWhistle (EIP-150)
#  - HIVE_FORK_SPURIOUS        block number for SpuriousDragon (EIP-155/158)
#  - HIVE_FORK_CLASSIC         block number for Classic fork (DAO rejection)
#  - HIVE_FORK_ECIP1015        block number for ECIP-1015
#  - HIVE_FORK_DIE_HARD        block number for Die Hard
#  - HIVE_FORK_GOTHAM          block number for Gotham
#  - HIVE_FORK_ECIP1041        block number for difficulty bomb defusal
#  - HIVE_FORK_ATLANTIS        block number for Atlantis (Byzantium equivalent)
#  - HIVE_FORK_AGHARTA         block number for Agharta (Constantinople equivalent)
#  - HIVE_FORK_PHOENIX         block number for Phoenix (Istanbul equivalent)
#  - HIVE_FORK_THANOS          block number for Thanos (ECIP-1099)
#  - HIVE_FORK_MAGNETO         block number for Magneto (Berlin equivalent)
#  - HIVE_FORK_MYSTIQUE        block number for Mystique (London equivalent)
#  - HIVE_FORK_SPIRAL          block number for Spiral (Shanghai equivalent)
#
# ETH fork names also supported for test compatibility:
#  - HIVE_FORK_BYZANTIUM, HIVE_FORK_CONSTANTINOPLE, HIVE_FORK_PETERSBURG
#  - HIVE_FORK_ISTANBUL, HIVE_FORK_BERLIN
#
# Clique PoA:
#
#  - HIVE_CLIQUE_PERIOD        enables clique support. value is block time in seconds.
#  - HIVE_CLIQUE_PRIVATEKEY    private key for clique mining
#
# Other:
#
#  - HIVE_MINER                enables mining. value is coinbase.
#  - HIVE_MINER_EXTRA          extra-data field to set for newly minted blocks
#  - HIVE_LOGLEVEL             Client log level
#  - HIVE_GRAPHQL_ENABLED      If set, GraphQL is enabled on port 8545 and RPC is disabled

set -e

besu=/opt/besu/bin/besu

# See https://github.com/hyperledger/besu/issues/1464
export BESU_OPTS="-Dsecp256k1.randomize=false"

# Use bonsai storage.
FLAGS="--data-storage-format=BONSAI"

# Configure logging.
LOG=info
case "$HIVE_LOGLEVEL" in
    0|1) LOG=ERROR ;;
    2)   LOG=WARN  ;;
    3)   LOG=INFO  ;;
    4)   LOG=DEBUG ;;
    5)   LOG=TRACE ;;
esac
FLAGS="$FLAGS --logging=$LOG --color-enabled=false"

# Configure the chain.
mv /genesis.json /genesis-input.json
jq -f /mapper.jq /genesis-input.json > /genesis.json
FLAGS="$FLAGS --genesis-file=/genesis.json "

# Dump genesis.
if [ "$HIVE_LOGLEVEL" -lt 4 ]; then
    echo "Supplied genesis state (trimmed, use --sim.loglevel 4 or 5 for full output):"
    jq 'del(.alloc[] | select(.balance == "0x123450000000000000000"))' /genesis.json
else
    echo "Supplied genesis state:"
    cat /genesis.json
fi


# Enable experimental 'berlin' hard-fork features if configured.
#if [ -n "$HIVE_FORK_BERLIN" ]; then
#    FLAGS="$FLAGS --Xberlin-enabled=true"
#fi

# The client should start after loading the blocks, this option configures it.
IMPORTFLAGS="--run"

# Skip PoW checks on import.
IMPORTFLAGS="$IMPORTFLAGS --skip-pow-validation-enabled"

# Load chain.rlp if present.
if [ -f /chain.rlp ]; then
    HAS_IMPORT=1
    IMPORTFLAGS="$IMPORTFLAGS --from=/chain.rlp"
fi

# Load the remaining individual blocks.
if [ -d /blocks ]; then
    HAS_IMPORT=1
    blocks=`echo /blocks/* | sort -n`
    # See https://github.com/hyperledger/besu/issues/1992#issuecomment-796528168
    # We import and run Besu in one go, to not have to instantiate the JRE twice.
    # However, besu has some special logic, and if only one file is imported, it
    # exits if that file fails to import.
    # Therefore, we append an extra (non-existent) file to the import.
    blocks="$blocks dummy"
    IMPORTFLAGS="$IMPORTFLAGS $blocks"
fi

if [ "$HIVE_BOOTNODE" == "" ]; then
    # Configure mining.
    if [ "$HIVE_MINER" != "" ]; then
        FLAGS="$FLAGS --miner-enabled --miner-coinbase=$HIVE_MINER"
        # For clique mining, besu uses the node key as the block signing key.
        if [ "$HIVE_CLIQUE_PRIVATEKEY" != "" ]; then
            echo "Importing clique signing key as node key..."
            echo "$HIVE_CLIQUE_PRIVATEKEY" > /opt/besu/key
        fi
    fi
fi
if [ "$HIVE_MINER_EXTRA" != "" ]; then
    FLAGS="$FLAGS --miner-extra-data=$HIVE_MINER_EXTRA"
fi
FLAGS="$FLAGS --min-gas-price=1 --tx-pool-price-bump=0 --rpc-gas-cap=50000000"

# Configure peer-to-peer networking.
if [ "$HIVE_BOOTNODE" != "" ]; then
    FLAGS="$FLAGS --bootnodes=$HIVE_BOOTNODE"
fi
if [ "$HIVE_NETWORK_ID" != "" ]; then
    FLAGS="$FLAGS --network-id=$HIVE_NETWORK_ID"
else
    FLAGS="$FLAGS --network-id=1337"
fi

# Configure sync mode
case "$HIVE_NODETYPE" in
    "" | "full" | "archive")
        syncmode=FULL ;;
    snap)
        syncmode=SNAP ;;
    *)
        echo "Unsupported HIVE_NODETYPE = $HIVE_NODETYPE"
        exit 1 ;;
esac
FLAGS="$FLAGS --sync-mode=$syncmode"

# Enable Snap Server.
FLAGS="$FLAGS --snapsync-server-enabled"

# Configure RPC.
RPCFLAGS="--host-allowlist=*"
if [ "$HIVE_GRAPHQL_ENABLED" == "" ]; then
    RPCFLAGS="$RPCFLAGS --rpc-http-enabled --rpc-http-api=DEBUG,TRACE,ETH,NET,WEB3,ADMIN --rpc-http-host=0.0.0.0"
else
    RPCFLAGS="$RPCFLAGS --graphql-http-enabled --graphql-http-host=0.0.0.0 --graphql-http-port=8545"
fi

# Enable WebSocket.
RPCFLAGS="$RPCFLAGS --rpc-ws-enabled --rpc-ws-api=DEBUG,TRACE,ETH,NET,WEB3,ADMIN --rpc-ws-host=0.0.0.0"

# Enable merge support if needed
if [ "$HIVE_TERMINAL_TOTAL_DIFFICULTY" != "" ]; then
    echo "0x7365637265747365637265747365637265747365637265747365637265747365" > /jwtsecret
    RPCFLAGS="$RPCFLAGS --engine-host-allowlist=* --engine-jwt-secret /jwtsecret"
fi

# Disable parallel transaction processing
if [ "$HIVE_PARALLEL_TX_PROCESSING_DISABLED" = "true" ]; then
    FLAGS="$FLAGS --bonsai-parallel-tx-processing-enabled=false"
fi

# Start Besu.
if [ -z "$HAS_IMPORT" ]; then
    cmd="$besu $FLAGS $RPCFLAGS"
else
    cmd="$besu $FLAGS $RPCFLAGS blocks import $IMPORTFLAGS"
fi
echo "starting main client: $cmd"
$cmd
