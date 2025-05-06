#!/bin/bash

# Monitor both validators' vote credits, skip rates, and last votes

FIRST_RPC=http://localhost:8899
SECOND_RPC=http://localhost:8898

FIRST_IDENTITY=$(solana-keygen pubkey ~/sol/ex/validator-identity-keypair.json)
SECOND_IDENTITY=$(solana-keygen pubkey ~/sol/ex/second/validator-identity-keypair.json)

function print_validator_status() {
  local rpc=$1
  local identity=$2

  echo "============================="
  echo "Validator Identity: $identity"
  echo "RPC Endpoint: $rpc"
  echo "-----------------------------"

  solana --url $rpc validators --output json | jq --arg ID "$identity" '.validators[] | select(.identity == $ID) | {
    identity: .identity,
    vote_account: .vote_account,
    last_vote: .last_vote,
    root_slot: .root_slot,
    skip_rate: .skip_rate,
    credits: .credits,
    version: .version,
    active_stake: .active_stake
  }'

  echo "============================="
}

while true; do
  clear
  echo "Cluster Voting Status - $(date)"

  print_validator_status $FIRST_RPC $FIRST_IDENTITY
  print_validator_status $SECOND_RPC $SECOND_IDENTITY

  echo "Sleeping 10 seconds before next update"
  sleep 10
done
