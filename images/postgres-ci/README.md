# postgres-ci

Custom PostgreSQL image used as the service container for the backend CI `unit-testing` job (see `.github/workflows/backend-ci.yaml`).

It extends `postgis/postgis` with the PostgreSQL Anonymizer extension so unit tests can run against an anonymized data set.

## What it contains

- PostgreSQL (version pinned in `Dockerfile`, e.g. `postgis/postgis:18-master`)
- PostGIS
- `postgresql_anonymizer_<major>` from the Dalibo labs apt repo

## When to rebuild

Bump the PostgreSQL major version by editing, together:

1. `images/postgres-ci/Dockerfile` — the `FROM postgis/postgis:<major>-master` line and the `postgresql_anonymizer_<major>` package name
2. `images/postgres-ci/build.sh` — image tags (`postgres<major>-postgis-anon`)
3. `.github/workflows/backend-ci.yaml` — the `services.postgres.image` reference (`ghcr.io/bcgov/postgres<major>-postgis-anon:latest`)

## Build and push

```bash
cd images/postgres-ci
./build.sh
```

This builds, tags (`ghcr.io/bcgov/postgres<major>-postgis-anon:latest`), and pushes the image.

### Prerequisites

1. **Login to GHCR with a `write:packages` PAT that is SSO-authorized for the `bcgov` org.**

   ```bash
   docker login ghcr.io
   ```

   Use a classic PAT with the `write:packages` and `read:packages` scopes. Because the bcgov org has SAML enforcement, the PAT must also be authorized for the org, or the push fails with:

   ```
   denied: permission_denied: Resource protected by organization SAML enforcement.
   You must grant your Personal Access token access to this organization.
   ```

   Fix it at https://github.com/settings/tokens → open the token → **Organization access → Configure SSO → bcgov → Authorize**.

2. **Set the package visibility to Public after pushing.**

   A freshly pushed GHCR package defaults to **private**. The CI service container is pulled without authentication, so a private package makes CI fail with:

   ```
   Error response from daemon: denied
   ```

   Change the visibility at:

   ```
   https://github.com/orgs/bcgov/packages/container/postgres<major>-postgis-anon/settings
   ```

   **Change visibility → Public.**

   Note: if you are only an org *member*, you need a `bcgov` org owner/admin to do this (members get `404`/`permission_denied` when attempting it via the API or Settings).

## Verify

Confirm the image is publicly pullable before rerunning CI:

```bash
docker pull ghcr.io/bcgov/postgres18-postgis-anon:latest
```

Then rerun the workflow that calls `backend-ci.yaml`.