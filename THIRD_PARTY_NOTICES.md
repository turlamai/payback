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

## GTK 4, GLib and linked Linux system libraries

The Linux host is a GTK 4 application. GTK and GLib are licensed under
the GNU Lesser General Public License, version 2.1 or later. No Linux
library is bundled: every linked library is a system dependency
resolved by the normal loader search on the target machine
(`linux/CMakeLists.txt`), so the exact versions are whatever your
distribution ships:

- GTK 4 and GIO (LGPL-2.1-or-later)
- json-glib (LGPL-2.1-or-later) — loads the shared/i18n strings tables
  at runtime
- libsecret (LGPL-2.1-or-later)
- ncurses / libtinfo (MIT-style X-consortium license)
- lz4 (BSD 2-Clause, library)
- zlib (the zlib license)

## Microsoft Windows App SDK

The Windows host is a WinUI 3 application built on the Microsoft
Windows App SDK, distributed by Microsoft under the MIT license.

## Apple system frameworks

The macOS host is a SwiftUI application built against Apple's system
frameworks (SwiftUI, AppKit and friends), provided under Apple's SDK
license terms and shipped by the operating system itself.

## AppImageKit runtime (`.AppImage` artifacts)

`.AppImage` release artifacts contain the type-2 AppImage runtime from
[AppImage/AppImageKit](https://github.com/AppImage/AppImageKit),
licensed MIT. The build tool is the official `appimagetool` 1.9.0
release pinned by the Rivet release toolchain, run in
extract-and-run mode by the release workflow. AppImageKit's license
does not apply to the contents of the AppImage: those are Payback's
MIT payload plus the entries above.
