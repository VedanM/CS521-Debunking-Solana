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

Files Contained in `hashing`

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

**ALH**

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

On some of our machines when running the python experiment we got the unexpected result where ADH was actually faster than ALH. We then recreated the test in C++. We did this because of C++'s more consistent behavior and minimal overhead compared to Python.

Some of our hypothesises for why ADH would be faster in Python include:

- Python Optimizations:
  - The Merkle tree calculation might be benefiting from Python's list comprehensions
  - The sum-based ALH might be using Python's integer arithmetic inefficiently
- System-specific Issues:
  - Memory or CPU cache effects specific to your friend's machine
  - Python version or interpreter differences
