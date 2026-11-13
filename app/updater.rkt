#lang racket/base

;; Online update support for Payback, built on rivet/distribution. The
;; backend verifies and downloads signed update artifacts; the native host
;; owns installation (docs/update.md). A check downloads and verifies the
;; Ed25519-signed update-manifest.json — the family single-file wrapper
;; carrying every platform and architecture; the actual DMG/MSI download
;; runs on a background thread with progress published to a state box that
;; the UI polls through the `update-state` RPC (RVT1 events are
;; thread-local, so a background thread cannot emit them directly).

;; crypto goes through rivet/distribution (same constraint as license.rkt):
;; crypto/all would pull the nettle factory's GMP FFI into the embedded
;; bundle, killing startup on machines without libgmp. The one exception is
;; plain `crypto` for crypto-random-bytes — the family rollout-bucket
;; primitive (taskly updater); it loads no crypto factory.

(require crypto
         net/base64
         rivet/distribution
         racket/file
         racket/format
         racket/match
         racket/string
         "store.rkt"
         "version.rkt")

(provide platform-symbol
         architecture-symbol
         installer-extension
         manifest-url
         destination-path
         updater-config-for
         update-state-snapshot
         reset-update-state!
         perform-check!
         start-download!
         rollout-bucket)

;; rivet release tooling emits these exact symbols into update manifests
(define (platform-symbol)
  (case (system-type 'os)
    [(macosx) 'macos]
    [(windows) 'windows]
    [else 'linux]))

(define (architecture-symbol)
  (case (system-type 'arch)
    [(aarch64 arm64) 'arm64]
    [else 'x64]))

(define (installer-extension)
  (case (system-type 'os)
    [(macosx) ".dmg"]
    [(windows) ".msi"]
    [else ".tar.gz"]))

(define maximum-download-bytes (* 800 1024 1024))

;; ---------- public key ----------

;; rivet/distribution pins the libcrypto factory at its module load; the
;; embedded DER is the public half of keys/update-ed25519-private.der, which
;; never ships (docs/update.md).
(define (embedded-public-key)
  (bytes->ed25519-public-key (base64-string->bytes update-public-key-b64)))

;; ---------- shared update state (UI-visible) ----------

;; phase: idle | checking | downloading | downloaded | error
(define update-state
  (box (hasheq 'phase "idle"
               'percent 0
               'message 'null
               'downloadedPath 'null
               'availableVersion 'null)))

;; The managed updater owns the authenticated check/download lifecycle:
;; candidate selection, progress, the stall/total watchdog, cancellation,
;; and the terminal state. This module only maps its snapshot onto the wire
;; shape the UI polls and keeps the product-owned key/config/destination.
(define updater-box (box #f))
(define download-root-box (box #f))

(define (state-set! key value)
  (set-box! update-state (hash-set (unbox update-state) key value)))

(define (managed-state->product state)
  (define phase (hash-ref state 'phase "idle"))
  ;; The product's UI treats "available"/"up-to-date"/"cancelled" as idle;
  ;; the available version and terminal error message carry the signal.
  (define mapped-phase
    (case phase
      [("available" "up-to-date" "cancelled") "idle"]
      [else phase]))
  (hasheq 'phase mapped-phase
          'percent (if (string=? mapped-phase "idle")
                       0
                       (hash-ref state 'percent 0))
          'message (let ([message (hash-ref state 'message #f)])
                     (if message message 'null))
          'downloadedPath (let ([path (hash-ref state 'downloadedPath #f)])
                            (if path path 'null))
          'availableVersion (let ([version (hash-ref state 'availableVersion #f)])
                              (if version version 'null))))

(define (update-state-snapshot)
  (define instance (unbox updater-box))
  (if instance
      (managed-state->product (updater-state instance))
      (unbox update-state)))

(define (reset-update-state!)
  (set-box! updater-box #f)
  (set-box! download-root-box #f)
  (set-box! update-state
            (hasheq 'phase "idle"
                    'percent 0
                    'message 'null
                    'downloadedPath 'null
                    'availableVersion 'null)))

;; ---------- manifest URL ----------

(define (manifest-url settings)
  ;; Single-file family feed (taskly baseline): one signed wrapper per
  ;; release, every platform × architecture inside. The channel still gates
  ;; selection (select-update matches app-channel against the manifest).
  (define base
    (let ([configured (hash-ref settings 'updateBaseUrl 'null)])
      (if (and (string? configured) (not (string=? configured "")))
          configured
          default-update-base-url)))
  (string-append (string-trim base "/" #:right? #t)
                 "/update-manifest.json"))

;; ---------- updater config ----------

;; One construction site for the updater identity, shared by the check and
;; the download (tests/updater-test.rkt exercises it directly so the live
;; path cannot drift from the tested shape). The final argument is the feed
;; component: this feed's artifacts carry the 'app component (rivet #271),
;; and select-update matches config component against artifact component, so
;; it must stay 'app — #f would silently select nothing from the real feed.
(define (updater-config-for store settings)
  (updater-config app-identifier
                  app-version
                  app-channel
                  (platform-symbol)
                  (architecture-symbol)
                  (embedded-public-key)
                  update-key-id
                  (rollout-bucket store settings)
                  maximum-download-bytes
                  'app))

;; ---------- managed updater ----------

;; One managed instance owns the authenticated check/download lifecycle;
;; the product supplies its key, feed, component and staging path.
(define (make-payback-updater store settings)
  (make-updater
   #:application-id app-identifier
   #:current-version app-version
   #:channel app-channel
   #:platform (platform-symbol)
   #:architecture (architecture-symbol)
   #:component 'app
   #:public-key (embedded-public-key)
   #:key-id update-key-id
   #:manifest-url (manifest-url settings)
   #:data-directory (find-system-path 'pref-dir)
   #:destination
   (lambda (candidate)
     (destination-path (or (unbox download-root-box)
                           (find-system-path 'pref-dir))
                       candidate))
   #:rollout-bucket (rollout-bucket store settings)
   #:maximum-download-bytes maximum-download-bytes))

;; ---------- check ----------

;; Returns the managed wire result; also refreshes "lastUpdateCheckAt"
;; (epoch seconds) in the store on every completed check.
(define (perform-check! store settings)
  (with-handlers
      ([exn:fail?
        (lambda (e)
          (state-set! 'phase "error")
          (state-set! 'message (exn-message e))
          (hasheq 'status "error" 'message (exn-message e)))])
    (define instance (make-payback-updater store settings))
    (set-box! updater-box instance)
    (define result (updater-check! instance))
    (unless (equal? (hash-ref result 'status #f) "error")
      (store-mutate! store
                     (lambda (doc)
                       (values
                        (settings-with doc 'lastUpdateCheckAt (current-seconds))
                        (void)))))
    result))

;; helper producing a document with one settings key replaced
(define (settings-with doc key value)
  (hash-set doc 'settings
            (hash-set (hash-ref doc 'settings) key value)))

;; rollout bucket: stable random 0..99 assigned on first check so staged
;; rollouts are sticky per installation. crypto-random-bytes, not `random`:
;; racket/base's PRNG has a fixed seed, which would put every fresh install
;; in the same lockstep bucket.
(define (rollout-bucket store settings)
  (define existing (hash-ref settings 'rolloutBucket 'null))
  (cond
    [(and (exact-integer? existing) (<= 0 existing 99)) existing]
    [else
     (define bucket
       (modulo (integer-bytes->integer (crypto-random-bytes 4) #t #t) 100))
     ;; A headless check may have no store (the live-check regression test
     ;; passes #f); a random bucket still lets the signed feed selection run.
     (when store
       (store-mutate! store
                      (lambda (doc)
                        (values (settings-with doc 'rolloutBucket bucket)
                                (void)))))
     bucket]))

;; ---------- download ----------

(define (destination-path data-dir candidate)
  (define version
    (update-manifest-version (update-candidate-manifest candidate)))
  (build-path data-dir
              "updates"
              (string-append app-display-name "-" version
                             (installer-extension))))

(define (start-download! store settings data-dir)
  ;; The managed instance already owns the checked candidate, the worker,
  ;; the watchdog, and the terminal state. The staging directory is chosen
  ;; by the product; the destination callback reads it here.
  (define instance (unbox updater-box))
  (unless instance
    (error 'start-download! "no update is available; run a check first"))
  (set-box! download-root-box data-dir)
  (updater-download! instance))
