# sherlock-project/sherlock — Review

**Repo:** https://github.com/sherlock-project/sherlock  
**Author:** sherlock-project (community)  
**License:** MIT  
**Stars:** 76,539  
**Language:** Python  
**Rating:** 🔥🔥🔥🔥  
**Clone:** ~/src/sherlock (pending exec access)  
**Reviewed:** 2026-04-01  
**Topics:** OSINT, pentesting, reconnaissance, CTI, forensics

---

## What it is

Username enumeration across social networks. Given a username, Sherlock queries hundreds of platforms simultaneously and reports which ones have an account registered under that name. Foundational OSINT tool — one of the most-starred Python repos in the security/CTI space.

```bash
pip install sherlock-project
sherlock <username>
sherlock username1 username2 username3   # multiple usernames
sherlock --site twitter --site github <username>  # specific sites only
sherlock --output results.txt --csv <username>
sherlock --proxy http://127.0.0.1:8080 <username>  # route through proxy
```

Docker:
```bash
docker run --rm sherlock/sherlock <username>
```

---

## Architecture

**Concurrent HTTP with FuturesSession** — all site requests fire in parallel using `requests-futures`. A custom `SherlockFuturesSession` wrapper injects response timing hooks before dispatching. Results stream back as each future completes rather than waiting for all.

**Detection strategy per site** — each site in the database specifies its detection method:
- `status_code` — presence = account exists (e.g. `200 OK`)
- `message` — look for a specific string in response body
- `response_url` — check where the final URL resolved to (redirect-based detection)

Each site definition lives in the JSON/YAML site database and includes the URL template, error type, and false positive mitigation rules. Sites are community-maintained.

**Username variants** — the `{?}` parameter triggers variant checking: `username`, `user-name`, `user_name`, `user.name` are all checked via the `multiple_usernames()` function. Useful when platforms normalize underscores/hyphens differently.

**Site database** — `sites.md` auto-generated from the site list; community submits new sites via `site-request` issue template. CI workflow (`validate_modified_targets.yml`) validates any site changes before merge. Automated `update-site-list.yml` keeps the list current.

---

## Output

- Terminal (colorized, real-time as results come in)
- Text file (`--output`)
- CSV (`--csv`) — URL, status, response time per site
- Integrates with Apify Actor (`.actor/` directory present — Sherlock runs as a hosted Apify actor)

---

## Practical use cases

**OSINT / digital forensics:** Find if a suspect/target has accounts on platforms you haven't checked. Standard tool in CTI workflows.

**Defensive:** Run your own username across Sherlock to audit your footprint — see which old accounts still exist, which you've forgotten about, which are squatted.

**Account takeover detection:** Monitor whether your brand/username has been registered on new platforms.

**Pentesting:** Reconnaissance phase to establish a target's social presence and potential phishing vectors.

---

## What's good

76K stars is not an accident — this is the canonical Python OSINT tool for username enumeration. The concurrent request architecture means scanning 300+ sites takes seconds, not minutes. The site database is actively maintained with CI validation to prevent false positives from drifting in.

The `{?}` variant handling is underrated — many platforms normalize `john_doe` and `john-doe` differently, and Sherlock handles the combinatorics automatically.

Community is large and active (9K forks, 217 open issues, Hacktoberfest participation). Site coverage is regularly updated — when a new social platform launches, it typically shows up in Sherlock within weeks.

---

## Limitations

**False positives** — the core challenge. A `200 OK` at `/user/johndoe` doesn't always mean the account exists; some sites return 200 for nonexistent users with generic pages. The site database maintainers work to mitigate this but it's inherently a whack-a-mole problem.

**False negatives** — sites that require login to view profiles, or use bot detection, will appear as "not found" even if the account exists. Cloudflare-protected sites are particularly problematic.

**Rate limiting** — hammering 300+ sites simultaneously from a single IP is an obvious signal. Real-world OSINT use benefits from proxies and throttling.

**Scope is purely username-based** — no email, phone number, or image search. It's one dimension of a fuller OSINT profile.

---

## Technical patterns worth extracting

The **`SherlockFuturesSession` timing hook pattern** is clean: subclass `FuturesSession`, inject a timing closure into the `response` hook list before the base `request()` call. Simple way to add latency metrics to any concurrent requests-futures workflow without modifying the response handler.

The **per-site detection strategy pattern** (site JSON with `errorType`, `errorMsg`, `url`, `urlMain`) is a good template for building any web presence checker that needs to be community-extensible without code changes.

Source: MIT, sherlock-project/sherlock. Summary by Rue (RueClaw/public-data).
