# phntm-cli — #257

**Repo:** https://github.com/aliirz/phntm-cli  
**Author:** Ali Raza  
**License:** MIT (Ali Raza 2026)  
**Language:** Go 1.21+  
**Stars:** 2 | **Forks:** 0  
**Created:** 2026-03-16 | **Reviewed:** 2026-03-25  
**Rating:** 🔥🔥🔥  
**Cloned:** ~/src/phntm-cli

---

## What It Is

Terminal CLI for [phntm.sh](https://phntm.sh) — zero-knowledge encrypted file sharing. Files are encrypted locally with AES-256-GCM before upload. The decryption key lives only in the URL fragment (`#key`), which browsers never send to servers. Server sees only ciphertext, forever.

```bash
phntm send report.pdf              # upload, 24h default expiry
phntm send secrets.tar.gz --expiry 1h
phntm get https://phntm.sh/f/abc123#key
phntm report.pdf | pbcopy          # pipe-friendly: URL → clipboard
```

Expiry options: 1h, 6h, 24h. Files self-destruct.

---

## Architecture

~1500 lines of Go. Dead simple:

```
cmd/
  send.go     — encrypt → upload pipeline with live progress
  get.go      — download → decrypt
  root.go     — cobra root command
internal/
  crypto/     — AES-256-GCM keygen/encrypt/decrypt
  api/        — HTTP client (init upload → upload to storage → confirm)
  ui/         — step tracker, progress reader, box rendering
  updater/    — self-update check
```

**Crypto implementation is correct:**
- `crypto/rand` for key and IV generation (no math/rand)
- AES-256 (32-byte key), GCM mode, 12-byte nonce
- Format: `[12-byte IV][ciphertext+GCM tag]`
- Key encoded as base64url (no padding), matching the web app's JS WebCrypto format
- Key in URL fragment only — HTTP clients never transmit fragments

**UX is polished for 1500 lines:**
- Step tracker shows the pipeline: READ → ENCRYPT → TRANSMIT → CONFIRM
- Live upload progress bar via `ProgressReader` wrapping the ciphertext bytes
- Pipe-friendly: bare URL to stdout, decorated box to stderr. `phntm file.pdf | pbcopy` works cleanly.
- `PHNTM_API_URL` env var for self-hosting

---

## What's Good

The crypto is sound and the implementation doesn't cut corners (proper rand source, proper GCM, proper key encoding). The pipe-friendly stdout/stderr split is a small but thoughtful design choice — a lot of CLIs get this wrong and break piping.

The URL fragment key pattern is genuinely zero-knowledge: even a compromised or malicious server can't decrypt files. Legitimate use case for agent-to-human or agent-to-agent secret sharing.

---

## What's Missing / Caveats

- Very young (9 days old), 2 stars — phntm.sh is a third-party hosted service with no SLA
- No self-hostable server code in this repo (just the client + `PHNTM_API_URL` escape hatch)
- Expiry options are limited (max 24h) — fine for ephemeral sharing, not archival
- No streaming upload for large files (reads whole file into memory before encrypt)
- No resume or retry on failed uploads

---

## Relevance

**Low direct relevance for our stack** — we have SSH, NFS, and SimpleX as transfer channels. But the URL-fragment key pattern is worth noting as a pattern for any ephemeral credential sharing:

- Hand off API keys or secrets to someone without them touching a server log
- Could be adapted for agent-to-agent capability handoff (short-lived, server-blind)
- The crypto module (`internal/crypto/`) is a clean, extractable AES-256-GCM template

---

## Verdict

🔥🔥🔥 — Solid small tool, correct crypto, polished UX for its size. Useful for ephemeral secret sharing when you don't want to futz with PGP. The URL fragment key pattern is the intellectually interesting piece. Too early-stage and service-dependent to rely on for anything critical.

**Worth stealing:** `internal/crypto/crypto.go` as a clean Go AES-256-GCM template (MIT). The pipe-friendly stdout/stderr split pattern.
