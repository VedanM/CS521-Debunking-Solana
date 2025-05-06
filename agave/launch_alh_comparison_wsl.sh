#!/bin/bash

# This script compares ALH and ADH hashes for a given slot using agave-ledger-tool
# Output: Slot, ALH, ADH hashes, and whether they match

#!/bin/bash

LEDGER=~/sol/ex/solana-ledger
LOG=~/sol/ex/logs/validator.log

echo "Checking latest slot in ledger..."
LATEST_SLOT=$(grep -a "bank-accounts_lt_hash" "$LOG" | awk -F'slot=' '{print $2}' | awk -F'i' '{print $1}' | sort -n | tail -1)

if [ -z "$LATEST_SLOT" ]; then
    echo "Ledger has no valid slots yet. Exiting."
    exit 1
fi

N=50  # Number of most recent slots to compare
START_SLOT=$((LATEST_SLOT - N))
if [ "$START_SLOT" -lt 0 ]; then
    START_SLOT=0
fi

echo
echo "Comparing ALH and ADH hashes from slot $START_SLOT to $LATEST_SLOT"
echo

for SLOT in $(seq $START_SLOT $LATEST_SLOT); do
    echo "Comparing hashes for slot: $SLOT"

    # ALH
    ALH_HASH=$(grep -a "bank-accounts_lt_hash" "$LOG" | grep "slot=$SLOT" | awk -F'hash=' '{print $2}' | tail -1 | tr -d '"')
    # ADH
    ADH_HASH=$(grep -a "bank-accounts_delta_hash" "$LOG" | grep "slot=$SLOT" | awk -F'hash=' '{print $2}' | tail -1 | tr -d '"')
    
    echo "  ALH: $ALH_HASH"
    echo "  ADH: $ADH_HASH"

    if [ "$ALH_HASH" == "$ADH_HASH" ] && [ -n "$ALH_HASH" ]; then
        echo "Hashes match"
    elif [ -z "$ALH_HASH" ] || [ -z "$ADH_HASH" ]; then
        echo "Missing hash data"
    else
        echo "Hashes differ!"
    fi

    echo
done

echo "Comparison complete."
