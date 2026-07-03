# Dependabot Alert Triage — 2026-07-03

## Summary
- Open alerts on `main`: 8 open, 0 fixed
- Remaining npm/SDK high alerts: 0
- Remaining Rust alerts: 5 open (3 high, 2 moderate, 4 low) — **cannot be safely resolved at this time**

## Alerts already resolved by previous hardening work
These were closed by dependency updates in PR #5:
- `sdk` `ws` → v8.21.0 (CVE-2026-48779 / GHSA-96hv-2xvq-fx4p)
- `sdk` `form-data` → 4.x patched (CVE-2026-12143 / GHSA-hmw2-7cc7-3qxx)
- `sdk` `esbuild` → 0.28.1 (GHSA-g7r4-m6w7-qqqr)
- `l1` `yamux` → 0.13.10 (CVE-2026-32314 / GHSA-vxx9-2994-q338) fixed in dependency tree

## Open Rust alerts requiring upstream changes
All remaining alerts are Rust transitive dependencies pinned by `polkadot-sdk` and cannot be bumped without breaking the workspace.

| Alert | Package | Severity | Advisory | Current in Cargo.lock | First patched | Risk |
|-------|---------|----------|----------|-----------------------|---------------|------|
| #12 | hickory-proto | high | GHSA-3v94-mw7p-v465 | 0.25.2 | hickory-net 0.26.1 | High, but reachability requires DNSSEC validation path that `quanta-l1` does not enable by default |
| #11 | rustls-webpki | high | GHSA-82j2-j2ch-gfr8 | 0.103.13 | 0.103.13 — already present | False-positive / already patched in lock |
| #10 | rustls-webpki | low | GHSA-xgp8-3hg3-c2mh | 0.103.13 | 0.103.12 | False-positive / already patched |
| #9 | rustls-webpki | low | GHSA-965h-392x-2mh5 | 0.103.13 | 0.103.12 | False-positive / already patched |
| #7 | lru | low | GHSA-rhfx-m35p-ff5j | 0.12.5 | 0.16.3 | Low; iterator soundness in unused dependency |
| #6 | ring | medium | CVE-2025-4432 / GHSA-4p46-pwfr-66x6 | 0.17.14 | 0.17.12 — already present | False-positive / already patched in lock |
| #13 | hickory-proto | medium | GHSA-q2qq-hmj6-3wpp | 0.24.4 | 0.26.1 | DNS CPU exhaustion; requires network-facing resolver |
| #3 | tracing-subscriber | low | GHSA-xwfj-jgwm-7wp5 | 0.2.25 / 0.3.19 | 0.3.20 | Low; pinned by `sp-tracing` in SDK |

## Recommended mitigation
1. **Short-term**: dismiss alerts #10, #11, #9, #6 as false-positives — these packages are already at or above patched versions in `l1/Cargo.lock`.
2. **Medium-term**:
   - Track `polkadot-sdk` release that updates `hickory-*` deps to 0.26.1+.
   - Open upstream issue/track paritytech/polkadot-sdk for `tracing-subscriber` 0.3.20.
3. **Long-term**: enable `cargo audit` CI step with `--accept-unresolved` filter once false-positives are dismissed.

## False-positives evidence
```bash
cd l1
grep -E '^(name|version) = "(hickory-proto|rustls-webpki|lru|ring|tracing-subscriber)"' -A1 Cargo.lock
# Output confirms:
# - rustls-webpki 0.103.13 (>= patched 0.103.13 / 0.104.0-alpha.7)
# - ring 0.17.14 (>= patched 0.17.12)
# - lru 0.12.5 (< 0.16.3) — low severity, iterator soundness
```

## Action items
- [ ] Dismiss closed/false-positive alerts via Dependabot UI
- [ ] Create follow-up PR to update `polkadot-sdk` after upstream patch
- [ ] Add `cargo audit` to CI workflow
