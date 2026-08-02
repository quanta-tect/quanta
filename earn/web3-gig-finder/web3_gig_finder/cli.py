"""CLI entry point for web3-gig-finder."""

import csv
import json
import sys
from pathlib import Path

try:
    import click
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich import box
except ImportError:
    print("Install dependencies: pip install click rich")
    sys.exit(1)

from .data import SAMPLE_JOBS, SAMPLE_GRANTS, SAMPLE_AUDITS
from .cover_letter import generate_cover_letter

console = Console()

SKILL_ALIASES = {
    "eth": ["solidity", "ethereum"],
    "sol": ["solidity"],
    "defi": ["defi", "solidity"],
    "ai": ["ai", "python", "ml"],
    "ml": ["ml", "python", "ai"],
    "web3": ["web3", "blockchain"],
    "frontend": ["react", "typescript", "web3"],
    "backend": ["rust", "python", "go"],
    "mobile": ["flutter", "swift", "ios", "android"],
}


def expand_skill(skill: str) -> list[str]:
    """Expand skill alias to full list."""
    s = skill.lower().strip()
    if s in SKILL_ALIASES:
        return SKILL_ALIASES[s]
    return [s]


def match_skill(job_skills: list[str], filter_skills: list[str]) -> bool:
    """Check if job matches any of the filter skills."""
    expanded = []
    for s in filter_skills:
        expanded.extend(expand_skill(s))
    expanded = set(expanded)
    return any(s.lower() in expanded for s in job_skills)


@click.group()
def main():
    """web3-gig-finder: Find Web3/Blockchain freelance jobs & bounties."""
    pass


@main.command()
@click.option("--skill", "-s", multiple=True, help="Filter by skill (solidity, rust, ai, etc.)")
@click.option("--sort", "-t", type=click.Choice(["pay", "title", "company"]), default="pay", help="Sort by")
@click.option("--export", "-e", type=str, help="Export to CSV file")
@click.option("--json", "-j", "export_json", is_flag=True, help="Export to JSON")
def scan(skill, sort, export, export_json):
    """Scan available Web3 jobs."""
    jobs = list(SAMPLE_JOBS)

    # Filter by skill
    if skill:
        jobs = [j for j in jobs if match_skill(j["skills"], skill)]

    # Sort
    if sort == "pay":
        jobs.sort(key=lambda x: x["rate_num"], reverse=True)
    elif sort == "title":
        jobs.sort(key=lambda x: x["title"])
    elif sort == "company":
        jobs.sort(key=lambda x: x["company"])

    if not jobs:
        console.print("[yellow]No jobs found matching your filters.[/yellow]")
        return

    # Display
    console.print()
    table = Table(
        title=f"🔍 Web3 Jobs ({len(jobs)} results)",
        box=box.ROUNDED,
        show_lines=True,
    )
    table.add_column("#", style="dim", width=3)
    table.add_column("Title", style="cyan", max_width=30)
    table.add_column("Company", style="green")
    table.add_column("Rate", style="yellow", justify="right")
    table.add_column("Skills", style="magenta")
    table.add_column("URL", style="blue")

    for i, job in enumerate(jobs, 1):
        table.add_row(
            str(i),
            job["title"],
            job["company"],
            job["rate"],
            ", ".join(job["skills"]),
            job["url"],
        )

    console.print(table)
    console.print()

    # Export
    if export:
        with open(export, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=jobs[0].keys())
            writer.writeheader()
            writer.writerows(jobs)
        console.print(f"[green]✅ Exported to {export}[/green]")

    if export_json:
        out = json.dumps(jobs, indent=2, ensure_ascii=False)
        print(out)


@main.command()
def grants():
    """List available grant programs."""
    console.print()
    table = Table(
        title="💰 Web3 Grant Programs",
        box=box.ROUNDED,
        show_lines=True,
    )
    table.add_column("#", style="dim", width=3)
    table.add_column("Grant", style="cyan")
    table.add_column("Amount", style="yellow")
    table.add_column("Deadline", style="red")
    table.add_column("Requirements", style="green")
    table.add_column("URL", style="blue")

    for i, g in enumerate(SAMPLE_GRANTS, 1):
        table.add_row(
            str(i),
            g["name"],
            g["amount"],
            g["deadline"],
            g["requirements"],
            g["url"],
        )

    console.print(table)
    console.print()


@main.command()
def audits():
    """List available audit contests."""
    console.print()
    table = Table(
        title="🛡️ Audit Contests & Bug Bounties",
        box=box.ROUNDED,
        show_lines=True,
    )
    table.add_column("#", style="dim", width=3)
    table.add_column("Contest", style="cyan")
    table.add_column("Prize Pool", style="yellow")
    table.add_column("Duration", style="green")
    table.add_column("Skills", style="magenta")
    table.add_column("URL", style="blue")

    for i, a in enumerate(SAMPLE_AUDITS, 1):
        table.add_row(
            str(i),
            a["name"],
            a["prize"],
            a["duration"],
            ", ".join(a["skills"]),
            a["url"],
        )

    console.print(table)
    console.print()


@main.command()
@click.option("--job", "-j", required=True, help="Job title")
@click.option("--company", "-c", required=True, help="Company name")
@click.option("--skills", "-s", default="solidity, web3", help="Your skills (comma-separated)")
@click.option("--project", "-p", default="your innovative approach to Web3", help="What impresses you about the company")
@click.option("--output", "-o", type=str, help="Save to file")
def cover(job, company, skills, project, output):
    """Generate a cover letter template."""
    skill_list = [s.strip() for s in skills.split(",")]
    letter = generate_cover_letter(
        title=job,
        company=company,
        skills=skill_list,
        specific_project=project,
    )

    if output:
        Path(output).write_text(letter)
        console.print(f"[green]✅ Cover letter saved to {output}[/green]")
    else:
        console.print(Panel(letter, title="📝 Cover Letter", border_style="cyan"))


@main.command()
def stats():
    """Show job market statistics."""
    from collections import Counter

    all_skills = []
    for job in SAMPLE_JOBS:
        all_skills.extend(job["skills"])

    skill_counts = Counter(all_skills)
    avg_pay = sum(j["rate_num"] for j in SAMPLE_JOBS) / len(SAMPLE_JOBS)

    console.print()
    console.print(Panel("📊 Web3 Job Market Stats", border_style="cyan"))
    console.print(f"  Total jobs: {len(SAMPLE_JOBS)}")
    console.print(f"  Average pay: ${avg_pay:.0f}/hr")
    console.print(f"  Grant programs: {len(SAMPLE_GRANTS)}")
    console.print(f"  Audit contests: {len(SAMPLE_AUDITS)}")
    console.print()
    console.print("  [cyan]Top Skills:[/cyan]")
    for skill, count in skill_counts.most_common(10):
        bar = "█" * count
        console.print(f"    {skill:15} {bar} ({count})")
    console.print()


if __name__ == "__main__":
    main()
