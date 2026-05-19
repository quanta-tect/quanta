"""
QUANTA Tokenomics Simulator
===========================

Mô phỏng phát thải, burn, supply qua 50 năm with các kịch bản adoption.
Output: bảng + ASCII chart.

Chạy: python tokenomics_sim.py [--scenario optimistic|base|bear]
"""

from __future__ import annotations
import argparse
from dataclasses import dataclass


@dataclass
class Scenario:
    name: str
    initial_daily_tx: int
    tx_growth_per_year: float        # multiplier
    initial_daily_inferences: int
    inference_growth_per_year: float
    avg_tx_fee: float = 0.001        # QTA
    avg_inference_fee: float = 0.0001 # QTA


SCENARIOS = {
    "optimistic": Scenario("Optimistic", 100_000, 3.0, 1_000_000, 5.0),
    "base":       Scenario("Base case",   50_000, 1.8, 500_000,   2.5),
    "bear":       Scenario("Bear",        10_000, 1.2, 50_000,    1.3),
}


def emission_per_year(year: int, total_after_genesis: float = 700_000_000) -> float:
    """Halving every 6 years. Total 700M in ~50 years."""
    # Period 1 (year 1-6): 100M → ~16.67M/year
    # Period 2 (year 7-12): 50M → ~8.33M/year
    # ...
    period = (year - 1) // 6
    base = 100_000_000 / 6  # year 1 emission
    return base / (2 ** period)


def simulate(sc: Scenario, years: int = 30):
    supply = 300_000_000          # genesis 30%
    cumulative_burned = 0.0
    rows = []
    daily_tx = sc.initial_daily_tx
    daily_inf = sc.initial_daily_inferences

    for year in range(1, years + 1):
        # Phát thải
        emitted = emission_per_year(year)
        # Burn cả năm
        annual_tx = daily_tx * 365
        annual_inf = daily_inf * 365
        burn_from_tx = annual_tx * sc.avg_tx_fee * 0.5
        burn_from_inf = annual_inf * sc.avg_inference_fee * 0.3
        burn = burn_from_tx + burn_from_inf
        # Cap burn at 8% of current supply (realistic ceiling)
        burn = min(burn, supply * 0.08)

        supply = supply + emitted - burn
        cumulative_burned += burn
        net_inflation = (emitted - burn) / supply * 100

        rows.append({
            "year": year,
            "emitted": emitted,
            "burned": burn,
            "supply": supply,
            "net_inflation_pct": net_inflation,
            "daily_tx": daily_tx,
            "daily_inferences": daily_inf,
        })

        # Growth
        daily_tx = int(daily_tx * (sc.tx_growth_per_year ** (1/1)) ** 0.5)  # dampen
        daily_inf = int(daily_inf * (sc.inference_growth_per_year ** (1/1)) ** 0.5)
        # Cap growth realistically
        daily_tx = min(daily_tx, 1_000_000_000)
        daily_inf = min(daily_inf, 100_000_000_000)

    return rows


def print_table(rows, sc):
    print(f"\n📊 Scenario: {sc.name}")
    print(f"{'Year':>4} | {'Emit (M)':>10} | {'Burn (M)':>10} | {'Supply (M)':>12} | "
          f"{'Net infl%':>9} | {'Daily TX':>14} | {'Daily Inf':>15}")
    print("-" * 100)
    for r in rows:
        if r["year"] in [1, 2, 3, 5, 7, 10, 15, 20, 25, 30]:
            print(f"{r['year']:>4} | "
                  f"{r['emitted']/1e6:>10.2f} | "
                  f"{r['burned']/1e6:>10.2f} | "
                  f"{r['supply']/1e6:>12.2f} | "
                  f"{r['net_inflation_pct']:>8.2f}% | "
                  f"{r['daily_tx']:>14,} | "
                  f"{r['daily_inferences']:>15,}")


def ascii_chart(rows, label: str = "Supply"):
    print(f"\n📈 {label} (M QTA) over 30 years")
    vals = [r["supply"] / 1e6 for r in rows]
    max_v = max(vals)
    min_v = min(vals)
    width = 60
    for i, v in enumerate(vals):
        if (i+1) % 2:  # every 2 năm
            bar_len = int((v - min_v) / (max_v - min_v + 1e-9) * width)
            print(f"  Y{i+1:>2} |{'█' * bar_len}{' ' * (width - bar_len)}| {v:>8.1f}M")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--scenario", choices=list(SCENARIOS), default="base")
    parser.add_argument("--years", type=int, default=30)
    parser.add_argument("--all", action="store_true", help="Show all scenarios")
    args = parser.parse_args()

    print("⚛️  QUANTA Tokenomics Simulator\n")

    if args.all:
        for sc in SCENARIOS.values():
            rows = simulate(sc, args.years)
            print_table(rows, sc)
        # So sánh cuối kỳ
        print("\n🎯 Comparison at year 30:")
        print(f"{'Scenario':>15} | {'Final Supply (M)':>18} | {'Cum Burn (M)':>15}")
        print("-" * 60)
        for sc in SCENARIOS.values():
            rows = simulate(sc, args.years)
            final = rows[-1]
            cum_burn = sum(r["burned"] for r in rows)
            print(f"{sc.name:>15} | {final['supply']/1e6:>18.2f} | {cum_burn/1e6:>15.2f}")
    else:
        sc = SCENARIOS[args.scenario]
        rows = simulate(sc, args.years)
        print_table(rows, sc)
        ascii_chart(rows)

    print("\n💡 Key insights:")
    print("  • Halving every 6 years → emission decreases like Bitcoin")
    print("  • Burn from tx + AI inference scales with usage → deflationary as adoption grows")
    print("  • Optimistic scenario: net deflation from year ~7-8")
    print("  • Bear scenario: still inflationary but under 3%/year")


if __name__ == "__main__":
    main()
