"""
QUANTA Quantum-Resistant Wallet
================================

Implements a wallet with post-quantum signatures.

In production, we use CRYSTALS-Dilithium (NIST FIPS 204)
via libraries like `pqcrypto` (C bindings of liboqs).

For this prototype, we use SPHINCS-style hash-based signatures
(pure Python, no exotic dependencies) — hash-based signatures are
already quantum-safe since Grover only provides √n speedup
instead of exponential.

Design principle: API stays the same so we can swap the algorithm.
"""

from __future__ import annotations
import hashlib
import os
import json
import secrets
from dataclasses import dataclass, asdict
from typing import Tuple


# ---------------------------------------------------------------------------
# 1. Hash-based One-Time Signature (Lamport-style)
# ---------------------------------------------------------------------------
# This is a miniature illustrative version. Production uses SPHINCS+ or Dilithium.
# Lamport is quantum-safe because it relies only on hash functions (Grover-resistant).

HASH = lambda b: hashlib.sha3_256(b).digest()
HASH_LEN = 32        # bytes
MSG_BITS = 256       # we hash message to 256-bit then sign each bit


def _gen_lamport_keys() -> Tuple[bytes, bytes]:
    """Generate Lamport secret + public key (one-time use)."""
    # Secret: 2 × 256 random 32-byte strings
    sk_pairs = [(secrets.token_bytes(HASH_LEN), secrets.token_bytes(HASH_LEN))
                for _ in range(MSG_BITS)]
    # Public: hash each secret half
    pk_pairs = [(HASH(s0), HASH(s1)) for (s0, s1) in sk_pairs]

    sk = b"".join(s0 + s1 for (s0, s1) in sk_pairs)
    pk = b"".join(p0 + p1 for (p0, p1) in pk_pairs)
    return sk, pk


def _lamport_sign(sk: bytes, msg: bytes) -> bytes:
    """Sign a message with Lamport key."""
    digest = HASH(msg)
    sig_parts = []
    for i in range(MSG_BITS):
        bit = (digest[i // 8] >> (i % 8)) & 1
        # Pick secret part matching the bit
        offset = i * 2 * HASH_LEN + bit * HASH_LEN
        sig_parts.append(sk[offset:offset + HASH_LEN])
    return b"".join(sig_parts)


def _lamport_verify(pk: bytes, msg: bytes, sig: bytes) -> bool:
    """Verify a Lamport signature."""
    if len(sig) != MSG_BITS * HASH_LEN:
        return False
    digest = HASH(msg)
    for i in range(MSG_BITS):
        bit = (digest[i // 8] >> (i % 8)) & 1
        sig_chunk = sig[i * HASH_LEN:(i + 1) * HASH_LEN]
        expected = pk[i * 2 * HASH_LEN + bit * HASH_LEN:
                      i * 2 * HASH_LEN + (bit + 1) * HASH_LEN]
        if HASH(sig_chunk) != expected:
            return False
    return True


# ---------------------------------------------------------------------------
# 2. Merkle tree to make one-time → many-time (like XMSS/SPHINCS+ idea)
# ---------------------------------------------------------------------------

class MerkleSignatureScheme:
    """
    Wrapper turning Lamport one-time → 2^h signatures.
    Simplified XMSS simulation. h=4 → 16 signatures per key (enough for demo).
    """

    def __init__(self, height: int = 4):
        self.height = height
        self.n_keys = 2 ** height
        self.used = 0
        self.lamport_sks = []
        self.lamport_pks = []
        for _ in range(self.n_keys):
            sk, pk = _gen_lamport_keys()
            self.lamport_sks.append(sk)
            self.lamport_pks.append(pk)
        self.tree = self._build_tree()
        self.root = self.tree[1]

    def _build_tree(self) -> list[bytes]:
        # Leaves = hash(pk_i)
        leaves = [HASH(pk) for pk in self.lamport_pks]
        nodes = [b""] * self.n_keys + leaves
        for i in range(self.n_keys - 1, 0, -1):
            nodes[i] = HASH(nodes[2 * i] + nodes[2 * i + 1])
        return nodes

    def auth_path(self, idx: int) -> list[bytes]:
        path = []
        i = idx + self.n_keys
        while i > 1:
            sibling = i ^ 1
            path.append(self.tree[sibling])
            i //= 2
        return path

    def sign(self, msg: bytes) -> dict:
        if self.used >= self.n_keys:
            raise RuntimeError("Wallet exhausted — rotate keys")
        idx = self.used
        sig = _lamport_sign(self.lamport_sks[idx], msg)
        result = {
            "scheme": "QUANTA-MSS-v0",
            "idx": idx,
            "ots_pk": self.lamport_pks[idx].hex(),
            "ots_sig": sig.hex(),
            "auth_path": [n.hex() for n in self.auth_path(idx)],
        }
        self.used += 1
        # Wipe sk from memory (best-effort)
        self.lamport_sks[idx] = b"\x00" * len(self.lamport_sks[idx])
        return result

    def public_root(self) -> bytes:
        return self.root


def verify_signature(root: bytes, msg: bytes, sig_obj: dict) -> bool:
    """Verifier only needs the Merkle root."""
    if sig_obj.get("scheme") != "QUANTA-MSS-v0":
        return False
    idx = sig_obj["idx"]
    ots_pk = bytes.fromhex(sig_obj["ots_pk"])
    ots_sig = bytes.fromhex(sig_obj["ots_sig"])
    if not _lamport_verify(ots_pk, msg, ots_sig):
        return False
    # Verify Merkle path
    node = HASH(ots_pk)
    i = idx
    for sibling_hex in sig_obj["auth_path"]:
        sibling = bytes.fromhex(sibling_hex)
        if i % 2 == 0:
            node = HASH(node + sibling)
        else:
            node = HASH(sibling + node)
        i //= 2
    return node == root


# ---------------------------------------------------------------------------
# 3. Wallet API
# ---------------------------------------------------------------------------

@dataclass
class Wallet:
    """High-level QUANTA wallet."""
    mss: MerkleSignatureScheme
    address: str

    @classmethod
    def create(cls, height: int = 4) -> "Wallet":
        mss = MerkleSignatureScheme(height=height)
        # Address = bech32m-style: "qta1" + first 16 bytes of root in hex
        addr = "qta1" + mss.root.hex()[:38]
        return cls(mss=mss, address=addr)

    def sign(self, message: dict) -> dict:
        msg_bytes = json.dumps(message, sort_keys=True).encode()
        return self.mss.sign(msg_bytes)

    @property
    def public_root(self) -> str:
        return self.mss.root.hex()

    def remaining_signatures(self) -> int:
        return self.mss.n_keys - self.mss.used


def verify(address_root_hex: str, message: dict, signature: dict) -> bool:
    msg_bytes = json.dumps(message, sort_keys=True).encode()
    return verify_signature(bytes.fromhex(address_root_hex), msg_bytes, signature)


if __name__ == "__main__":
    print("🔐 QUANTA Quantum-Resistant Wallet Demo\n")
    alice = Wallet.create(height=3)  # 8 signatures
    print(f"Alice address  : {alice.address}")
    print(f"Public root    : {alice.public_root}")
    print(f"Signatures left: {alice.remaining_signatures()}")

    msg = {"from": alice.address, "to": "qta1bob...", "amount": 100, "nonce": 1}
    sig = alice.sign(msg)
    print(f"\nSigned message. Signature size: {len(sig['ots_sig']) // 2} bytes "
          f"+ auth path {len(sig['auth_path'])} × 32 bytes")
    print(f"Verification result: {verify(alice.public_root, msg, sig)}")

    # Tampering test
    tampered = dict(msg, amount=999999)
    print(f"Tampered verify   : {verify(alice.public_root, tampered, sig)}")
