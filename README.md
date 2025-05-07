# CS521-Debunking-Solana

## Project Description:

During this project, we walked over the Solana code, explaining the four most important aspects: <br />
Accounts & State: How Solana Handles Data <br />
Consensus: Tower BFT and Proof of History <br />
Fee Calculation and Rent <br />
Validator Lifecycle & Voting <br /> <br />

We also looked into the possible implementation of ALH (Accounts Lattice Hash) instead of ADH (Accounts Delta Hash) in Solana and its limitations. <br /> <br />
**Members:** <br />
Vedan Malhotra (vedanm2)<br />
Tanay Pareek (tpareek2)<br />
Nick Messina (messina4)<br />
Aryan Malhotra (aryanm8)<br />

**Contributions**: <br />
We all worked together on setting up Solana locally on our machines, as well as creating the scripts to test the ALH/ADH hash timings. We all tried to implement the same portions of the project, so we ended up always meeting to jointly work on each section. But, outside of this, each team member focused on these sections specifically:

Aryan: Created the bash script to setup validator nodes locally and to create SOL transactions <br />
Vedan: Created the bash scripts to setup Agave locally <br />
Tanay: Deployed Validator nodes without Agave locally <br />
Nick: Worked on hashing scripts and aided other teammembers with setting up their section


## What we did:

### Section 1: **Trying to set up a Validator Node and funded accounts to transfer SOL**

Files contained in `transactions`

This section walks through the process of setting up a validator node in Solana. The goal was to create both a validator account and a vote account to participate in the network's consensus mechanism. Here's what we did:

- Created keys for a validator node on our machine
- Funded the validator account using the Solana faucet.
- Set up a vote account linked to the validator account for voting in the consensus process.
- Transferred SOL from the validator account to another created account for transaction testing.

If you want to try it out, check out the transactions folder and run the transfer_SOL.sh script. The related logs for this section are present in the fundAndTransferSOL_logs.pdf file.

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
   Used the following command to fund the wallet through the faucet:

   ```bash
   solana airdrop 10
   ```

   However, sometimes this command errors out. In that case, run the following command to fetch the address of the wallet and funded this address by requesting SOL on the testnet using the faucet interface
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

### Section 2: **Comparing Account Delta Hashing vs. Account Lattice Hashing**

Files contained in `hashing`

The purpose of the scripts was to compare the performance difference between the computationally intensive Merkle tree aproach (ADH) versus the simpler additive approach (ALH).

**`adh_alh.py`**

**ALH**

```python
def compute_alh(accounts: List[bytes]) -> int:
    start = time.time()
    total = 0
    for acct in accounts:
        digest = sha256_digest(acct)
        val = digest_to_u64_le(digest)
        total = (total + val) & 0xFFFFFFFFFFFFFFFF  # wraparound at 64 bits
    duration = time.time() - start
    return total, duration
```

- `compute_alh` takes a list of account data bytes
- For each account, it computes the SHA-256 hash and converts the first 8 bytes to a uint64
- It sums all these values with 64-bit wraparound (using a bitwise AND with 0xFFFFFFFFFFFFFFFF)
- It tracks and returns the computation time along with the result

**ADH**

```python
def compute_adh(accounts: List[bytes]) -> bytes:
    start = time.time()
    accounts = sorted(accounts)
    hashes = [sha256_digest(acct) for acct in accounts]

    # 3. Build Merkle Tree
    while len(hashes) > 1:
        if len(hashes) % 2 == 1:
            hashes.append(hashes[-1])  # duplicate last to make even
        new_hashes = []
        for i in range(0, len(hashes), 2):
            combined = hashes[i] + hashes[i + 1]
            new_hashes.append(sha256_digest(combined))
        hashes = new_hashes
    duration = time.time() - start
    return hashes[0].hex(), duration
```

- Takes a list of account data bytes
- Sorts accounts
- Computes SHA-256 hashes for each account
- Builds a Merkle tree:
  - Pairs adjacent hashes and hashes their concatenation
  - If odd number of hashes, duplicates the last one
  - Repeats until only one hash remains (the Merkle root)
- Returns the hexadecimal representation of the root and computation time

**`solana_hashing.cpp`**

`adh_merkle_root`

- Takes a vector of accounts
- Sorts the accounts
- Computes secure hash for each account
- Builds a Merkle tree:
  - Pairs adjacent hashes
  - If odd number of hashes, duplicates the last one
  - Concatenates pairs as strings and hashes them
  - Repeats until only one hash remains (the Merkle root)
- Returns the Merkle root as uint64_t

`alh_hash`

- Takes a vector of accounts
- For each account, computes the secure hash
- Sums all hash values with natural 64-bit wrapping
- Returns the sum as uint64_t

**Results**

**Python**

```bash
ADH Hash: 3ff40a3a52e6809e4c28d5f1aeeeb2ba8bc2a0f8734e5209d29ae16e9e63ca54, Time: 0.016403913497924805
ALH Hash: 17870609279760938959, Time: 0.00869607925415039
1.8863574052749903
```

**C++**

```bash
ADH Merkle Root: 17962529666642118938, Time: 0.347235 s
ALH Sum Hash: 3233227066089387301, Time: 0.046957 s
Speed-up: 7.39474×
```

In both languages ALH was faster in computing a hash of account states.

**Issues**

We then recreated the test in C++. We did this because of C++'s more consistent behavior and minimal overhead compared to Python.

Some of our hypotheses for why ALH isn't significantly faster than ADH in Python include:

- Python Optimizations:
  - The Merkle tree calculation might be benefiting from Python's list comprehensions
  - The sum-based ALH might be using Python's integer arithmetic inefficiently
- System-specific Issues:
  - Memory or CPU cache effects specific to your friend's machine
  - Python version or interpreter differences

### Section 3: **Setting up Solana Locally Without Agave (Solana 1.18.8)**

Files contained in `solana-cluster`

This section outlines how we successfully set up a local Solana cluster with multiple validators entirely using the native `solana` toolchain (version 1.18.8), without relying on Agave. The goal was to launch a self-contained 4-node Solana cluster for testing validator behavior and ledger consistency. The entire setup was done on macOS, but the steps generalize to any Unix-like system with Solana installed.

**Generating the Bootstrap Validator and Initializing the Cluster**

The first step was to generate the required keypairs for the bootstrap validator:

- Identity keypair: validator-keypair.json
- Vote account keypair: vote-account-keypair.json

We then initialized the cluster by generating a new genesis file using the `solana-genesis` command. This sets up the initial parameters for the network such as lamport distributions, tick scheduling, rent/burn parameters, and faucet configuration:

```bash
solana-genesis \
  --ledger ~/solana-ledger \
  --hashes-per-tick sleep \
  --bootstrap-validator validator-keypair.json vote-account-keypair.json vote-account-keypair.json \
  --bootstrap-validator-lamports 500000000000 \
  --bootstrap-validator-stake-lamports 250000000000 \
  --faucet-pubkey validator-keypair.json \
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
```

This creates the necessary genesis.bin and ledger structure in ~/solana-ledger.

**Starting the Bootstrap Validator**

We then launched the bootstrap validator using the following command, exposing RPC, gossip, and TPU ports locally, and enabling faucet access:

```bash
solana-validator \
  --identity validator-keypair.json \
  --vote-account vote-account-keypair.json \
  --ledger ~/solana-ledger \
  --rpc-port 8899 \
  --gossip-port 8001 \
  --dynamic-port-range 8000-8020 \
  --expected-genesis-hash <hash from solana-genesis> \
  --rpc-bind-address 0.0.0.0 \
  --rpc-faucet-address 127.0.0.1:9900 \
  --enable-rpc-transaction-history \
  --full-rpc-api \
  --no-port-check \
  --log -
```

The --no-port-check ensures we can bind to needed ports even in parallel test environments. The --rpc-faucet-address allows for airdrops to local accounts.

To allow CLI tools like `solana balance` or `solana airdrop` to interface with this validator, we ran:

```bash
solana config set --url http://127.0.0.1:8899
```

**Adding Additional Validators to the Cluster**

To create additional validators, we generated new identity and vote keypairs and then copied the bootstrap ledger as a starting point for each new validator. For instance, for Validator 2:

```bash
cp -r ~/solana-ledger ~/solana-ledger-2
```

We then started Validator 2 with a different set of ports, and pointed it to the bootstrap validator as its entrypoint:

```bash
solana-validator \
  --identity validator2-identity-keypair.json \
  --vote-account validator2-vote-keypair.json \
  --ledger ~/solana-ledger-2 \
  --rpc-port 8910 \
  --gossip-port 8017 \
  --dynamic-port-range 8020-8040 \
  --expected-genesis-hash <same hash> \
  --rpc-bind-address 0.0.0.0 \
  --rpc-faucet-address 0.0.0.0:9900 \
  --entrypoint 127.0.0.1:8001 \
  --trusted-validator <bootstrap validator pubkey> \
  --known-validator <bootstrap validator pubkey> \
  --enable-rpc-transaction-history \
  --full-rpc-api \
  --no-port-check \
  --log -
```

The key flags to note for validators joining an existing cluster are:

- --entrypoint: specifies where to find the bootstrap validator
- --trusted-validator and --known-validator: enforces secure validator discovery
- --expected-genesis-hash: must match the genesis of the bootstrap validator
- --rpc-faucet-address: shared faucet access for all validators

Before setting up validators 3 and 4, we wanted to ensure that the Bootstrap validator and validator were connected and correctly running. To do so, we ran the command below:

```bash
solana gossip
```

Unfortunately, this command showed that the nodes were not active in the local cluster. Moreover, the image below showed a lot of other validators, which did not seem to be configure by us.

![alt text](https://github.com/VedanM/CS521-Debunking-Solana/blob/main/solana-cluster/images/solanass1.png)

Curious to understand whether why there were so many validators, we ran the command `solana validators` which resulted in the output below:

![alt text](https://github.com/VedanM/CS521-Debunking-Solana/blob/main/solana-cluster/images/solanass2.png)

Through this, and the `solana config get` command, we were able to realize that we were connected to the mainnet, and were able to fix the configuration as described in **Common Issues and Fixes** at the end of this section. However, this still not show us our local validators communicating when running `solana gossip`. When correctly configured, all 4 validators should have appeared here with IP 127.0.0.1 and their assigned gossip ports.

**Common Issues and Fixes**

- Invalid entrypoint error: Occurs if the entrypoint address is malformed or the bootstrap validator isn’t gossiping correctly. Fixed by ensuring `--entrypoint` is `127.0.0.1:<bootstrap gossip port>`.
- Genesis hash mismatch: Happens when ledgers are misaligned. Used `cp -r` to copy the bootstrap ledger to other validators
- No nodes in gossip: Research and use of AI suggested that this is typically caused by omitted `--entrypoint`, or network isolation. However, unable to resolve
- CLI commands defaulting to mainnet: Resolved by running `solana config set --url http://127.0.0.1:8899`

Finally, using the progress made here, we switched to Agave to set up our local Solana cluster, the details of which can be found in the following section.

### Section 4: **Setting up Solana Locally Using Agave**

Files contained in `agave`

This section walks through setting up Solana using the Agave validator. The goal was to setup a local Solana cluster with multiple validators, retrieving the ALH and ADH hashes generated to compare their values while the cluster ran.

**`launch_cluster_wsl.sh`**

This bash script was created to initialize the bootstrap validator and Solana genesis (starting the blockchain). Before running this script, one should have Agave installed (instructions found [here](https://docs.anza.xyz/cli/install)). We used version `2.2.0`.

The initial steps of generating the cluster's bootstrap validator's identity, vote, and stake key-pairs are the same as Section 1.

The following code starts up the blockchain. Here, we can see the bootstrap validator is assigned to the Solana key-pairs we generated prior, with lamport values being initialized for testing. These values can be arbitrarily assigned, and the same goes for burn percentages and vote commission. The rest of these variables were default options when running solana-genesis, and are explained by running `solana-genesis -help`.

```bash
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
```

To run the validator created, we call `agave-validator` as below:

```bash
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
```

`nohup` right before `agave-validator` allows the process to keep running even if you close the terminal. It ignores SIGHUP (hangup) signals.

Running `agave-validator -help` will succinctly describe each attribute. Essentially, this creates a validator which gossips on port 8001 and binds the RPC port to localhost. The faucet address enables us to interact through the faucet interface (aka airdrop SOL). The biggest option to note is `--no-wait-for-vote-start-leader`. This automatically tells the validator that even if no votes have been landed, just start producing slots (which is helpful for testing the hashes we want).

We then start the faucet for the validator in the script through `nohup solana-faucet validator-identity-keypair.json` and wait for the validator RPC to be ready (as it sometimes takes time to start up). If we timeout here, we know there's an issue with starting the validator RPC.

The rest of the code in the script is to visualize/check the prior functions were properly setup without errors. If there are any, the logs should accurately describe the issue which occurred.

**`launch_second_validator_wsl.sh`**

This bash script runs a second validator that connects to the cluster/bootstrap validator created before. We have to create new keypairs for this validator; however, we use the same ledger from the first validator as part of creating the connection. To do this, we simply copied the previous ledger into the directory of the second validator through this command in the script: `cp -r "$FIRST_LEDGER" "$SECOND_LEDGER"`.

The below snippet shows the setup of the second validator:

```bash
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
```

This setup mirrors the first script (though `IDENTITY_KEY`, `VOTE_KEY`, etc. now point to the second validator, and we use different ports to bind to since validators can't use the same ones). The only difference here is we added `--known-validator` and `--entrypoint`. These specify trusted/recognized validator identities and which port to access (otherwise the validator will default to public entrypoints on the mainnet/devnet).

The rest of the script is practically the same as the first one.

**`launch_monitoring_wsl.sh`**

This script continually monitors the state of each validator, returning diagnostic information visually. It's prints updated information every 10 seconds while the cluster and validators are setup and running concurrently. Monitoring was setup purely for testing and collecting data. See the script for more information.

**`launch_alh_comparison_wsl.sh`**

This script collects the N (in our case, 50) most recent slots created and retrieves the ALH and ADH hash that was computed for each one. These can be found from the validator's logs. The hashes are then compared to see if there was a difference in computation, printing if there was a match as well as what hashes were created. Agave v2.2.0 still shows both hashings, which is great for visualizing the differences between ALH/ADH. See the script for more information.

**Issues**

Unfortunately, when trying to connect the second validator to the bootstrap validator, we were unsuccessful. There was a problem in connecting it to the first validator's gossip port. As a result, we only had one validator properly running in the cluster, though that should be enough to calculate the slot ALH and ADH hashes. However, these hashes weren't present in the log. We theorize that since the Solana cluster was setup in WSL, which is known for having issues with file descriptor and RAM limitations for Solana, the logs were unable to display the ALH and ADH hashes properly. It's also possible that the log verbosity levels were too low (which wasn't fixable), or the validator was progressing mostly with votes and no account changes (in which case the delta hashes and lattice hashes might not be computed or logged as accounts aren't being modified otherwise).
