# Network Halt Fix - Byzantine Fault Tolerance Solution

## What We Fixed

The Splendor blockchain was stuck at block 214126 because of a bug in `Core-Blockchain/node_src/consensus/congress/snapshot.go`.

**Problem**: When validators were added to the network, the code didn't clean up the "recently signed" tracking map. This caused all validators to be marked as "recently signed" forever, creating a deadlock where no validator could sign new blocks.

**Fix**: Added cleanup logic in the `apply()` function to properly clear old entries from the `Recents` map when validator sets change:

```go
// Clean up recent validators when validator set changes to prevent chain halt
// This prevents the "Signed recently, must wait for others" deadlock
if newValidatorCount > oldValidatorCount {
    // Clear more recent entries when expanding validator set
    for blockNum := range snap.Recents {
        if number >= newLimit && blockNum <= number-newLimit {
            delete(snap.Recents, blockNum)
        }
    }
} else if newValidatorCount < oldValidatorCount {
    // Clear recent entries when reducing validator set
    for blockNum := range snap.Recents {
        if blockNum <= number-newLimit {
            delete(snap.Recents, blockNum)
        }
    }
}
```

**Result**: Network can now handle validator additions/removals without halting.

## How to Deploy

1. Compile: `cd Core-Blockchain/node_src && make geth`
2. Copy the binary from `Core-Blockchain/node_src/build/bin/geth` to your servers
3. Replace the old geth binary and restart nodes

---

**Status**: Fixed and ready for deployment
