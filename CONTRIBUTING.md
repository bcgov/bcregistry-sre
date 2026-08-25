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

That is the whole setup. The `prepare` script installs the git hook automatically, and the Gitleaks binary is downloaded on first use — nothing needs to be installed manually.

Requires Node.js 18 or newer.

### Verify it works

```bash
git rev-parse --git-path hooks/pre-commit | xargs ls -l
```

To confirm scanning runs against your staged changes:

```bash
npm run gitleaks:staged
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
| `npm run gitleaks:staged` | Scan staged changes (what the hook runs) |
| `npm run gitleaks:repo` | Scan all uncommitted work, including untracked files |

### If a finding is a false positive

Do not disable the hook. Either add an inline `gitleaks:allow` comment on the offending line, or add a placeholder token to `stopwords` in [.gitleaks.toml](.gitleaks.toml). Mention the change in your PR so it gets reviewed.

Bypassing the hook with `git commit --no-verify` is not acceptable for working around a real finding.

### Troubleshooting

- **Hook did not run:** you likely cloned without running `npm install`. Run it, then re-check the hook path above.
- **Hook still missing:** run `npx lefthook install`.
- **First commit is slow:** Gitleaks is downloading its binary once; later runs are fast.
