# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "httpx",
#     "beautifulsoup4"
# ]
# ///
"""
Scan BC Registry public websites for embedded OpenShift Silver cluster URLs.

These are Nuxt/Vue SPAs where environment variables are baked into the HTML
or inline JavaScript at build time (via window.__NUXT__, process.env injection,
or <script> config blocks). This script fetches each site's HTML and referenced
JS bundles, then searches for Silver cluster URL patterns.

Usage:
    uv run scan_website_silver_refs.py
    uv run scan_website_silver_refs.py --target gold.devops.gov.bc.ca
    uv run scan_website_silver_refs.py --urls https://www.bcregistry.gov.bc.ca,https://account.bcregistry.gov.bc.ca
    uv run scan_website_silver_refs.py --output output/website_silver_refs.md
"""

import argparse
import os
import re
from datetime import datetime
from urllib.parse import urljoin, urlparse

import httpx
from bs4 import BeautifulSoup

# ── Known BC Registry public websites ─────────────────────────────────────────
DEFAULT_WEBSITES = [
    "https://www.bcregistry.gov.bc.ca",
    "https://account.bcregistry.gov.bc.ca",
    "https://developer.connect.gov.bc.ca",
    "https://www.names.bcregistry.gov.bc.ca",
    "https://business-dashboard.bcregistry.gov.bc.ca",
    "https://www.standalone-transition.business.bcregistry.gov.bc.ca",
    "https://www.corps.business.bcregistry.gov.bc.ca",
    "https://www.home.business.bcregistry.gov.bc.ca",
    "https://www.create.business.bcregistry.gov.bc.ca",
    "https://www.edit.business.bcregistry.gov.bc.ca",
    "https://www.business.bcregistry.gov.bc.ca",
    "https://www.pay.bcregistry.gov.bc.ca",
    "https://www.assets.bcregistry.gov.bc.ca/",
    "https://www.search.bcregistry.gov.bc.ca/",
    "https://namex.bcregistry.gov.bc.ca/",
    "https://www.business-registry-dashboard.bcregistry.gov.bc.ca/",
    "https://documents.bcregistry.gov.bc.ca/",
    "https://www.platform.shorttermrental.registry.gov.bc.ca/",
    "https://www.stratahotel.shorttermrental.registry.gov.bc.ca/",
    "https://host.shorttermrental.registry.gov.bc.ca/",
    "https://examiner.shorttermrental.registry.gov.bc.ca/",
    "https://www.examiner-dashboard.shorttermrental.registry.gov.bc.ca/",
    "https://people.business.bcregistry.gov.bc.ca/",
]

DEFAULT_TARGET = "silver.devops.gov.bc.ca"

# Extract URL-like strings containing the target from JS/HTML
URL_EXTRACT_PATTERN = re.compile(r'["\`](https?://[^\s"\'`<>]{5,})["\`]', re.IGNORECASE)

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
MAX_JS_BUNDLES = 20  # Max JS files to fetch per page (avoid fetching everything)
MAX_JS_SIZE = 10_000_000  # Skip JS files larger than 10MB


def extract_context(text: str, match_start: int, window: int = 120) -> str:
    """Return a snippet of text around a match position."""
    start = max(0, match_start - window)
    end = min(len(text), match_start + window)
    snippet = text[start:end].replace("\n", " ").replace("\r", "")
    return snippet.strip()


def scan_text(content: str, target: str, source_url: str) -> list[dict]:
    """Find all occurrences of target in content, with surrounding context."""
    findings = []
    seen_urls = set()

    # Find embedded URLs matching the target
    for m in URL_EXTRACT_PATTERN.finditer(content):
        url = m.group(1)
        if target.lower() in url.lower() and url not in seen_urls:
            seen_urls.add(url)
            context = extract_context(content, m.start())
            findings.append(
                {
                    "source": source_url,
                    "matched_url": url,
                    "context": context,
                }
            )

    # Also catch raw non-quoted occurrences (e.g. template literals, concatenations)
    for m in re.finditer(re.escape(target), content, re.IGNORECASE):
        ctx = extract_context(content, m.start())
        # Try to extract the full URL from the context
        url_in_ctx = re.search(
            r"https?://\S+" + re.escape(target) + r"\S*", ctx, re.IGNORECASE
        )
        found_url = (
            url_in_ctx.group(0).rstrip("\",;`'")
            if url_in_ctx
            else f"...(contains {target})..."
        )
        if found_url not in seen_urls:
            seen_urls.add(found_url)
            findings.append(
                {
                    "source": source_url,
                    "matched_url": found_url,
                    "context": ctx,
                }
            )

    return findings


def fetch(client: httpx.Client, url: str) -> str | None:
    """Fetch URL content, returning text or None on failure."""
    try:
        resp = client.get(url, follow_redirects=True, timeout=15)
        if resp.status_code == 200:
            return resp.text
    except Exception as e:
        print(f"  ⚠️  Could not fetch {url}: {e}")
    return None


def scan_website(client: httpx.Client, base_url: str, target: str) -> list[dict]:
    """Fetch a website's HTML and key JS bundles, scanning for Silver references."""
    findings = []
    parsed = urlparse(base_url)
    origin = f"{parsed.scheme}://{parsed.netloc}"

    print(f"\n  Fetching: {base_url}")
    html = fetch(client, base_url)
    if not html:
        print(f"  ⚠️  Failed to fetch page HTML.")
        return findings

    # Scan HTML directly
    html_findings = scan_text(html, target, f"{base_url} [HTML]")
    if html_findings:
        print(f"  Found {len(html_findings)} match(es) in page HTML.")
        findings.extend(html_findings)

    # Parse JS script tags
    soup = BeautifulSoup(html, "html.parser")
    script_tags = soup.find_all("script", src=True)

    js_urls = []
    for tag in script_tags:
        src = tag.get("src", "")
        if not src or ".js" not in src:
            continue
        full_url = urljoin(origin, src) if not src.startswith("http") else src
        js_urls.append(full_url)

    # Also scan inline scripts for nuxt/vue config injection
    for tag in soup.find_all("script", src=False):
        inline = tag.get_text()
        if target.lower() in inline.lower():
            inline_findings = scan_text(inline, target, f"{base_url} [inline script]")
            findings.extend(inline_findings)
            if inline_findings:
                print(
                    f"  Found {len(inline_findings)} match(es) in inline <script> block."
                )

    # Also collect _nuxt/ and assets/ JS from <link rel="preload"> tags
    preload_links = soup.find_all("link", rel=lambda r: r and "preload" in r)
    for link in preload_links:
        href = link.get("href", "")
        if ".js" in href:
            full_url = urljoin(origin, href) if not href.startswith("http") else href
            if full_url not in js_urls:
                js_urls.append(full_url)

    # Fetch and scan JS bundles (limit to avoid downloading the whole app)
    scanned_js = 0
    for js_url in js_urls[: MAX_JS_BUNDLES * 3]:  # try more, skip large ones
        if scanned_js >= MAX_JS_BUNDLES:
            break

        js_content = fetch(client, js_url)
        if not js_content:
            continue

        if len(js_content) > MAX_JS_SIZE:
            print(f"  ⏭  Skipping large bundle: {js_url} ({len(js_content) // 1024}KB)")
            continue

        scanned_js += 1
        if target.lower() in js_content.lower():
            js_findings = scan_text(js_content, target, js_url)
            if js_findings:
                print(f"  Found {len(js_findings)} match(es) in {js_url}")
                findings.extend(js_findings)

    return findings


def main():
    parser = argparse.ArgumentParser(
        description="Scan BC Registry websites for embedded Silver cluster URLs"
    )
    parser.add_argument(
        "--urls",
        help="Comma-separated list of website URLs to scan (uses defaults if omitted)",
    )
    parser.add_argument("--target", default=DEFAULT_TARGET, help="String to search for")
    parser.add_argument(
        "--output", help="Output Markdown file path (defaults to output/ folder)"
    )
    args = parser.parse_args()

    websites = (
        [u.strip() for u in args.urls.split(",")] if args.urls else DEFAULT_WEBSITES
    )
    target = args.target
    today = datetime.now().strftime("%Y-%m-%d")

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_path = args.output or os.path.join(
        OUTPUT_DIR, f"website_silver_refs_{today}.md"
    )

    print(f"{'=' * 60}")
    print(f"  Website Silver URL Scanner")
    print(f"{'=' * 60}")
    print(f"  Target  : {target}")
    print(f"  Sites   : {len(websites)}")
    print(f"{'=' * 60}")

    all_findings: dict[str, list[dict]] = {}
    total_matches = 0

    headers = {
        "User-Agent": "Mozilla/5.0 (BCRegistry-SRE-Scanner/1.0; +https://github.com/bcgov/bcregistry-sre)",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    }

    with httpx.Client(headers=headers, timeout=20) as client:
        for url in websites:
            findings = scan_website(client, url, target)
            if findings:
                all_findings[url] = findings
                total_matches += len(findings)
            else:
                print(f"  ✅ No Silver references found.")

    # ── Console summary ───────────────────────────────────────────────────────
    print(f"\n{'=' * 60}")
    print(f"  RESULTS  ({total_matches} match{'es' if total_matches != 1 else ''})")
    print(f"{'=' * 60}")
    for url, findings in all_findings.items():
        print(f"\n🌐 {url}")
        for f in findings:
            print(f"  └─ {f['matched_url']}")

    # ── Markdown report ───────────────────────────────────────────────────────
    md_lines = [
        f"# Website Silver Cluster URL Scan",
        "",
        f"**Generated:** {today}  ",
        f"**Target Pattern:** `{target}`  ",
        f"**Sites Scanned:** {len(websites)} | **Total Matches:** {total_matches}",
        "",
        "---",
        "",
        "## Summary",
        "",
        "| Website | Matched URL | Source |",
        "|:--------|:------------|:-------|",
    ]

    for url in websites:
        for f in all_findings.get(url, []):
            source_short = f["source"].replace(url, "").strip() or "[HTML]"
            md_lines.append(f"| {url} | `{f['matched_url']}` | {source_short} |")

    if not any(all_findings.get(u) for u in websites):
        md_lines.append("| — | *No matches found* | — |")

    md_lines += ["", "---", "", "## Per-Site Detail", ""]

    for url in websites:
        md_lines.append(f"### {url}\n")
        findings = all_findings.get(url, [])
        if not findings:
            md_lines.append("✅ No Silver cluster references found.\n")
            continue

        md_lines += [
            "| Source | Matched URL | Context |",
            "|:-------|:------------|:--------|",
        ]
        for f in findings:
            source_short = f["source"].replace(url, "").strip() or "[HTML]"
            ctx_escaped = f["context"].replace("|", "\\|")[:150]
            md_lines.append(
                f"| {source_short} | `{f['matched_url']}` | `{ctx_escaped}` |"
            )
        md_lines.append("")

    with open(output_path, "w") as out:
        out.write("\n".join(md_lines))

    print(f"\n  Report saved to: {output_path}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
