import hashlib
from typing import List
import random
import time

def sha256_digest(data: bytes) -> bytes:
    return hashlib.sha256(data).digest()

def digest_to_u64_le(digest: bytes) -> int:
    # Convert first 8 bytes of digest to uint64 in little-endian
    return int.from_bytes(digest[:8], byteorder='little')

def compute_alh(accounts: List[bytes]) -> int:
    start = time.time()
    total = 0
    for acct in accounts:
        digest = sha256_digest(acct)
        val = digest_to_u64_le(digest)
        total = (total + val) & 0xFFFFFFFFFFFFFFFF  # wraparound at 64 bits
    duration = time.time() - start
    return total, duration

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

# Generate synthetic data
accounts = [random.randbytes(32) for _ in range(20000)]

# Compute ADH (Merkle root) and ALH
merkle_hash, merkle_time = compute_adh(accounts)
alh_hash_val, alh_time = compute_alh(accounts)

print(f'ADH Hash: {merkle_hash}, Time: {merkle_time}')
print(f'ALH Hash: {alh_hash_val}, Time: {alh_time}')
print(merkle_time / alh_time)
