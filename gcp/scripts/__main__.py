"""
BC Registry SRE Scripts — Project Runner

Runs all scanning and reporting scripts in sequence.
Scripts that require arguments (e.g. --project) are configured here
with their production defaults.

Usage:
    # Run everything
    uv run --project gcp/scripts gcp/scripts/__main__.py

    # Run a specific group only
    uv run --project gcp/scripts gcp/scripts/__main__.py --only inventory
    uv run --project gcp/scripts gcp/scripts/__main__.py --only silver
    uv run --project gcp/scripts gcp/scripts/__main__.py --only endpoints
    uv run --project gcp/scripts gcp/scripts/__main__.py --only report

    # Skip specific tasks
    uv run --project gcp/scripts gcp/scripts/__main__.py --skip inventory endpoints
"""

import argparse
import subprocess
import sys
from datetime import datetime
from pathlib import Path

SCRIPTS_DIR = Path(__file__).parent
OUTPUT_DIR = SCRIPTS_DIR / "output"

# ── Task registry ─────────────────────────────────────────────────────────────
# Each task: (group, script_file, extra_argv, description)
TASKS = [
    # ── Inventory  ──────────────────────────────────────────────────
    ("inventory", "scan_gcp_projects.py", [], "Scan GCP project inventory"),
    (
        "inventory",
        "scan_app_inventory.py",
        [],
        "Scan app inventory, tech stacks & EOL deps",
    ),
    # ── Audit ───────────────────────────────────────────────────────────────
    ("audit", "audit_github_contributors.py", [], "Audit GitHub contributors"),
    # ── Uptime & endpoints ────────────────────────────────────────────────────
    ("endpoints", "scan_uptime_checks.py", [], "List GCP uptime checks"),
    (
        "endpoints",
        "scan_apigee_endpoints.py",
        ["--project", "okagqp-test"],
        "Scan Apigee proxies & KVM endpoints",
    ),
    # ── Silver cluster references ─────────────────────────────────────────────
    (
        "silver",
        "scan_openshift_silver_refs.py",
        [],
        "Scan Cloud Run env vars for Silver refs",
    ),
    (
        "silver",
        "scan_website_silver_refs.py",
        [],
        "Scan public websites for Silver refs",
    ),
    (
        "silver",
        "scan_1password_silver_refs.py",
        [],
        "Scan 1Password vaults for Silver refs",
    ),
    # ── SRE report (runs last — consumes output from above) ──────────────────
    ("report", "generate_sre_report.py", [], "Generate monthly SRE health report"),
]

GROUPS = sorted({t[0] for t in TASKS})


def run_script(script_path: Path, extra_argv: list[str]) -> tuple[bool, float]:
    """Run a script as a subprocess, streaming its output. Returns (success, elapsed_s)."""
    cmd = [
        sys.executable,
        "-m",
        "uv",
        "run",
        "--project",
        str(SCRIPTS_DIR),
        str(script_path),
    ] + extra_argv

    t0 = time.monotonic()
    try:
        result = subprocess.run(cmd, cwd=str(SCRIPTS_DIR.parent.parent))
        elapsed = time.monotonic() - t0
        return result.returncode == 0, elapsed
    except Exception as e:
        elapsed = time.monotonic() - t0
        print(f"  ⚠️  Exception: {e}")
        return False, elapsed


def print_banner(text: str, width: int = 60):
    print(f"\n{'═' * width}")
    print(f"  {text}")
    print(f"{'═' * width}")


def main():
    parser = argparse.ArgumentParser(description="Run all BC Registry SRE scripts")
    parser.add_argument(
        "--only",
        nargs="+",
        choices=GROUPS,
        metavar="GROUP",
        help=f"Only run scripts from these groups: {GROUPS}",
    )
    parser.add_argument(
        "--skip",
        nargs="+",
        choices=GROUPS,
        metavar="GROUP",
        help="Skip scripts from these groups",
    )
    parser.add_argument("--list", action="store_true", help="List all tasks and exit")
    args = parser.parse_args()

    if args.list:
        print(f"\n{'─' * 60}")
        print(f"  {'GROUP':<12} {'SCRIPT':<38} DESCRIPTION")
        print(f"{'─' * 60}")
        for group, script, argv, desc in TASKS:
            extra = f"  [{' '.join(argv)}]" if argv else ""
            print(f"  {group:<12} {script:<38} {desc}{extra}")
        print(f"{'─' * 60}\n")
        return

    # Filter tasks
    active_tasks = TASKS
    if args.only:
        active_tasks = [t for t in TASKS if t[0] in args.only]
    if args.skip:
        active_tasks = [t for t in active_tasks if t[0] not in args.skip]

    if not active_tasks:
        print("No tasks to run after applying filters.")
        return

    OUTPUT_DIR.mkdir(exist_ok=True)

    start_time = datetime.now()
    print_banner(f"BC Registry SRE Scripts  —  {start_time.strftime('%Y-%m-%d %H:%M')}")
    print(f"  Tasks to run : {len(active_tasks)}")
    print(f"  Output dir   : {OUTPUT_DIR}")

    results = []
    current_group = None

    for group, script, argv, desc in active_tasks:
        if group != current_group:
            current_group = group
            print(f"\n  ── {group.upper()} ──")

        script_path = SCRIPTS_DIR / script
        if not script_path.exists():
            print(f"  ⚠️  {script} not found, skipping.")
            results.append((script, desc, False, 0.0, "not found"))
            continue

        print(f"\n  ▶  {desc}")
        print(f"     {script}" + (f"  {' '.join(argv)}" if argv else ""))

        success, elapsed = run_script(script_path, argv)
        status = "✅" if success else "❌"
        results.append((script, desc, success, elapsed, ""))
        print(f"     {status}  {'done' if success else 'FAILED'}  ({elapsed:.1f}s)")

    # ── Summary ───────────────────────────────────────────────────────────────
    total_elapsed = (datetime.now() - start_time).total_seconds()
    passed = sum(1 for r in results if r[2])
    failed = len(results) - passed

    print_banner(
        f"SUMMARY  —  {passed}/{len(results)} passed  ({total_elapsed:.0f}s total)"
    )
    print(f"  {'STATUS':<4}  {'SCRIPT':<42} {'TIME':>6}")
    print(f"  {'──────':<4}  {'──────':<42} {'────':>6}")
    for script, desc, success, elapsed, note in results:
        icon = "✅" if success else "❌"
        note_str = f"  ({note})" if note else ""
        print(f"  {icon}    {script:<42} {elapsed:>5.1f}s{note_str}")

    if failed:
        print(f"\n  ⚠️  {failed} script(s) failed. Check output above.\n")
        sys.exit(1)
    else:
        print(f"\n  All reports saved to: {OUTPUT_DIR}\n")


if __name__ == "__main__":
    main()
