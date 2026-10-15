# Shared git hook rules

One place to maintain the [gitleaks](https://github.com/gitleaks/gitleaks) rules used by the bcregistry repos' pre-commit hooks (Git Hooks RFC, bcgov/entity#34619). Change a rule here and every repo using it picks it up within a day, with no PR in each repo.

| File | Purpose |
|---|---|
| `gitleaks-base.toml` | Shared rules: gitleaks defaults plus the `hardcoded-password` and `custom-password` rules, and common allowlists (lockfiles, placeholders). |
| `lefthook-remote.yml` | Empty on purpose. Repos point lefthook `remotes` at it so this repo gets fetched without merging bcregistry-sre's own `lefthook.yml` into theirs. |
| `tests/` | Samples that must be blocked / must pass. CI runs them on every change here (`.github/workflows/gitleaks-base-test.yaml`). |

## Using it in a repo (lefthook)

`lefthook.yml`:

```yaml
pre-commit:
  commands:
    secret-scan:
      tags: [security]
      run: if [ ! -f .git/info/lefthook-remotes/bcregistry-sre-main/git-hooks/gitleaks-base.toml ]; then echo Shared gitleaks rules missing - run npx lefthook install; exit 1; fi; npx --yes gitleaks-secret-scanner

remotes:
  - git_url: https://github.com/bcgov/bcregistry-sre
    ref: main
    refetch_frequency: 24h
    configs:
      - git-hooks/lefthook-remote.yml
```

`.gitleaks.toml` (only the repo's own exceptions go here):

```toml
[extend]
path = ".git/info/lefthook-remotes/bcregistry-sre-main/git-hooks/gitleaks-base.toml"

[allowlist]
description = "Repo-specific false positives"
regexes = [
  # e.g. document storage keys in fixtures
  '''[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.pdf''',
]
```

Then run `pnpm install` / `npm install` (or `npx lefthook install`) once. lefthook downloads this repo into `.git/info/lefthook-remotes/` and refreshes it every 24h.

When switching a repo over, scan its existing files with the shared rules once installed (`npx gitleaks-secret-scanner --diff-mode history` - this covers the whole git history, so it also lists secrets in old commits that have since been removed) and add allowlist entries for anything that isn't a real secret, typically test fixtures and vendored third-party JS (`libs/`, generated docs). The hook only checks changed lines, but whoever next edits one of those lines would get blocked.

### Why the `if [ ! -f ... ]` check matters

gitleaks can't load a config from a URL, so the shared file has to be downloaded first. If it isn't there (fresh clone with no network yet), the repo's `.gitleaks.toml` extends a missing file, gitleaks loads **no rules at all**, and every commit "passes". The check blocks the commit with a message instead. Keep it, and keep the secret-scan command in the repo's own `lefthook.yml` rather than in a remote config, for the same reason: if the remote isn't downloaded, a remote-only hook doesn't exist and nothing gets scanned.

### Gotchas

- Windows: run `git config --global core.longpaths true` once. lefthook downloads all of bcregistry-sre, and some of its paths go past the 260-character Windows limit when the repo lives in a deep folder (roughly, a repo folder path longer than 125 characters). The download then stops partway, and the check above blocks commits until it's fixed.
- If commits keep failing with "Shared gitleaks rules missing" after running `npx lefthook install` (it prints "Couldn't sync" and leaves a partial download behind), set `core.longpaths` as above, delete `.git/info/lefthook-remotes`, then run `npx lefthook install` again.
- Don't put `"` inside a lefthook `run:` command. On Windows lefthook runs it as `sh -c "<run>"`, so inner double quotes break it.
- Don't put `: ` (colon + space) in an unquoted `run:` value. It makes the whole `lefthook.yml` invalid and every commit fails.
- Git worktrees aren't supported. In a worktree `.git` is a file, so the `.git/info/...` paths above don't exist and commits there get blocked by the check (it fails safe, it doesn't skip the scan).
- Don't set `useDefault = true` in the repo's `.gitleaks.toml`. The shared file already does, and gitleaks errors if `path` and `useDefault` are both set.
- If a commit is blocked by a false positive, add an allowlist entry rather than committing with `--no-verify`. If the false positive would hit other repos too, fix it here.

## Changing the shared rules

1. Edit `gitleaks-base.toml`.
2. Add a sample to `tests/should-block/` (named `<rule-id>__<anything>`, so the test checks the right rule fires) or `tests/should-pass/`.
3. Open a PR. The test workflow must pass. Remember this reaches every repo using it: if `gitleaks-base.toml` is broken or emptied, the hook in every repo passes every commit without scanning.

Repos using the `pre-commit` framework instead of lefthook (e.g. sbc-pay, the schema repos) aren't covered by this yet.
