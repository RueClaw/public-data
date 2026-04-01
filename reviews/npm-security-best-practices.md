# npm-security-best-practices — Review

**Repo:** https://github.com/lirantal/npm-security-best-practices  
**Author:** Liran Tal (snyk/nodejs-security contributor)  
**License:** Apache-2.0  
**Stars:** ~471  
**Rating:** 🔥🔥🔥🔥  
**Cloned:** ~/src/npm-security-best-practices  
**Reviewed:** 2026-03-31

---

## What it is

14 concrete, actionable npm security hardening practices by Liran Tal — security researcher at Snyk, author of `npq` and `lockfile-lint`. This isn't an abstract list; every item has a "how to implement" block with exact commands. Covers both consumer security (protecting yourself from malicious packages) and publisher security (protecting your users).

Structured around three personas: **npm consumer**, **local developer**, **npm package maintainer**.

---

## The 14 practices (grouped)

### Supply chain attack mitigation (consumer-side)

**1. Disable post-install scripts**
Set `npm config set ignore-scripts true` + `allow-git none` globally. The README calls out a critical gap: even with `--ignore-scripts`, a git-based dep can ship its own `.npmrc` that re-enables lifecycle scripts. `--allow-git=none` (npm 11.10.0+) closes this.

pnpm 10 disables postinstall by default. Use `pnpm-workspace.yaml` `onlyBuiltDependencies` allowlist to enable only what you trust. `strictDepBuilds: true` makes unauthorized build scripts a CI-blocking error.

**2. Install with cooldown**
`npm config set min-release-age 3` — skip any version published less than 3 days ago. Newly published malicious packages are often caught by the community within hours. All major package managers now support this:
- npm: `min-release-age=3` in `.npmrc`
- pnpm 10.16+: `minimumReleaseAge: 20160` (minutes) in `pnpm-workspace.yaml`
- Bun 1.3+: `minimumReleaseAge = 259200` (seconds) in `bunfig.toml`
- Yarn 4.10+: `npmMinimalAgeGate: "3d"` in `.yarnrc.yml`
- Snyk auto-PRs have a 21-day built-in cooldown. Renovate has `minimumReleaseAge`. Dependabot has `cooldown`.

**3. Harden with security tools before install**
- `npq` — audits packages pre-install (typosquatting, postinstall scripts, age, vulnerability DB, provenance, binary introduction, maintainer domain expiry). Use `alias npm='npq-hero'` for seamless integration.
- `sfw` (Socket Firewall) — real-time firewall wrapping your package manager command. Works across npm/pnpm/yarn/pip/uv/cargo. More proprietary but deeper threat intelligence.

**4. Prevent lockfile injection**
`lockfile-lint` validates that lockfile resolved URLs only come from trusted registries. Covers the attack where a PR modifies `package-lock.json` to point a package to an attacker-controlled URL with a matching SHA.

pnpm is inherently more resistant. pnpm 10.26+ adds `blockExoticSubdeps: true` — transitive deps can only come from the registry, not from git repos or raw tarballs. Only your direct deps can use exotic sources.

pnpm 10.21+ adds `trustPolicy: no-downgrade` — refuses to install any version whose publish-time trust level (OIDC > provenance > signature > none) is weaker than a previously published version. Catches compromised account takeover.

**5. Use `npm ci`** (not `npm install`) in CI/CD. Strict lockfile adherence, fails on inconsistency. Equivalent: `pnpm install --frozen-lockfile`, `bun install --frozen-lockfile`, `yarn install --immutable`.

**6. Avoid blind upgrades** — `npm update` or `npx npm-check-updates -u` without review is an anti-pattern. Use `npx npm-check-updates --interactive` or auto-PR tools with cooldown policies.

### Local development hardening

**7. No plaintext secrets in .env files**
Use secret references (`op://vault/database/password`) not actual values. Inject at runtime with `op run -- npm start`. Malicious postinstall scripts can read `process.env` — this limits the blast radius.

**8. Dev containers**
Isolate npm installs from the host. Supply chain attack blast radius is contained to the container. Includes optional Docker hardening (`--security-opt=no-new-privileges:true`, `--cap-drop=ALL`, `NODE_OPTIONS=--disable-proto=delete`).

### Publisher hardening

**9. Enable 2FA** on npm accounts — `auth-and-writes` not `auth-only`.

**10. Publish with provenance attestations** — GitHub Actions: add `permissions: id-token: write`, run `npm publish --provenance`. Generates cryptographic proof linking the package tarball to the exact source commit and workflow run.

**11. Publish with OIDC (Trusted Publishing)** — eliminates long-lived npm tokens. Short-lived, workflow-scoped tokens only. Configure trusted publisher on npmjs.com, then `npm publish` with `id-token: write` permission — done.

**12. Minimize dependency tree** — fewer deps = smaller attack surface for your users. Native JS alternatives to common utility packages listed (Set for unique arrays, fetch for HTTP, etc.).

### Package evaluation

**13. Consult Snyk security database** — [security.snyk.io](https://security.snyk.io) for health score (security, popularity, maintenance, community).

**14. Don't trust npmjs.org website** — it omits git/HTTPS-based deps and may show source code that differs from the actual published tarball. Use `npm pack <pkg> --dry-run` to inspect what actually gets installed.

---

## What's particularly notable

**pnpm 10 is genuinely ahead on supply chain security** — default postinstall blocking, `strictDepBuilds`, `trustPolicy: no-downgrade`, `blockExoticSubdeps`, and `allowBuilds` granular control. If you're using npm for anything serious, this doc makes a case for switching.

**The cooldown pattern** is underused and trivially deployed. `npm config set min-release-age 3` takes 5 seconds and catches a meaningful category of attacks.

**The lockfile injection attack** is less discussed than it should be for teams accepting PRs from outside contributors. `lockfile-lint` in CI is the concrete fix.

**The `.npmrc` bypass** for `--ignore-scripts` via git dependencies with embedded `.npmrc` is the kind of gotcha that makes a checklist like this worth having.

---

## Relevance to us

Most immediately applicable:
- Set `ignore-scripts` + `allow-git=none` globally on dev machines
- Add `min-release-age 3` to npm config
- Use `pnpm --frozen-lockfile` in any CI we run (VOS, DMARC-Report-Manager, etc.)
- The `no plaintext secrets in .env` pattern is directly relevant — we have `.env` files with real values in several repos
- Dev containers for any project that installs untrusted packages

Source: Apache-2.0, lirantal/npm-security-best-practices
