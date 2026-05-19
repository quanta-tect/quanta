# 🎮 QUANTA War Games — Security Drill Scenarios

> **Purpose**: Practice incident response BEFORE it's real. Each scenario is a 30-60 minute exercise. Run quarterly minimum.
>
> **Format**: 1 facilitator (knows what's happening), team responds in real-time as if it's actually happening.

## 🎯 Why war games matter

Stats from past DeFi incidents:
- **47 min**: Average time to drain 80% of TVL once exploit starts
- **2.3 hours**: Average time from alarm to public statement (too slow!)
- **12 hours**: Average time to deploy fix
- **40%**: Of teams couldn't reach all multisig signers within 1 hour

Teams that **practiced** beat those averages by 5-10x.

## 📋 Drill checklist (run for each scenario)

Before drill:
- [ ] Facilitator picks scenario + injects "facts" in stages
- [ ] All on-call members participate (treat as real)
- [ ] Use real tools (Safe, Tenderly, Discord) but on testnet
- [ ] Time everything

During drill:
- [ ] Record decisions + timestamps
- [ ] Don't help team if they're stuck (that's the lesson)
- [ ] Inject curveballs (e.g., "signer 2 is on vacation, unreachable")

After drill:
- [ ] Post-mortem within 24 hours
- [ ] What went well? What broke down?
- [ ] Update runbook based on learnings
- [ ] Schedule next drill

---

## Scenarios available

| ID | Scenario | Difficulty | Duration |
|----|----------|-----------|----------|
| [WG-01](./WG-01-active-exploit.md) | Active exploit draining funds | 🔥🔥🔥 Hard | 60 min |
| [WG-02](./WG-02-signer-compromise.md) | Multisig signer compromised | 🔥🔥 Medium | 45 min |
| [WG-03](./WG-03-frontend-hack.md) | Frontend supply chain attack | 🔥🔥🔥 Hard | 60 min |
| [WG-04](./WG-04-zero-day-disclosure.md) | Whitehat reports critical bug | 🔥 Easy | 30 min |
| [WG-05](./WG-05-oracle-failure.md) | Oracle returns bad data | 🔥🔥 Medium | 45 min |
| [WG-06](./WG-06-bridge-anomaly.md) | Unusual bridge mint pattern | 🔥🔥 Medium | 45 min |

## 📊 Scoring rubric

After each drill, score 0-5 on:

| Criterion | 0 (fail) | 5 (excellent) |
|-----------|----------|---------------|
| **Detection time** | >30 min | <2 min |
| **Pause time (if needed)** | >60 min | <15 min |
| **All signers reached** | <50% in 1h | 100% in 15 min |
| **Public communication** | Confused/late | Clear/timely |
| **Decision quality** | Wrong calls | Optimal calls |
| **Forensics** | Couldn't reconstruct | Full clarity in 1h |

**Target**: Average score >4 across all criteria within 6 months of practice.

## 🏆 Maturity levels

- **Level 1 (untested)**: Never drilled. Will fail real incident.
- **Level 2 (basic)**: Drilled once, learned. Some panic.
- **Level 3 (competent)**: Quarterly drills. Smooth execution.
- **Level 4 (advanced)**: Monthly drills. Sub-15-min response.
- **Level 5 (elite)**: Continuous chaos engineering. Bots randomly drill.

**Most surviving DeFi teams are Level 3-4.**

---

## How to use

```bash
# Pick a scenario
cat WG-01-active-exploit.md

# Schedule with team (don't tell them which scenario!)
# Use Signal: "Drill on Friday 3pm, 1 hour, all on-call participate"

# Facilitator prepares:
# - Reads scenario + appendix
# - Sets up Tenderly fork to simulate "exploit" if needed
# - Prepares "alerts" to inject at right times

# During: facilitator drips info, team responds
# After: 30-min post-mortem
```

## Resources

- **Tenderly War Room** ($0 to $500/month) — collaborate during incidents
- **Forta** — receive real testnet alerts during drill
- **OpenZeppelin Defender** — practice timelock operations
- **PagerDuty trial** — practice on-call alerting

---

**The best time to learn incident response is BEFORE the incident.**
**The second best time is during quarterly drills.**
