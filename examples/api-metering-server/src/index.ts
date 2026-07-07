import 'dotenv/config';
import express from 'express';

type GenerationRequest = {
  agentId: string;
  prompt: string;
  maxTokens: number;
};

type MockReceipt = {
  agentId: string;
  prompt: string;
  maxTokens: number;
  usageSimulated: number;
  costSimulated: string;
  policyMaxAllowance: string;
  allowed: boolean;
  note: string;
};

type ErrorResponse = {
  error: string;
  addresses?: {
    token: string;
    registry: string;
    channel: string;
    marketplace: string;
  };
  spentToday?: string;
  maxAllowance?: string;
};

const app = express();
app.use(express.json());

const isRealMode = Boolean(process.env.QUANTA_RPC_URL?.trim());

function assertString(value: unknown, label: string): asserts value is string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`${label} is required`);
  }
}

function parseEnvAddress(label: string): string {
  const value = process.env[label];
  assertString(value, label);
  return value.trim();
}

const MOCK_POLICY: Record<string, { maxAllowance: bigint; spentToday: bigint }> = {
  'agent-Agent-001': {
    maxAllowance: BigInt(100000),
    spentToday: BigInt(0),
  },
};

function mockCheckPolicy(agentId: string): { allowed: boolean; spentToday: bigint; maxAllowance: bigint } {
  const policy = MOCK_POLICY[agentId];
  if (!policy) {
    return { allowed: false, spentToday: BigInt(0), maxAllowance: BigInt(0) };
  }
  return { allowed: true, spentToday: policy.spentToday, maxAllowance: policy.maxAllowance };
}

function mockRecordSpend(agentId: string, units: bigint): void {
  const policy = MOCK_POLICY[agentId];
  if (policy) {
    policy.spentToday = policy.spentToday + units;
  }
}

function createMockReceipt(
  agentId: string,
  prompt: string,
  maxTokens: number,
  usageSimulated: number
): MockReceipt {
  const costSimulated = '0.00001';
  return {
    agentId,
    prompt,
    maxTokens,
    usageSimulated,
    costSimulated,
    policyMaxAllowance: '100000',
    allowed: true,
    note: 'Mock receipt only. No on-chain settlement.',
  };
}

app.get('/health', (_req: express.Request, res: express.Response) => {
  res.json({ status: 'ok', mode: isRealMode ? 'real' : 'mock' });
});

app.post('/api/generate', async (req: express.Request, res: express.Response) => {
  const body = req.body as GenerationRequest;
  const agentId = String(body?.agentId ?? '').trim();
  const prompt = String(body?.prompt ?? '').trim();
  const maxTokens = Number(body?.maxTokens ?? 0);

  if (!agentId || !prompt || !Number.isFinite(maxTokens) || maxTokens <= 0) {
    return res.status(400).json({ error: 'agentId, prompt, and positive maxTokens are required' } satisfies ErrorResponse);
  }

  if (isRealMode) {
    // Real mode: document the safe integration surface.
    // 1) Load registry/channel/addresses from env.
    // 2) Call the registry or SDK to verify:
    //    - agent exists
    //    - spending policy allows this request
    // 3) Execute the upstream API/model call.
    // 4) Record spend through the payment channel or marketplace.
    // Uncommenting a full real implementation requires more SDK work.
    try {
      const tokenAddress = parseEnvAddress('QUANTA_CONTRACT_TOKEN');
      const registryAddress = parseEnvAddress('QUANTA_CONTRACT_REGISTRY');
      const channelAddress = parseEnvAddress('QUANTA_CONTRACT_CHANNEL');
      const marketplaceAddress = parseEnvAddress('QUANTA_CONTRACT_MARKETPLACE');
      void tokenAddress;
      void registryAddress;
      void channelAddress;
      void marketplaceAddress;

      // Example placeholders (kept minimal by design):
      // let sender = createWalletClient({ ... });
      // let registry = getQuantaContracts({ rpcUrl: process.env.QUANTA_RPC_URL }).registry;
      // let policy = await readContract(sender, { ... registry abi ..., 'getPolicy', [agentId] });
      // if (policy.maxPerDay < estimatedCost) reject;
      // await writeContract(sender, { ... channel abi ..., 'recordSpend', [agentId, value, nonce] });

      return res.status(501).json({
        error: 'Real mode is configured but not implemented in this example yet.',
        addresses: {
          token: tokenAddress,
          registry: registryAddress,
          channel: channelAddress,
          marketplace: marketplaceAddress,
        },
      } satisfies ErrorResponse);
    } catch (err) {
      return res.status(500).json({
        error: err instanceof Error ? err.message : 'real mode initialization failed',
      } satisfies ErrorResponse);
    }
  }

  // Mock mode.
  const usageSimulated = Math.max(1, Math.floor(maxTokens));
  const usageUnits = BigInt(usageSimulated);

  const policyResult = mockCheckPolicy(agentId);
  if (!policyResult.allowed) {
    return res.status(403).json({
      error: 'Agent not found or not allowed in mock policy',
    } satisfies ErrorResponse);
  }

  const estimatedCost = usageUnits;
  if (policyResult.spentToday + estimatedCost > policyResult.maxAllowance) {
    return res.status(402).json({
      error: 'Mock policy spend limit exceeded',
      spentToday: policyResult.spentToday.toString(),
      maxAllowance: policyResult.maxAllowance.toString(),
    } satisfies ErrorResponse);
  }

  mockRecordSpend(agentId, estimatedCost);

  const receipt = createMockReceipt(agentId, prompt, maxTokens, usageSimulated);
  return res.json(receipt);
});

const port = Number(process.env.PORT ?? 3000);
app.listen(port, () => {
  const mode = isRealMode ? 'real' : 'mock';
  console.log(`API metering server listening on http://localhost:${port} (${mode} mode)`);
});
