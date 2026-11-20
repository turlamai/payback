# Third-party notices

Payback builds on the components below. Each entry names where the
component enters the shipped artifacts and the license it is distributed
under; consult the upstream license files for full terms. This file is
the root overview for the repository — the release pipeline deliberately
does not attach a generated per-artifact notices file, so this document
is the authoritative notices record for every published release. The
Rivet toolchain is a first-party TurLamAI project (MIT) consumed as a
pinned package — not third-party code — so it is not listed here.

## Racket CS runtime

Every platform host embeds the statically linked Racket CS runtime
([racket/racket](https://github.com/racket/racket)). Racket is
distributed under the MIT license and the Apache License 2.0, at your
option; the Racket CS runtime system additionally embeds Chez Scheme,
distributed under the Apache License 2.0 (per Racket's `LICENSE.txt`).

## crypto-lib

Update-trust work — Ed25519 manifest verification and SHA-256 artifact
checks through Rivet's distribution layer, plus the rollout-bucket
randomness — runs through the Racket `crypto` package's libcrypto
factory ([racket/crypto](https://github.com/racket/crypto)), distributed
under the Apache License 2.0. It links against the platform's OpenSSL
(libcrypto), which ships with the operating system.

## Microsoft Windows App SDK

The Windows host is a WinUI 3 application built on the Microsoft
Windows App SDK, distributed by Microsoft under the MIT license.

## Apple system frameworks

The macOS host is a SwiftUI application built against Apple's system
frameworks (SwiftUI, AppKit and friends), provided under Apple's SDK
license terms and shipped by the operating system itself.
