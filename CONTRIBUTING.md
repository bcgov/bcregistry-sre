## How to contribute

Government employees, public and members of the private sector are encouraged to contribute to the repository by **forking and submitting a pull request**.

(If you are new to GitHub, you might start with a [basic tutorial](https://help.github.com/articles/set-up-git) and  check out a more detailed guide to [pull requests](https://help.github.com/articles/using-pull-requests/).)

Pull requests will be evaluated by the repository guardians on a schedule and if deemed beneficial will be committed to the master.

All contributors retain the original copyright to their stuff, but by contributing to this project, you grant a world-wide, royalty-free, perpetual, irrevocable, non-exclusive, transferable license to all users **under the terms of the license under which this project is distributed.**

## Local setup: secret scanning pre-commit hook

This repo blocks commits that contain secrets, using [Gitleaks](https://github.com/gitleaks/gitleaks) run by a [Lefthook](https://github.com/evilmartians/lefthook) pre-commit hook.

Run this once after cloning:

```bash
npm install
```

That is the whole setup. The `prepare` script installs the git hook automatically. The scanner itself is fetched by `npx` on first use, so nothing needs to be installed manually.

Requires Node.js 18 or newer.

### Verify it works

```bash
git rev-parse --git-path hooks/pre-commit | xargs ls -l
```

To scan your staged changes the same way the hook does:

```bash
npx --yes gitleaks-secret-scanner@latest
```

### What you will see when a secret is caught

The commit is rejected and no commit is created:

```
Finding:  Uncovered a GitHub Personal Access Token...
RuleID:   github-pat
File:     example.txt
Line:     1

❌ Secrets were detected.
```

Remove the secret from the file, then re-stage and commit. Move real values into a secret manager or an untracked local env file. **Do not** commit a secret and rely on deleting it later — it stays in git history and must be treated as compromised and rotated.

### Useful commands

| Command | Purpose |
| --- | --- |
| `npx --yes gitleaks-secret-scanner@latest` | Scan staged changes (what the hook runs) |
| `npx --yes gitleaks-secret-scanner@latest --diff-mode all` | Scan all uncommitted work, including untracked files |
| `npx --yes gitleaks-secret-scanner@latest --diff-mode history` | Audit the full commit history |

The hook pins nothing: `@latest` means each run uses the newest published scanner.

### What gets flagged

Two layers, both configured in [.gitleaks.toml](.gitleaks.toml):

- **Gitleaks default rules** — known credential formats (`ghp_…`, `AKIA…`, private keys) and high-entropy strings near words like `secret` or `token`.
- **A custom `hardcoded-password` rule** — catches weak passwords the default rules miss, because short human-chosen values fall below the entropy threshold. It triggers on a literal assignment to a `password` / `passwd` / `pwd` name.

Values containing markers such as `fake`, `dummy`, `example`, `placeholder` or `changeme` are treated as placeholders and allowed. Environment lookups (`os.environ`, `process.env`) and interpolations (`"${var.secret}"`) never match.

### If a finding is a false positive

Do not disable the hook. Pick one of:

- add an inline `gitleaks:allow` comment on the offending line
- name the value so it reads as a placeholder, for example `fake-password-123`
- add a pattern to the relevant allowlist in [.gitleaks.toml](.gitleaks.toml)

Mention the change in your PR so it gets reviewed. Bypassing the hook with `git commit --no-verify` is not acceptable for working around a real finding.

### Troubleshooting

- **Hook did not run:** you likely cloned without running `npm install`. Run it, then re-check the hook path above.
- **Hook still missing:** run `npx lefthook install`.
- **First commit is slow, or hangs on a slow network:** `npx` is downloading the scanner. It is cached afterwards, but the first run needs network access.
- **`npm: command not found` when committing from VS Code or another git GUI:** GUI clients run hooks from a bare shell that never sources your shell profile, so version managers like nvm are invisible. [.lefthookrc](.lefthookrc) restores Node for the common ones. If your setup still is not found, add its bin directory there.
