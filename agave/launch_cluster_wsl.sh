#!/bin/bash
set -e

WORKDIR=~/sol/ex
LEDGER=~/sol/ex/solana-ledger
LOGDIR=~/sol/ex/logs
mkdir -p "$LOGDIR"
cd "$WORKDIR"

IDENTITY_KEY="validator-identity-keypair.json"
VOTE_KEY="validator-vote-keypair.json"
STAKE_KEY="validator-stake-keypair.json"

FIRST_VALIDATOR_PUBKEY=""

echo "==== Using persistent keypairs ===="
if [[ ! -f "$IDENTITY_KEY" ]]; then
    solana-keygen new -o "$IDENTITY_KEY"
fi
if [[ ! -f "$VOTE_KEY" ]]; then
    solana-keygen new -o "$VOTE_KEY"
fi
if [[ ! -f "$STAKE_KEY" ]]; then
    solana-keygen new -o "$STAKE_KEY"
fi

FIRST_VALIDATOR_PUBKEY=$(solana-keygen pubkey "$IDENTITY_KEY")

echo "==== Reusing genesis if exists ===="
if [[ ! -d "$LEDGER" ]]; then
    echo "No ledger found. Creating genesis."
    solana-genesis \
	--ledger "$LEDGER" \
	--hashes-per-tick sleep \
	--bootstrap-validator "$IDENTITY_KEY" "$VOTE_KEY" "$STAKE_KEY" \
	--bootstrap-validator-lamports 500000000000 \
	--bootstrap-validator-stake-lamports 250000000000 \
	--faucet-pubkey "$IDENTITY_KEY" \
	--faucet-lamports 1000000000000 \
	--cluster-type development \
	--fee-burn-percentage 0 \
	--rent-burn-percentage 0 \
	--target-lamports-per-signature 10000 \
	--target-signatures-per-slot 20000 \
	--ticks-per-slot 8 \
	--lamports-per-byte-year 3480 \
	--rent-exemption-threshold 2.0 \
	--max-genesis-archive-unpacked-size 1073741824 \
	--vote-commission-percentage 10
else
    echo "Ledger already exists. Skipping genesis."
fi

echo "==== Starting validator ===="
nohup agave-validator \
    --identity "$IDENTITY_KEY" \
    --vote-account "$VOTE_KEY" \
    --ledger "$LEDGER" \
    --require-tower \
    --rpc-port 8899 \
    --rpc-bind-address 0.0.0.0 \
    --rpc-faucet-address 127.0.0.1:9900 \
    --gossip-port 8001 \
    --dynamic-port-range 8000-8020 \
    --enable-rpc-transaction-history \
    --full-rpc-api \
    --no-port-check \
    --no-wait-for-vote-to-start-leader \
    --log "$LOGDIR/validator.log" > nohup.out 2>&1 &

echo "Starting solana-faucet (logs in $LOGDIR/faucet.log)"
nohup solana-faucet validator-identity-keypair.json > "$LOGDIR/faucet.log" 2>&1 &

echo "Waiting for validator RPC to become ready..."
for i in {1..30}; do
    if solana slot --url http://127.0.0.1:8899 > /dev/null 2>&1; then
        echo "Validator RPC is up!"
        break
    else
        echo "Waiting ($i)..."
        sleep 2
    fi
    if [ "$i" -eq 30 ]; then
        echo "Validator RPC did not become ready in time. Check validator log."
        exit 1
    fi
done

echo "Setting solana CLI config"
solana config set --url http://localhost:8899 --keypair "$IDENTITY_KEY"

echo "Requesting airdrop to fund identity..."
solana airdrop 10 || echo "Airdrop failed or already funded."

echo "Checking balance"
solana balance

echo "==== Validator summary ===="
solana validators

echo "Cluster setup complete! Use tail -f $LOGDIR/validator.log to view logs."
