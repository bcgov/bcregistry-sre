# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "httpx",
#     "python-dotenv",
# ]
# ///
"""
Scan all 1Password Connect vaults for item field values that reference
the OpenShift Silver cluster (silver.devops.gov.bc.ca).

Authentication uses the 1Password Connect API — no `op` CLI sign-in needed.

Required environment variables (export or add to .env):
    OP_CONNECT_HOST   <your Connect API endpoint>
    OP_CONNECT_TOKEN  <your Connect API token>

Usage:
    uv run scan_1password_silver_refs.py
    uv run scan_1password_silver_refs.py --target gold.devops.gov.bc.ca
    uv run scan_1password_silver_refs.py --vaults "DevOps" "Shared"
    uv run scan_1password_silver_refs.py --output /tmp/1p_silver.md
    uv run scan_1password_silver_refs.py --show-values
"""

import argparse
import os
import sys
from datetime import datetime
from pathlib import Path

import httpx
from dotenv import load_dotenv

# ── Defaults ──────────────────────────────────────────────────────────────────
DEFAULT_TARGET = "silver.devops.gov.bc.ca"
OUTPUT_DIR = Path(__file__).parent / "output"

# Field types that never contain URLs — skip to avoid noise
SKIP_FIELD_TYPES = {"TOTP", "OTP", "totp", "otp", "DATE", "MONTH_YEAR"}

CONTEXT_WINDOW = 120  # chars of context around each match


# ── 1Password Connect client ──────────────────────────────────────────────────


class ConnectClient:
    """Thin wrapper around the 1Password Connect REST API."""

    def __init__(self, host: str, token: str):
        self._base = host.rstrip("/")
        self._client = httpx.Client(
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            timeout=30,
        )

    def _get(self, path: str) -> list | dict | None:
        url = f"{self._base}{path}"
        try:
            resp = self._client.get(url)
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as exc:
            print(f"  ⚠️  HTTP {exc.response.status_code} for {url}")
            return None
        except Exception as exc:
            print(f"  ⚠️  Request failed for {url}: {exc}")
            return None

    def list_vaults(self) -> list[dict]:
        data = self._get("/v1/vaults")
        return data if isinstance(data, list) else []

    def list_items(self, vault_id: str) -> list[dict]:
        data = self._get(f"/v1/vaults/{vault_id}/items")
        return data if isinstance(data, list) else []

    def get_item(self, vault_id: str, item_id: str) -> dict | None:
        data = self._get(f"/v1/vaults/{vault_id}/items/{item_id}")
        return data if isinstance(data, dict) else None

    def close(self):
        self._client.close()


# ── Scanning helpers ───────────────────────────────────────────────────────────


def extract_context(text: str, index: int, window: int = CONTEXT_WINDOW) -> str:
    start = max(0, index - window)
    end = min(len(text), index + window)
    return text[start:end].replace("\n", " ").replace("\r", "").strip()


def mask_value(value: str, target: str) -> str:
    """Show only the portion around the target; redact the rest."""
    idx = value.lower().find(target.lower())
    if idx == -1:
        return "[REDACTED]"
    start = max(0, idx - 40)
    end = min(len(value), idx + len(target) + 40)
    snippet = value[start:end]
    return f"{'...' if start > 0 else ''}{snippet}{'...' if end < len(value) else ''}"


def scan_item(item: dict, target: str, show_values: bool) -> list[dict]:
    """Return a list of match dicts for every field value containing target."""
    matches: list[dict] = []
    target_lower = target.lower()

    # Check the item's URL list
    for url_entry in item.get("urls", []):
        href = url_entry.get("href", "")
        if target_lower in href.lower():
            idx = href.lower().find(target_lower)
            matches.append(
                {
                    "field_label": "[URL entry]",
                    "field_type": "URL",
                    "value_display": href if show_values else mask_value(href, target),
                    "context": extract_context(href, idx),
                }
            )

    # Check every field value
    for field in item.get("fields", []):
        ftype = field.get("type", "")
        if ftype in SKIP_FIELD_TYPES:
            continue

        value = field.get("value", "")
        if not isinstance(value, str) or not value:
            continue

        if target_lower in value.lower():
            idx = value.lower().find(target_lower)
            label = field.get("label") or field.get("id") or ftype or "unknown"
            matches.append(
                {
                    "field_label": label,
                    "field_type": ftype,
                    "value_display": value
                    if show_values
                    else mask_value(value, target),
                    "context": extract_context(value, idx),
                }
            )

    return matches


# ── Main ──────────────────────────────────────────────────────────────────────


def main():
    load_dotenv()

    parser = argparse.ArgumentParser(
        description="Scan 1Password Connect vaults for Silver cluster references"
    )
    parser.add_argument(
        "--target",
        default=DEFAULT_TARGET,
        help=f"Substring to search for (default: {DEFAULT_TARGET})",
    )
    parser.add_argument(
        "--vaults",
        nargs="+",
        metavar="VAULT",
        help="Vault name(s) to scan (default: all accessible vaults)",
    )
    parser.add_argument(
        "--output",
        metavar="PATH",
        help="Output Markdown file path (default: output/1password_silver_refs_<date>.md)",
    )
    parser.add_argument(
        "--show-values",
        action="store_true",
        help="Include full plaintext field values in the report (default: masked)",
    )
    parser.add_argument(
        "--no-report",
        action="store_true",
        help="Print to stdout only; skip writing the Markdown report",
    )
    args = parser.parse_args()

    # ── Auth ──────────────────────────────────────────────────────────────────
    connect_host = os.environ.get("OP_CONNECT_HOST", "").strip()
    connect_token = os.environ.get("OP_CONNECT_TOKEN", "").strip()

    if not connect_host or not connect_token:
        print("❌  Missing required environment variables:")
        if not connect_host:
            print(
                "      OP_CONNECT_HOST  (e.g. https://vault-service.apps.gold.devops.gov.bc.ca)"
            )
        if not connect_token:
            print("      OP_CONNECT_TOKEN  (your Connect bearer token)")
        print("\n  Export them or add them to .env and retry.")
        sys.exit(1)

    target: str = args.target
    show_values: bool = args.show_values
    today = datetime.now().strftime("%Y-%m-%d")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output_path = (
        Path(args.output)
        if args.output
        else OUTPUT_DIR / f"1password_silver_refs_{today}.md"
    )

    # ── Banner ────────────────────────────────────────────────────────────────
    print(f"\n{'=' * 64}")
    print(f"  1Password Connect  —  Silver Reference Scanner")
    print(f"{'=' * 64}")
    print(f"  Connect host : {connect_host}")
    print(f"  Target       : {target}")
    print(f"  Vaults       : {', '.join(args.vaults) if args.vaults else 'ALL'}")
    print(f"  Output       : {output_path}")
    print(f"{'=' * 64}\n")

    client = ConnectClient(connect_host, connect_token)

    # ── Discover vaults ───────────────────────────────────────────────────────
    all_vaults = client.list_vaults()
    if not all_vaults:
        print("❌  No vaults returned. Check OP_CONNECT_HOST and OP_CONNECT_TOKEN.")
        sys.exit(1)

    if args.vaults:
        names_lower = {n.lower() for n in args.vaults}
        vaults = [v for v in all_vaults if v.get("name", "").lower() in names_lower]
        if not vaults:
            print(f"❌  None of the specified vaults found: {args.vaults}")
            print(f"    Available: {[v.get('name') for v in all_vaults]}")
            sys.exit(1)
    else:
        vaults = all_vaults

    print(f"  Found {len(vaults)} vault(s) to scan.\n")

    # ── Scan ──────────────────────────────────────────────────────────────────
    # {vault_name: {item_title: [match_dict, ...]}}
    all_findings: dict[str, dict[str, list[dict]]] = {}
    total_items_scanned = 0
    total_matches = 0
    errors = 0

    for vault in vaults:
        vault_id = vault.get("id", "")
        vault_name = vault.get("name", vault_id)

        print(f"  📂  Vault: {vault_name!r}")
        items = client.list_items(vault_id)
        print(f"       {len(items)} item(s)")

        vault_findings: dict[str, list[dict]] = {}

        for stub in items:
            item_id = stub.get("id", "")
            item_title = stub.get("title", item_id)

            detail = client.get_item(vault_id, item_id)
            if detail is None:
                errors += 1
                continue

            total_items_scanned += 1
            matches = scan_item(detail, target, show_values)

            if matches:
                vault_findings[item_title] = matches
                total_matches += len(matches)
                plural = "es" if len(matches) != 1 else ""
                print(
                    f"       🔴  {item_title!r}  ({len(matches)} field match{plural})"
                )

        if vault_findings:
            all_findings[vault_name] = vault_findings
        else:
            print(f"       ✅  No matches.")
        print()

    client.close()

    # ── Console summary ───────────────────────────────────────────────────────
    print(f"\n{'=' * 64}")
    print(f"  RESULTS")
    print(f"  Vaults scanned : {len(vaults)}")
    print(f"  Items scanned  : {total_items_scanned}")
    print(f"  Total matches  : {total_matches}")
    print(f"  Errors         : {errors}")
    print(f"{'=' * 64}")

    if all_findings:
        for vault_name, vault_findings in all_findings.items():
            print(f"\n  📂 {vault_name}")
            for item_title, matches in vault_findings.items():
                print(f"     🔑 {item_title!r}")
                for m in matches:
                    print(f"        └─ [{m['field_label']}]  {m['value_display']}")
    else:
        print(f"\n  ✅  No references to '{target}' found in any vault.")

    # ── Markdown report ───────────────────────────────────────────────────────
    if args.no_report:
        return

    md: list[str] = [
        "# 1Password Silver Cluster Reference Scan",
        "",
        f"**Generated:** {today}  ",
        f"**Connect host:** `{connect_host}`  ",
        f"**Target:** `{target}`  ",
        f"**Vaults scanned:** {len(vaults)}  ",
        f"**Items scanned:** {total_items_scanned}  ",
        f"**Total field matches:** {total_matches}  ",
        f"**Errors:** {errors}",
        "",
        "---",
        "",
        "## Summary",
        "",
        "| Vault | Item | Field | Value |",
        "|:------|:-----|:------|:------|",
    ]

    if all_findings:
        for vault_name, vault_findings in all_findings.items():
            for item_title, matches in vault_findings.items():
                for m in matches:
                    val = m["value_display"].replace("|", "\\|")[:200]
                    md.append(
                        f"| {vault_name} | {item_title} | `{m['field_label']}` | `{val}` |"
                    )
    else:
        md.append("| — | *No matches found* | — | — |")

    md += ["", "---", "", "## Per-Vault Detail", ""]

    if all_findings:
        for vault_name, vault_findings in all_findings.items():
            md.append(f"### 📂 {vault_name}\n")
            for item_title, matches in vault_findings.items():
                md.append(f"#### 🔑 `{item_title}`\n")
                md += [
                    "| Field | Type | Value | Context |",
                    "|:------|:-----|:------|:--------|",
                ]
                for m in matches:
                    val = m["value_display"].replace("|", "\\|")[:200]
                    ctx = m["context"].replace("|", "\\|")[:150]
                    md.append(
                        f"| `{m['field_label']}` | {m['field_type']} | `{val}` | `{ctx}` |"
                    )
                md.append("")
    else:
        md.append(f"✅ No references to `{target}` found in any scanned vault.\n")

    md += [
        "---",
        "",
        "> **Note:** Values are masked by default. "
        "Re-run with `--show-values` to include full plaintext values.",
        "",
    ]

    output_path.write_text("\n".join(md), encoding="utf-8")
    print(f"\n  Report saved → {output_path}")
    print(f"{'=' * 64}\n")


if __name__ == "__main__":
    main()
