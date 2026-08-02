# Building AI Agents That Earn: The Autonomous Economy

**Meta:** How to build AI agents that transact autonomously — paying for APIs, earning from tasks, and managing their own finances. Tutorial with code examples.

**Tags:** ai-agents, autonomous, web3, payments, python

---

## The Vision

By 2030, AI agents will:
- Pay for their own API calls
- Earn money by completing tasks
- Hire other agents for subtasks
- Save and invest earnings

This is the autonomous agent economy. Let's build it.

## Agent Architecture

```
┌─────────────────────────────────────┐
│           AI AGENT                   │
├─────────────────────────────────────┤
│  Brain (LLM)                        │
│  ├── Decision making                │
│  ├── Task planning                  │
│  └── Communication                  │
├─────────────────────────────────────┤
│  Wallet (QUANTA)                    │
│  ├── Balance management             │
│  ├── Payment signing                │
│  └── Budget policies                │
├─────────────────────────────────────┤
│  Skills (Tools)                     │
│  ├── API calling                    │
│  ├── Data processing                │
│  └── Task execution                 │
└─────────────────────────────────────┘
```

## Step 1: Agent Wallet

```python
from quanta_sdk import QuantaSDK
from eth_account import Account

class AgentWallet:
    def __init__(self, private_key: str):
        self.account = Account.from_key(private_key)
        self.sdk = QuantaSDK(chain='base-sepolia')
        self.daily_budget = 10.0  # QTA
        self.spent_today = 0.0
        
    async def pay(self, to: str, amount: float, purpose: str):
        """Pay another agent or service."""
        if self.spent_today + amount > self.daily_budget:
            raise BudgetExceeded(
                f"Daily budget: {self.daily_budget}, "
                f"spent: {self.spent_today}"
            )
        
        tx_hash = await self.sdk.token.transfer(
            to=to,
            amount=str(amount)
        )
        
        self.spent_today += amount
        
        log.info(
            f"Agent {self.account.address} paid "
            f"{amount} QTA to {to} for {purpose}"
        )
        
        return tx_hash
    
    async def balance(self) -> float:
        bal = await self.sdk.token.balance_of(
            self.account.address
        )
        return float(bal) / 1e18
```

## Step 2: Agent Brain

```python
from openai import OpenAI

class AgentBrain:
    def __init__(self, model: str = "gpt-4"):
        self.client = OpenAI()
        self.model = model
        self.system_prompt = """You are an autonomous AI agent.
You can:
- Call APIs to get information
- Process data
- Make decisions
- Pay other agents for services

Always maximize value while staying within budget.
Log all decisions and reasoning."""
    
    async def think(self, task: str, context: dict) -> dict:
        """Think about a task and decide next action."""
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": self.system_prompt},
                {"role": "user", "content": f"""
Task: {task}
Context: {context}

What should I do next? Respond with JSON:
{{
    "action": "api_call|process|pay_agent|done",
    "target": "endpoint or agent address",
    "params": {{}},
    "reasoning": "why this action"
}}"""}
            ]
        )
        
        return json.loads(response.choices[0].message.content)
```

## Step 3: Agent Runner

```python
class AutonomousAgent:
    def __init__(self, name: str, private_key: str):
        self.name = name
        self.wallet = AgentWallet(private_key)
        self.brain = AgentBrain()
        self.skills = {}
        self.tasks_completed = 0
        
    async def run(self, task: str):
        """Execute a task autonomously."""
        log.info(f"Agent {self.name} starting task: {task}")
        
        context = {
            "task": task,
            "balance": await self.wallet.balance(),
            "daily_budget": self.wallet.daily_budget,
            "spent_today": self.wallet.spent_today,
        }
        
        while True:
            # Think
            decision = await self.brain.think(task, context)
            log.info(f"Decision: {decision['action']}")
            
            # Act
            if decision["action"] == "done":
                self.tasks_completed += 1
                log.info(f"Task completed! Total: {self.tasks_completed}")
                return decision
            
            elif decision["action"] == "api_call":
                result = await self.call_api(
                    decision["target"],
                    decision["params"]
                )
                context["last_result"] = result
            
            elif decision["action"] == "pay_agent":
                await self.wallet.pay(
                    to=decision["target"],
                    amount=decision["params"]["amount"],
                    purpose=task
                )
                context["balance"] = await self.wallet.balance()
            
            elif decision["action"] == "process":
                result = await self.process_data(
                    decision["params"]
                )
                context["last_result"] = result
```

## Step 4: Multi-Agent Collaboration

```python
class AgentNetwork:
    def __init__(self):
        self.agents = {}
        self.marketplace = AgentMarketplace()
    
    async def hire_agent(
        self, 
        hirer: AutonomousAgent,
        skill_needed: str,
        max_payment: float
    ) -> AutonomousAgent:
        """Hire another agent for a specific skill."""
        # Find available agents with the skill
        available = await self.marketplace.find_agents(
            skill=skill_needed,
            max_price=max_payment
        )
        
        if not available:
            raise NoAgentAvailable(
                f"No agent with skill: {skill_needed}"
            )
        
        # Hire cheapest qualified agent
        agent = min(available, key=lambda a: a.price_per_task)
        
        # Pay upfront
        await hirer.wallet.pay(
            to=agent.wallet.address,
            amount=agent.price_per_task,
            purpose=f"Hire for: {skill_needed}"
        )
        
        return agent
    
    async def collaborate(
        self, 
        agents: list,
        task: str
    ) -> dict:
        """Multiple agents collaborate on a task."""
        results = []
        
        for agent in agents:
            result = await agent.run(task)
            results.append(result)
        
        # Merge results
        return self.merge_results(results)
```

## Step 5: Revenue Generation

```python
class EarningAgent(AutonomousAgent):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.skills_offered = []
        self.earnings = 0.0
    
    def offer_skill(self, skill: str, price: float):
        """Register a skill on the marketplace."""
        self.skills_offered.append({
            "skill": skill,
            "price": price
        })
        
        self.marketplace.register(
            agent=self,
            skill=skill,
            price=price
        )
    
    async def accept_task(
        self, 
        task: dict, 
        payment: float
    ):
        """Accept and complete a paid task."""
        log.info(f"Accepted task: {task['description']}")
        
        # Execute task
        result = await self.run(task["description"])
        
        # Receive payment
        self.earnings += payment
        
        log.info(f"Earned {payment} QTA. Total: {self.earnings}")
        
        return result
```

## Running Your Agent

```python
# Create agent
agent = AutonomousAgent(
    name="DataMiner-001",
    private_key=os.getenv("AGENT_PRIVATE_KEY")
)

# Offer skills
agent.offer_skill("data_collection", price=0.1)
agent.offer_skill("data_analysis", price=0.5)
agent.offer_skill("report_writing", price=0.2)

# Run autonomously
async def main():
    while True:
        # Check for tasks
        tasks = await marketplace.get_available_tasks()
        
        for task in tasks:
            if task["price"] <= await agent.wallet.balance():
                await agent.accept_task(
                    task, 
                    task["price"]
                )
        
        # Sleep between checks
        await asyncio.sleep(60)

asyncio.run(main())
```

## Economics

| Metric | Value |
|--------|-------|
| Agent cost (per task) | 0.1 QTA |
| Agent revenue (per task) | 0.5 QTA |
| Profit margin | 80% |
| Tasks per day | 100 |
| Daily profit | 40 QTA |
| Monthly profit | 1,200 QTA |

## Getting Started

```bash
pip install quanta-sdk openai
```

```python
import os
from quanta_sdk import QuantaSDK

# Initialize
sdk = QuantaSDK(
    chain='base-sepolia',
    private_key=os.getenv("PRIVATE_KEY")
)

# Check balance
balance = await sdk.token.balance_of("0x...")
print(f"Balance: {balance} QTA")
```

## Conclusion

The autonomous agent economy is real. Agents that pay for themselves, earn money, and collaborate. QUANTA provides the payment rails. You build the agents.

---

*GitHub: [quanta-tect/quanta](https://github.com/quanta-tect/quanta)*
