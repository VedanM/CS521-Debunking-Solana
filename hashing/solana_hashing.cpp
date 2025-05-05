#include <openssl/sha.h>
#include <algorithm>
#include <chrono>
#include <cstring>
#include <iostream>
#include <random>
#include <string>
#include <vector>

uint64_t sha256_to_u64(const unsigned char* hash) {
    uint64_t result = 0;
    std::memcpy(&result, hash, sizeof(uint64_t));
    return result;
}

uint64_t secure_hash(const std::string& data) {
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256(reinterpret_cast<const unsigned char*>(data.data()), data.size(), hash);
    return sha256_to_u64(hash);
}

std::vector<std::string> make_accounts(size_t n, size_t account_size = 32) {
    std::mt19937_64 rng(0);
    std::uniform_int_distribution<int> dist(0, 255);
    std::vector<std::string> accounts;
    accounts.reserve(n);
    for (size_t i = 0; i < n; i++) {
        std::string a;
        a.reserve(account_size);
        for (size_t j = 0; j < account_size; j++) {
            a.push_back(static_cast<char>(dist(rng)));
        }
        accounts.push_back(std::move(a));
    }
    return accounts;
}

uint64_t adh_merkle_root(std::vector<std::string> accounts) {
    std::sort(accounts.begin(), accounts.end());

    std::vector<uint64_t> nodes;
    nodes.reserve(accounts.size());
    for (auto& acct : accounts) {
        nodes.push_back(secure_hash(acct));
    }

    while (nodes.size() > 1) {
        if (nodes.size() % 2 != 0) {
            nodes.push_back(nodes.back()); 
        }

        std::vector<uint64_t> next;
        next.reserve(nodes.size() / 2);

        for (size_t i = 0; i < nodes.size(); i += 2) {
            std::string combined = std::to_string(nodes[i]) + std::to_string(nodes[i + 1]);
            next.push_back(secure_hash(combined));
        }

        nodes.swap(next);
    }

    return nodes[0];
}

// ALH: Homomorphic sum of SHA-256-based hashes (mod 2^64)
uint64_t alh_hash(const std::vector<std::string>& accounts) {
    uint64_t acc = 0;
    for (auto& acct : accounts) {
        acc += secure_hash(acct);  // wrapping add
    }
    return acc;
}

int main() {
    const size_t N = 200000;
    auto accounts = make_accounts(N);

    auto t0 = std::chrono::steady_clock::now();
    uint64_t adh = adh_merkle_root(accounts);
    auto t1 = std::chrono::steady_clock::now();
    uint64_t alh = alh_hash(accounts);
    auto t2 = std::chrono::steady_clock::now();

    double adh_time = std::chrono::duration<double>(t1 - t0).count();
    double alh_time = std::chrono::duration<double>(t2 - t1).count();

    std::cout << "ADH Merkle Root: " << adh << ", Time: " << adh_time << " s\n";
    std::cout << "ALH Sum Hash: " << alh << ", Time: " << alh_time << " s\n";
    std::cout << "Speed-up: " << (adh_time / alh_time) << "×\n";

    return 0;
}
