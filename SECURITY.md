# Security Policy

Payback is a young product and has not undergone an independent security
audit.

Please do not publish a suspected vulnerability in a public issue.
Email **security@jrtx.site** (or open a GitHub security advisory on this
repository). Include reproduction steps, affected versions, and your
assessment of impact. You will get an acknowledgment within 72 hours.

Security-sensitive areas:

- **The update trust chain** (`app/updater.rkt`, `docs/UPDATE.md`):
  Ed25519 manifest verification, key handling, SHA-256 artifact checks, and
  the install/rollback steps in the native hosts. Manifest signature or
  artifact-verification reports are treated as high priority.
- **The update signing key**: the private key must never enter the
  repository or a release artifact. If it leaks, rotate immediately per
  `docs/UPDATE.md` (ship a trusting build first, then flip `key_id`).
- **RPC input handling** (`app/wire.rkt`): device payloads are validated at
  the Racket boundary before reaching storage.

Payback treats its own backend as trusted code. The embedded Racket runtime
shares the process with the native UI and is not a sandbox boundary. Device
data stays in a local JSON file; the only network traffic the app makes is
fetching the signed update manifest and update artifacts over HTTPS.
