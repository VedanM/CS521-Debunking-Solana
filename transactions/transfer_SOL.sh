# Run sh transfer_SOL.sh to run this module. This module:
#   1) Installs Solana CLI
#   2) Generate keypairs for the validator account, vote account, withdrawer id, and the second node (for the transfer)
#   3) Configures the default validator keypair
#   4) Launches the test validator
#   5) Adds funds from the faucet: 10 SOL to the validator (first node) and 5 SOL to the second node
#   6) Creates the vote account
#   7) Initializes the logs for viewing the transfer
#   8) Trasnfer 1 SOL from the validator to the second node


if ! command -v solana &> /dev/null; then
  echo "Installing Solana CLI..."
  sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
  export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
else
  echo "Solana CLI already installed: $(solana --version)"
fi


echo "Generating keypairs..."
solana-keygen new --no-passphrase -o validator-keypair.json
solana-keygen new --no-passphrase -o vote-account-keypair.json
solana-keygen new --no-passphrase -o authorized-withdrawer-keypair.json
solana-keygen new --no-passphrase -o node-keypair.json


echo "Configuring Solana CLI default keypair..."
solana config set --keypair ./validator-keypair.json


echo "Launching local test validator..."
solana-test-validator --reset > /dev/null 2>&1 &
sleep 5


echo "Airdropping 10 SOL to validator..."
solana airdrop 10 --url localhost
echo "Airdropping 5 SOL to node..."
NODE_PUBKEY=$(solana-keygen pubkey node-keypair.json)
solana airdrop 5 $NODE_PUBKEY --url localhost


echo "Creating vote account..."
solana create-vote-account \
  --fee-payer ./validator-keypair.json \
  --url localhost \
  ./vote-account-keypair.json \
  ./validator-keypair.json \
  ./authorized-withdrawer-keypair.json


echo "Streaming test-validator logs..."
solana logs &


echo "Transferring 1 SOL to node (${NODE_PUBKEY})..."
solana transfer $NODE_PUBKEY 1 \
  --allow-unfunded-recipient \
  --from ./validator-keypair.json \
  --url localhost


echo
echo "Transfer complete!"
echo "Validator Pubkey: $(solana-keygen pubkey validator-keypair.json)"
echo "Node Pubkey:      ${NODE_PUBKEY}"
