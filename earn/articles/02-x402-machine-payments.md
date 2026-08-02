# x402 Protocol: The Future of Machine-to-Machine Payments

**Meta:** How the HTTP 402 status code is being revived for AI agent micropayments, and how to implement x402-style payment channels in Solidity.

**Tags:** web3, http402, micropayments, ai-agents, solidity

---

## The Problem HTTP 402 Was Designed For

In 1997, HTTP/1.1 introduced status code 402: "Payment Required." It was reserved but never used. Twenty-eight years later, AI agents need it more than ever.

```http
GET /api/llm/inference
→ 402 Payment Required
  X-QUANTA-Price: 0.0001 QTA
  X-QUANTA-Receiver: qta1abc...

# Client pays in header of next request
Authorization: QUANTA <signed_payment_proof>
→ 200 OK { "completion": "..." }
```

This is the x402 pattern — machine-readable payments embedded in HTTP headers.

## Why Existing Payment Systems Fail

| System | Min Transaction | AI Agent Compatible |
|--------|----------------|---------------------|
| Stripe | $0.50 | ❌ (needs KYC) |
| PayPal | $0.01 | ❌ (needs account) |
| Ethereum L1 | $0.50 gas | ❌ (too expensive) |
| Ethereum L2 | $0.01 gas | ⚠️ (still expensive for 1M txs) |
| **QUANTA channels** | **$0.000001** | **✅** |

## Implementation Guide

### Step 1: Deploy the Payment Channel Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract X402Channel {
    struct Stream {
        address payer;
        address payee;
        uint256 ratePerSecond;
        uint256 startTime;
        uint256 deposited;
        bool active;
    }
    
    mapping(bytes32 => Stream) public streams;
    
    event StreamOpened(
        bytes32 indexed streamId,
        address payer,
        address payee,
        uint256 ratePerSecond
    );
    
    event PaymentClaimed(
        bytes32 indexed streamId,
        uint256 amount
    );
    
    function openStream(
        address payee,
        uint256 ratePerSecond,
        uint256 duration
    ) external payable returns (bytes32) {
        bytes32 streamId = keccak256(
            abi.encodePacked(
                msg.sender, payee, block.timestamp
            )
        );
        
        uint256 deposit = ratePerSecond * duration;
        
        streams[streamId] = Stream({
            payer: msg.sender,
            payee: payee,
            ratePerSecond: ratePerSecond,
            startTime: block.timestamp,
            deposited: deposit,
            active: true
        });
        
        emit StreamOpened(
            streamId, msg.sender, payee, ratePerSecond
        );
        
        return streamId;
    }
}
```

### Step 2: Build the HTTP 402 Middleware

```python
# Python middleware for x402 payments
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import hashlib

app = FastAPI()

# Pricing: microseconds per API call
PRICING = {
    "/api/llm/inference": 100,  # 0.0001 QTA
    "/api/image/generate": 500, # 0.0005 QTA
    "/api/embed": 10,           # 0.00001 QTA
}

@app.middleware("http")
async def x402_middleware(request: Request, call_next):
    path = request.url.path
    
    if path in PRICING:
        # Check for payment proof
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("QUANTA "):
            return JSONResponse(
                status_code=402,
                content={
                    "error": "Payment Required",
                    "price": PRICING[path],
                    "receiver": "qta1your_address_here",
                    "protocol": "x402"
                },
                headers={
                    "X-QUANTA-Price": str(PRICING[path]),
                    "X-QUANTA-Receiver": "qta1...",
                }
            )
    
    response = await call_next(request)
    return response
```

### Step 3: Agent Client SDK

```typescript
import { createPublicClient, http } from 'viem';
import { base } from 'viem/chains';

interface X402Payment {
  price: number;
  receiver: string;
}

class X402Client {
  private privateKey: string;
  
  constructor(privateKey: string) {
    this.privateKey = privateKey;
  }
  
  async callAPI(url: string): Promise<any> {
    // First request — get price
    const priceResp = await fetch(url);
    
    if (priceResp.status === 402) {
      const pricing: X402Payment = await priceResp.json();
      
      // Sign payment
      const proof = await this.signPayment(
        pricing.price,
        pricing.receiver
      );
      
      // Second request — with payment
      const dataResp = await fetch(url, {
        headers: {
          'Authorization': `QUANTA ${proof}`
        }
      });
      
      return dataResp.json();
    }
    
    return priceResp.json();
  }
  
  private async signPayment(
    price: number,
    receiver: string
  ): Promise<string> {
    // Sign with Dilithium3
    const msg = `PAY:${price}:${receiver}:${Date.now()}`;
    // ... sign with quantum-resistant key
    return signedProof;
  }
}
```

## Real-World Use Cases

### 1. LLM API Proxy
Each prompt costs 0.0001 QTA. Agent makes 10,000 calls/day = $1.00/day total.

### 2. GPU Compute Marketplace
Pay per GPU-second. 1 second of RTX 4090 = 0.01 QTA.

### 3. Data Feed Subscriptions
Stream real-time data at $0.00001/record. 1M records = $10.

### 4. Multi-Agent Collaboration
Agent A pays Agent B $0.001 per task completed. 1,000 tasks = $1.

## Getting Started

```bash
npm install @quanta/sdk
```

```typescript
import { QuantaSDK } from '@quanta/sdk';

const quanta = new QuantaSDK({
  chain: 'base-sepolia',
  privateKey: process.env.PRIVATE_KEY
});

// Open payment channel
const channel = await quanta.openChannel({
  receiver: '0x...',
  amount: parseEther('100'),
  duration: 86400 // 24 hours
});

// Pay for API call
const proof = await quanta.createPayment({
  channel: channel.id,
  amount: parseEther('0.0001')
});
```

## Conclusion

x402 isn't just a protocol — it's the economic layer for the AI agent economy. When billions of agents transact millions of times per second, you need sub-cent payments with quantum-resistant security.

QUANTA implements x402 natively. Try it on Base Sepolia today.

---

*GitHub: [quanta-tect/quanta](https://github.com/quanta-tect/quanta)*
