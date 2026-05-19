"""
QUANTA — Proof of Useful Work (PoUW) Consensus Module
=====================================================

Instead of meaningless SHA-256 hashes, validators must complete
a useful "AI task" and prove the result.

In production:
  - Tasks can be LLM inference, training shards, protein folding, scientific compute
  - Verified via zkML proof (ezkl, RiscZero) or redundant 3-of-5 execution
  - Stake-weighted random selection (like Algorand VRF)

In prototype:
  - Simulated task = "compute a function" then require validator to submit result
  - Verified by quick re-run (since tasks are small)
  - Validator chosen via simulated VRF (hash-based)
"""

from __future__ import annotations
import hashlib
import json
import random
import time
from dataclasses import dataclass, field
from typing import Callable, Optional


HASH = lambda b: hashlib.sha3_256(b).digest()


@dataclass
class UsefulTask:
    """A unit of useful work."""
    task_id: str
    kind: str
    payload: dict
    reward: float
    verifier_hint: dict

    def to_bytes(self) -> bytes:
        return json.dumps({
            "task_id": self.task_id,
            "kind": self.kind,
            "payload": self.payload,
        }, sort_keys=True).encode()


@dataclass
class WorkProof:
    """Proof of completed task."""
    task_id: str
    validator: str
    result: dict
    result_hash: str
    timestamp: float

    def to_bytes(self) -> bytes:
        return json.dumps({
            "task_id": self.task_id,
            "validator": self.validator,
            "result_hash": self.result_hash,
            "timestamp": self.timestamp,
        }, sort_keys=True).encode()


@dataclass
class Validator:
    address: str
    stake: float
    gpu_score: float = 1.0
    reputation: float = 1.0
    blocks_proposed: int = 0
    slashed_amount: float = 0.0

    def selection_weight(self) -> float:
        return self.stake * self.reputation


class PoUWConsensus:
    """Coordinator orchestrating validators + tasks."""

    MIN_STAKE = 10_000.0
    SLASH_RATE = 1.0
    BLOCK_REWARD = 50.0

    def __init__(self, seed: int = 0):
        self.validators: dict[str, Validator] = {}
        self.task_queue: list[UsefulTask] = []
        self.completed: list[tuple[UsefulTask, WorkProof]] = []
        self.rng = random.Random(seed)

    def register(self, validator: Validator) -> None:
        if validator.stake < self.MIN_STAKE:
            raise ValueError(f"Min stake {self.MIN_STAKE} QTA required")
        self.validators[validator.address] = validator

    def total_stake(self) -> float:
        return sum(v.selection_weight() for v in self.validators.values())

    def enqueue_task(self, task: UsefulTask) -> None:
        self.task_queue.append(task)

    def select_proposer(self, slot_seed: bytes) -> Optional[Validator]:
        """VRF-style stake-weighted selection."""
        if not self.validators:
            return None
        total = self.total_stake()
        h = int.from_bytes(HASH(slot_seed)[:8], "big")
        target = (h / 2**64) * total
        acc = 0.0
        for v in self.validators.values():
            acc += v.selection_weight()
            if acc >= target:
                return v
        return list(self.validators.values())[-1]

    def execute_task(self, validator, task, executor):
        result = executor(task)
        result_bytes = json.dumps(result, sort_keys=True).encode()
        return WorkProof(
            task_id=task.task_id,
            validator=validator.address,
            result=result,
            result_hash=HASH(result_bytes).hex(),
            timestamp=time.time(),
        )

    def verify_proof(self, task, proof, executor):
        expected_hash = task.verifier_hint.get("expected_hash")
        if expected_hash:
            return proof.result_hash == expected_hash
        recomputed = executor(task)
        recomputed_hash = HASH(json.dumps(recomputed, sort_keys=True).encode()).hex()
        return recomputed_hash == proof.result_hash

    def reward_and_slash(self, validator, success, work_score):
        if not success:
            slash = validator.stake * self.SLASH_RATE
            validator.stake -= slash
            validator.slashed_amount += slash
            validator.reputation = max(0.1, validator.reputation - 0.5)
            return -slash
        stake_factor = min(1.0, validator.stake / 1_000_000)
        reward = self.BLOCK_REWARD * (stake_factor * 0.4 + work_score * 0.6)
        validator.stake += reward
        validator.blocks_proposed += 1
        validator.reputation = min(2.0, validator.reputation + 0.01)
        return reward


def demo_executor(task: UsefulTask) -> dict:
    """Simulates an AI task."""
    if task.kind == "llm_inference":
        prompt = task.payload.get("prompt", "")
        out = HASH(prompt.encode() + b"|llm-quanta-7b").hex()[:64]
        return {"completion": out, "tokens": len(prompt.split())}
    elif task.kind == "image_gen":
        seed = task.payload.get("seed", 0)
        return {"image_hash": HASH(str(seed).encode()).hex()}
    else:
        return {"output": HASH(task.to_bytes()).hex()}


if __name__ == "__main__":
    print("⚙️  PoUW Consensus Demo\n")
    pouw = PoUWConsensus(seed=42)

    for i in range(5):
        v = Validator(
            address=f"qta1validator{i}",
            stake=10_000 + i * 5000,
            gpu_score=1.0 + i * 0.2,
        )
        pouw.register(v)
    print(f"Registered {len(pouw.validators)} validators, "
          f"total stake = {pouw.total_stake():,.0f} QTA")

    for i in range(3):
        task = UsefulTask(
            task_id=f"task-{i}",
            kind="llm_inference",
            payload={"prompt": f"Explain quantum cryptography (attempt {i})"},
            reward=5.0,
            verifier_hint={},
        )
        pouw.enqueue_task(task)

    for slot in range(3):
        task = pouw.task_queue.pop(0)
        proposer = pouw.select_proposer(slot_seed=f"slot-{slot}".encode())
        proof = pouw.execute_task(proposer, task, demo_executor)
        ok = pouw.verify_proof(task, proof, demo_executor)
        reward = pouw.reward_and_slash(proposer, ok, work_score=0.9)
        print(f"Block {slot}: proposer={proposer.address[:18]}... "
              f"task={task.task_id} verified={ok} reward={reward:+.2f} QTA")

    print("\nFinal validator stakes:")
    for v in pouw.validators.values():
        print(f"  {v.address}  stake={v.stake:,.2f}  blocks={v.blocks_proposed}  "
              f"rep={v.reputation:.2f}")
