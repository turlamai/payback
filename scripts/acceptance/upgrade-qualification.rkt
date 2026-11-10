#lang racket/base

;; Qualification driver for the published-upgrade workflow
;; (.github/workflows/appimage-upgrade-qualification.yml): drives the
;; updater entry points shipped in the previous published release against
;; the real feed. Two modes:
;;
;; upgrade (default) — perform-check! against the live signed feed (the
;;   client's own default base URL, i.e. releases/latest/download/
;;   update-manifest.json), then start-download! and wait for the terminal
;;   phase. Emits one JSON object with the offered version, the downloaded
;;   path and its SHA-256. The 4-hour auto-check throttle is host policy
;;   (the check-updates RPC consults lastUpdateCheckAt); these entry points
;;   never see it, which is exactly how the qualification bypasses the
;;   throttle without touching the shipped code.
;;
;; bad-signature (TAMPER_BYTES_PATH set) — the workflow hands us the real
;;   published feed bytes with one payload byte flipped (PRISTINE_BYTES_PATH
;;   carries the untampered bytes as the positive control). Verification is
;;   the first gate fetch-update-manifest applies, before selection or
;;   download; the pristine bytes must verify, the tampered bytes must be
;;   refused, and the updates directory must stay empty — a refused
;;   manifest can never reach disk as an artifact.
;;
;; Inputs (environment):
;;   DATA_DIR            payback data directory (XDG_DATA_HOME/payback)
;;   EXPECTED_VERSION    N+1 version string (upgrade mode)
;;   PRISTINE_BYTES_PATH real feed bytes (bad-signature mode, positive control)
;;   TAMPER_BYTES_PATH   tampered feed bytes (bad-signature mode)
;;   OUTPUT_JSON         where to write the result object
;;
;; Prints or writes one JSON object and exits non-zero on any mismatch.

(require crypto
         net/base64
         json
         racket/file
         racket/string
         ;; only-in: rivet main centralized platform-symbol /
         ;; architecture-symbol / installer-extension into
         ;; rivet/distribution (#258), which would clash with payback's own
         ;; trio under a bare require; only the two names below are needed
         (only-in rivet/distribution
                  base64-string->bytes
                  sha256-file/hex
                  verify-signed-manifest)
         "../../app/store.rkt"
         "../../app/updater.rkt"
         "../../app/version.rkt")

(define (need name)
  (or (getenv name)
      (error 'upgrade-qualification "~a is not set" name)))

(define (fail fmt . args)
  (apply error 'upgrade-qualification fmt args))

(define data-dir (need "DATA_DIR"))
(define output-json (getenv "OUTPUT_JSON"))
(define pristine-path (getenv "PRISTINE_BYTES_PATH"))
(define tamper-path (getenv "TAMPER_BYTES_PATH"))

(define store (make-store (build-path data-dir "local.json")))
(define settings (hash-ref (store-doc store) 'settings))

(define updates-dir (build-path data-dir "updates"))
(define (landed-artifacts)
  (if (directory-exists? updates-dir)
      (directory-list updates-dir)
      '()))

(define result
  (cond
    ;; ---------- bad-signature mode ----------
    [tamper-path
     (define public-key
       (datum->pk-key (base64-string->bytes update-public-key-b64)
                      'SubjectPublicKeyInfo))
     ;; positive control: the pristine published bytes must verify, so the
     ;; refusal below is attributable to the flipped byte alone
     (define pristine-ok
       (with-handlers ([exn:fail? (lambda (_) #f)])
         (verify-signed-manifest (open-input-bytes (file->bytes pristine-path))
                                 public-key
                                 #:key-id update-key-id)
         #t))
     (unless pristine-ok
       (fail "the pristine live feed bytes did not verify — the environment, not the tamper, is broken"))
     ;; the tampered bytes must be refused by the same gate
     (define tampered-accepted?
       (with-handlers ([exn:fail? (lambda (_) #f)])
         (verify-signed-manifest (open-input-bytes (file->bytes tamper-path))
                                 public-key
                                 #:key-id update-key-id)
         #t))
     (when tampered-accepted?
       (fail "one-byte-tampered live feed bytes were ACCEPTED — signature enforcement is broken"))
     (define left (landed-artifacts))
     (unless (null? left)
       (fail "a refused manifest must not reach download; updates/ holds: ~a" left))
     (hasheq 'mode "bad-signature"
             'pristineVerified #t
             'tamperedRefused #t
             'updatesDirEntries '())]
    ;; ---------- upgrade mode ----------
    [else
     (define expected-version (need "EXPECTED_VERSION"))
     (define checked (perform-check! store settings))
     (unless (equal? (hash-ref checked 'status #f) "available")
       (fail "feed did not offer an update: ~a" checked))
     (unless (equal? (hash-ref checked 'availableVersion #f) expected-version)
       (fail "expected version ~a, feed offered ~a"
             expected-version (hash-ref checked 'availableVersion #f)))
     (start-download! store settings data-dir)
     (define snapshot
       (let loop ([n 0])
         (define s (update-state-snapshot))
         (define phase (hash-ref s 'phase #f))
         (cond
           [(member phase '("downloaded" "error")) s]
           [(> n 600) s]
           [else (sleep 0.2) (loop (add1 n))])))
     (define phase (hash-ref snapshot 'phase #f))
     (unless (equal? phase "downloaded")
       (fail "download ended in phase ~a (message: ~a)"
             phase (hash-ref snapshot 'message #f)))
     (define downloaded-path (hash-ref snapshot 'downloadedPath #f))
     (unless (string? downloaded-path)
       (fail "downloadedPath is not a string: ~a" downloaded-path))
     (hasheq 'mode "upgrade"
             'status "downloaded"
             'availableVersion (hash-ref checked 'availableVersion #f)
             'installer (hash-ref checked 'installer #f)
             'sizeBytes (hash-ref checked 'sizeBytes #f)
             'feedUrl (manifest-url settings)
             'downloadedPath downloaded-path
             'downloadedSha256 (sha256-file/hex downloaded-path)
             'percent (hash-ref snapshot 'percent #f))]))

(if output-json
    (call-with-output-file output-json
      (lambda (out) (write-json result out) (newline out))
      #:exists 'truncate)
    (begin (write-json result) (newline)))
