#!/bin/bash
set -e

WORKDIR=~/sol/ex/second
FIRST_LEDGER=~/sol/ex/solana-ledger
SECOND_LEDGER=~/sol/ex/second/solana-ledger
LOGDIR=~/sol/ex/second/logs
mkdir -p "$LOGDIR"
cd "$WORKDIR"

IDENTITY_KEY="validator-identity-keypair.json"
VOTE_KEY="validator-vote-keypair.json"
STAKE_KEY="validator-stake-keypair.json"

FIRST_VALIDATOR_PUBKEY=$(solana-keygen pubkey ~/sol/ex/validator-identity-keypair.json)

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

echo "==== Copying ledger from first validator ===="
if [[ ! -d "$SECOND_LEDGER" ]]; then
    cp -r "$FIRST_LEDGER" "$SECOND_LEDGER"
else
    echo "Ledger already exists. Skipping copy."
fi

# --- PRE-CREATE accounts_index ---
#mkdir -p "$LEDGER/accounts_index"

echo "==== Starting second validator ===="
nohup agave-validator \
    --identity "$IDENTITY_KEY" \
    --vote-account "$VOTE_KEY" \
    --ledger "$SECOND_LEDGER" \
    --rpc-port 8898 \
    --rpc-bind-address 0.0.0.0 \
    --rpc-faucet-address 127.0.0.1:9901 \
    --gossip-port 8101 \
    --dynamic-port-range 8100-8120 \
    --enable-rpc-transaction-history \
    --full-rpc-api \
    --no-port-check \
    --no-wait-for-vote-to-start-leader \
    --known-validator "$FIRST_VALIDATOR_PUBKEY" \
    --entrypoint 127.0.0.1:8001 \
    --log "$LOGDIR/validator.log" > nohup.out 2>&1 &

# --- START FAUCET ---
echo "Starting solana-faucet (logs in $LOGDIR/faucet.log)"
nohup solana-faucet validator-identity-keypair.json --port 9901 > "$LOGDIR/faucet.log" 2>&1 &

# --- SET SOLANA CLI CONFIG FOR SECOND VALIDATOR ---
solana config set --url http://localhost:8898 --keypair "$IDENTITY_KEY"

# --- WAIT FOR RPC TO COME ONLINE ---
echo "Waiting for second validator RPC readiness..."
for i in {1..30}; do
  if solana cluster-version >/dev/null 2>&1; then
    echo "RPC ready."
    break
  fi
  sleep 2
done

echo "Requesting airdrop to fund identity..."
solana --url http://localhost:8898 airdrop 10 || echo "Airdrop failed or already funded."

echo "Creating vote account (if needed)..."
solana vote-account "$VOTE_KEY" || echo "Vote account likely exists or can't be created."

echo "==== Second validator summary ===="
solana validators

echo "Second validator setup complete! Use tail -f $LOGDIR/validator.log to view logs."
