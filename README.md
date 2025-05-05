# CS521-Debunking-Solana

## Project Description:
During this project, we walked over the Solana code, explaining the four most important aspects: <br />
Accounts & State: How Solana Handles Data <br />
Consensus: Tower BFT and Proof of History <br />
Fee Calculation and Rent <br />
Validator Lifecycle & Voting <br /> <br />

We also looked into the possible implementation of ALH (Accounts Lattice Hash) instead of ADH (Accounts Delta Hash) in Solana and its limitations. <br /> <br />
Members:<br />
Vedan Malhotra (vedanm2)<br />
Tanay Pareek (tpareek2)<br />
Nick Messina (messina4)<br />
Aryan Malhotra (aryanm8)<br />

## What we did:
### Section 1: **Trying to set up a Validator Node and funded accounts to transfer SOL**

This section walks through the process of setting up a validator node in Solana. The goal was to create both a validator account and a vote account to participate in the network’s consensus mechanism. Here's what we did:

- Created keys for a validator node on our machine
- Funded the validator account using the Solana faucet.
- Set up a vote account linked to the validator account for voting in the consensus process.
- Transferred SOL from the validator account to another created account for transaction testing.

The related logs for this section are present in the fundAndTransferSOL_logs.pdf file.

**Steps Taken:**
1. **Set up Solana CLI:**  
   Followed the instructions at https://docs.anza.xyz/cli/install to install and configure the Solana CLI on our system.

2. **Created Keys:**  
   Used the following commands to generate key pairs for the validator, vote account, and authorized withdrawer and to set the deafult validator account:
   ```bash
   solana-keygen new -o validator-keypair.json
   solana-keygen new -o vote-account-keypair.json
   solana-keygen new -o authorized-withdrawer-keypair.json
   ```
   ```bash
   solana config set --keypair ./validator-keypair.json
   ```
   
3. **Fund the account:**  
   Ran the following command to fetch the address of our wallet and funded this address by requesting SOL on the testnet using the faucet interface 
   https://faucet.solana.com
   ```bash
   solana address
   ```

4. **Create Vote Account:**  
   Created vote account by running:
   ```bash
   solana create-vote-account -ut \
    --fee-payer ./validator-keypair.json \
    ./vote-account-keypair.json \
    ./validator-keypair.json \
    ./authorized-withdrawer-keypair.json
   ```

5. **Connected to test validator:**  
   This is where we encountered machine limitations as advanced machines were needed to host a server to actually connect with the validator node. So we tried playing with the in-built test validator which can be used for testing. It shows live updates for processed transaction slots.

   Ran it using:
   ```bash
   solana-test-validator
   ```

6. **Transferred SOL:**  
   Opened solana logs to track transfer of SOL by running
   ```bash
   solana logs
   ```
   Then ran the following command to transfer 1 SOL to another account we created using step 2
   ```bash
   solana transfer <address_here> 1 --allow-unfunded-recipient
   ```
   Note: we used the --allow-unfunded-recipient flag because the second account we created to make the transfer was not funded by the faucet.
