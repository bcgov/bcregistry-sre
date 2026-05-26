import os
import re
import sys
from collections import defaultdict

import requests
from dotenv import load_dotenv

load_dotenv()

GITHUB_TOKEN = os.getenv("CODEQL_GITHUB_TOKEN")

if not GITHUB_TOKEN:
    raise ValueError("CODEQL_GITHUB_TOKEN is not set in .env")

HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json",
}

# Patterns that may indicate bot or spam accounts
SUSPICIOUS_PATTERNS = [
    r"I can (own|take|handle|work on) this",
    r"I('m| am) (an? )?(external|independent|freelance|open.source)",
    r"I('d| would) (like|love) to (contribute|help|work)",
    r"assign (this )?(to me|me)",
    r"can (you )?(assign|give).*(to me|me this)",
]

SINCE_DATE = "2026-01-01T00:00:00Z"


# ── Utility functions ──────────────────────────────────────────────────


def get_paginated(url):
    """Fetch all pages from a paginated GitHub API endpoint."""
    results = []
    while url:
        response = requests.get(url, headers=HEADERS)
        response.raise_for_status()
        results.extend(response.json())
        url = response.links.get("next", {}).get("url")
    return results


def is_suspicious(text):
    """Check if comment text matches known suspicious patterns."""
    for pattern in SUSPICIOUS_PATTERNS:
        if re.search(pattern, text, re.IGNORECASE):
            return True
    return False


def issue_number_from_url(api_url):
    """Extract issue number from GitHub API URL."""
    match = re.search(r"/issues/(\d+)", api_url)
    return f"#{match.group(1)}" if match else api_url


def get_repo_collaborators(owner, repo):
    """Get list of collaborator logins for a repo."""
    url = f"https://api.github.com/repos/{owner}/{repo}/collaborators"
    return [m["login"] for m in get_paginated(url)]


# ── Check 1: Non-collaborator issue comments ──────────────────────────


def check_issue_comments(owner, repo):
    """Find issue comments from non-collaborators on a specific repo."""
    print(f"\n{'=' * 70}")
    print(f"  CHECK 1: NON-COLLABORATOR ISSUE COMMENTS — {owner}/{repo}")
    print(f"{'=' * 70}")

    print(f"  Fetching collaborators for {owner}/{repo}...")
    collaborators = get_repo_collaborators(owner, repo)
    print(f"  Found {len(collaborators)} repo collaborators.")

    print(f"  Fetching issue comments (since {SINCE_DATE[:10]})...")
    comments_url = (
        f"https://api.github.com/repos/{owner}/{repo}"
        f"/issues/comments?since={SINCE_DATE}"
    )
    comments = get_paginated(comments_url)
    print(f"  Found {len(comments)} total comments.\n")

    # Group by non-collaborator author
    user_comments = defaultdict(list)
    for comment in comments:
        author = comment["user"]["login"]
        if author not in collaborators:
            flagged = is_suspicious(comment["body"])
            user_comments[author].append(
                {
                    "body": comment["body"],
                    "issue_url": comment["issue_url"],
                    "created_at": comment["created_at"],
                    "html_url": comment["html_url"],
                    "flagged": flagged,
                }
            )

    if not user_comments:
        print("  ✅ No non-collaborator comments found this month.\n")
        return

    sorted_users = sorted(
        user_comments.items(),
        key=lambda x: (
            -sum(1 for c in x[1] if c["flagged"]),
            -len(x[1]),
        ),
    )

    print(f"  {'User':<25} {'Comments':>8}  {'Flagged':>7}  Status")
    print("  " + "-" * 66)
    for user, clist in sorted_users:
        flagged_count = sum(1 for c in clist if c["flagged"])
        status = "⚠️  SUSPICIOUS" if flagged_count > 0 else "   OK"
        print(f"  {user:<25} {len(clist):>8}  {flagged_count:>7}  {status}")

    # Detail for flagged users
    flagged_users = [(u, cl) for u, cl in sorted_users if any(c["flagged"] for c in cl)]
    if flagged_users:
        print(f"\n  🚨 SUSPICIOUS COMMENTS (DETAIL)")
        for user, clist in flagged_users:
            print(f"\n    User: {user}")
            for c in clist:
                issue = issue_number_from_url(c["issue_url"])
                flag = " ⚠️" if c["flagged"] else ""
                body_preview = c["body"][:120].replace("\n", " ")
                print(f"      [{c['created_at'][:10]}] {issue}{flag}")
                print(f"        {body_preview}...")
                print(f"        Link: {c['html_url']}")

    # Detail for other non-collaborator users
    ok_users = [(u, cl) for u, cl in sorted_users if not any(c["flagged"] for c in cl)]
    if ok_users:
        print(f"\n  OTHER NON-COLLABORATOR COMMENTS")
        for user, clist in ok_users:
            print(f"\n    User: {user} ({len(clist)} comment(s))")
            for c in clist:
                issue = issue_number_from_url(c["issue_url"])
                body_preview = c["body"][:120].replace("\n", " ")
                print(f"      [{c['created_at'][:10]}] {issue}: {body_preview}")
    print()


# ── Check 2: Non-collaborator PR authors across managed repos ─────────


def check_pr_authors():
    """Find PRs authored by non-collaborators across all repos you manage."""
    print(f"\n{'=' * 70}")
    print(f"  CHECK 2: NON-COLLABORATOR PR AUTHORS (ALL MANAGED REPOS)")
    print(f"{'=' * 70}")

    # Get all repos the authenticated user has admin/push access to
    print("  Fetching your managed repos...")
    repos_url = "https://api.github.com/user/repos?type=all&sort=updated&per_page=100"
    all_repos = get_paginated(repos_url)

    # Filter to bcgov repos where the user has admin or maintain permission
    managed_repos = [
        r
        for r in all_repos
        if r.get("owner", {}).get("login") == "bcgov"
        and (
            r.get("permissions", {}).get("admin")
            or r.get("permissions", {}).get("maintain")
        )
    ]
    print(f"  Found {len(managed_repos)} managed repos.\n")

    non_collab_prs = []
    collaborator_cache = {}

    for i, repo in enumerate(managed_repos, 1):
        full_name = repo["full_name"]
        owner, name = full_name.split("/")
        sys.stdout.write(
            f"\r  Scanning [{i}/{len(managed_repos)}] {full_name}...".ljust(80)
        )
        sys.stdout.flush()

        # Get collaborators (cached)
        if full_name not in collaborator_cache:
            try:
                collaborator_cache[full_name] = get_repo_collaborators(owner, name)
            except requests.exceptions.HTTPError:
                # Skip repos where we can't list collaborators
                continue

        collaborators = collaborator_cache[full_name]

        # Get recent PRs — stop paginating once we pass the since date
        try:
            prs_url = (
                f"https://api.github.com/repos/{full_name}/pulls"
                f"?state=all&sort=created&direction=desc&per_page=100"
            )
            while prs_url:
                resp = requests.get(prs_url, headers=HEADERS)
                resp.raise_for_status()
                page_prs = resp.json()
                past_cutoff = False
                for pr in page_prs:
                    if pr["created_at"] < SINCE_DATE:
                        past_cutoff = True
                        break
                    pr_author = pr["user"]["login"]
                    if pr_author.endswith("[bot]"):
                        continue
                    if pr_author not in collaborators:
                        non_collab_prs.append(
                            {
                                "repo": full_name,
                                "author": pr_author,
                                "title": pr["title"],
                                "number": pr["number"],
                                "created_at": pr["created_at"],
                                "html_url": pr["html_url"],
                                "state": pr["state"],
                            }
                        )
                if past_cutoff or not page_prs:
                    break
                prs_url = resp.links.get("next", {}).get("url")
        except requests.exceptions.HTTPError:
            continue

    sys.stdout.write("\r" + " " * 80 + "\r")
    sys.stdout.flush()

    if not non_collab_prs:
        print("  ✅ No PRs from non-collaborators found this month.\n")
        return

    # Group by repo
    by_repo = defaultdict(list)
    for pr in non_collab_prs:
        by_repo[pr["repo"]].append(pr)

    print(f"  ⚠️  Found {len(non_collab_prs)} PR(s) from non-collaborators:\n")
    print(f"  {'Repo':<40} {'Author':<20} {'PR#':>5}  State")
    print("  " + "-" * 70)
    for repo, prs in sorted(by_repo.items()):
        for pr in prs:
            state_icon = "🟢" if pr["state"] == "open" else "⚫"
            print(
                f"  {repo:<40} {pr['author']:<20} "
                f"#{pr['number']:<4} {state_icon} {pr['state']}"
            )

    print(f"\n  DETAIL:")
    for repo, prs in sorted(by_repo.items()):
        print(f"\n    📁 {repo}")
        for pr in prs:
            print(f"      [{pr['created_at'][:10]}] #{pr['number']} ({pr['state']})")
            print(f"        {pr['title'][:100]}")
            print(f"        Author: {pr['author']}")
            print(f"        Link: {pr['html_url']}")
    print()


# ── Main ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    check_issue_comments("bcgov", "entity")
    check_pr_authors()
    print("Done.")
