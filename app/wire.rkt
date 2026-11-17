#lang racket/base

;; Wire validation for Payback RPC payloads. Input JSON is converted and
;; normalized into canonical device/settings records before it reaches the
;; store; violations raise with messages the native hosts surface verbatim.
;;
;; Money amounts are integer minor units. `willingPerDayMinor` (心理价位：
;; 用户愿意为这台设备每天支付的钱) drives the payback progress feature and
;; stays optional everywhere.

(require racket/date
         racket/list
         racket/format
         racket/random
         racket/port
         racket/string
         "domain.rkt")

(provide new-device-id
         now-timestamp
         timestamp-from-seconds
         canonical-currency?
         validate-new-device
         validate-device-update
         validate-settings-patch
         validate-backup-payload)

(define categories
  '("computer" "phone" "tablet" "watch" "audio" "camera" "gaming" "appliance" "accessory" "other"))

(define max-price-minor 1000000000)     ; 10,000,000.00
(define max-willing-minor 100000000)    ;   1,000,000.00 per day
(define max-name-chars 120)             ; design/DESIGN.md (2026-11 redesign)
(define max-notes-chars 2000)
(define max-icon-chars 16)
(define max-backup-devices 2000)        ; devices and trash each cap at 2000
(define valid-themes '("system" "light" "dark"))
(define valid-languages '("system" "zh-CN" "en"))

(define (random-hex-string byte-count)
  (string-append*
   (for/list ([byte (in-bytes (crypto-random-bytes byte-count))])
     (~r byte #:base 16 #:min-width 2 #:pad-string "0"))))

(define (new-device-id)
  (string-append "d-" (random-hex-string 5)))

(define (timestamp-from-seconds secs)
  (define d (seconds->date secs))
  (format "~a-~a-~a ~a:~a:~a"
          (date-year d)
          (~r (date-month d) #:min-width 2 #:pad-string "0")
          (~r (date-day d) #:min-width 2 #:pad-string "0")
          (~r (date-hour d) #:min-width 2 #:pad-string "0")
          (~r (date-minute d) #:min-width 2 #:pad-string "0")
          (~r (date-second d) #:min-width 2 #:pad-string "0")))

(define (now-timestamp)
  (timestamp-from-seconds (current-seconds)))

(define (canonical-currency? s)
  (and (string? s) (regexp-match? #px"^[A-Z]{3}$" s)))

(define (field jsexpr key [default 'absent])
  (define v (hash-ref jsexpr key default))
  (if (eq? v 'null) 'absent v))

(define (require-string who key value limit)
  (unless (string? value)
    (error who "field '~a' must be a string" key))
  (unless (<= (string-length value) limit)
    (error who "field '~a' exceeds ~a characters" key limit))
  value)

;; ---------- devices ----------

;; Builds a canonical device record from a wire payload. `id`, `created-at`
;; and `updated-at` are supplied by the caller; client-supplied values of
;; those fields are ignored on create and on update (updated-at is refreshed).
(define (validate-new-device payload settings today who)
  (unless (hash? payload)
    (error who "request body must be a JSON object"))
  (define name
    (string-trim
     (require-string who 'name (field payload 'name) (+ max-name-chars 2))))
  (unless (and (string? name) (<= 1 (string-length name) max-name-chars))
    (error who "field 'name' must be 1-~a characters" max-name-chars))
  (define icon
    (let ([raw (field payload 'icon)])
      (cond
        [(eq? raw 'absent) "📦"]
        [(and (string? raw) (<= 1 (string-length raw) max-icon-chars)) raw]
        [else (error who "field 'icon' must be 1-~a characters" max-icon-chars)])))
  (define category
    (let ([raw (field payload 'category "other")])
      (unless (member raw categories)
        (error who "field 'category' must be one of: ~a" (string-join categories ", ")))
      raw))
  (define price (field payload 'priceMinor))
  (unless (and (exact-integer? price) (<= 1 price max-price-minor))
    (error who "field 'priceMinor' must be an integer between 1 and ~a" max-price-minor))
  (define currency
    (let ([raw (field payload 'currency (hash-ref settings 'currency))])
      (unless (canonical-currency? raw)
        (error who "field 'currency' must be a 3-letter uppercase ISO 4217 code"))
      raw))
  (define purchase-date (field payload 'purchaseDate))
  (unless (valid-date-range? purchase-date today)
    (error who "field 'purchaseDate' must be a date between ~a and today (~a), formatted yyyy-MM-dd"
           min-date-string today))
  (define willing (field payload 'willingPerDayMinor))
  (unless (or (eq? willing 'absent)
              (and (exact-integer? willing) (<= 1 willing max-willing-minor)))
    (error who "field 'willingPerDayMinor' must be a positive integer up to ~a" max-willing-minor))
  (define notes
    (let ([raw (field payload 'notes "")])
      (unless (string? raw) (error who "field 'notes' must be a string"))
      (unless (<= (string-length raw) max-notes-chars)
        (error who "field 'notes' exceeds ~a characters" max-notes-chars))
      raw))
  (hasheq 'name name
          'icon icon
          'category category
          'priceMinor price
          'currency currency
          'purchaseDate purchase-date
          'willingPerDayMinor (if (eq? willing 'absent) 'null willing)
          'notes notes))

;; Returns the validated full record given the existing record for `id`.
(define (validate-device-update payload existing today who)
  (unless (hash? payload)
    (error who "request body must be a JSON object"))
  (define id (field payload 'id))
  (unless (and (string? id) (string=? id (hash-ref existing 'id)))
    (error who "field 'id' must identify an existing device"))
  (define checked
    (validate-new-device payload
                         (hasheq 'currency (hash-ref existing 'currency))
                         today
                         who))
  (for/fold ([record existing])
            ([key (in-list '(name icon category priceMinor currency
                             purchaseDate willingPerDayMinor notes))])
    (hash-set record key (hash-ref checked key))))

;; ---------- settings ----------

;; Only app-owned keys are patchable here; rolloutBucket and
;; lastUpdateCheckAt are maintained internally by the updater. `theme` and
;; `language` are the redesign's per-machine display preferences.
(define (validate-settings-patch payload who)
  (unless (hash? payload)
    (error who "request body must be a JSON object"))
  (for/fold ([patch (hasheq)])
            ([key (in-list '(currency updateAutoCheck updateBaseUrl
                             theme language))])
    (define raw (hash-ref payload key 'skip))
    (cond
      [(eq? raw 'skip) patch]
      ;; only updateBaseUrl may be set back to null (reset to default URL)
      [(eq? raw 'null)
       (if (eq? key 'updateBaseUrl)
           (hash-set patch key 'null)
           (error who "field '~a' cannot be null" key))]
      [(and (eq? key 'currency) (canonical-currency? raw))
       (hash-set patch key raw)]
      [(and (eq? key 'updateAutoCheck) (boolean? raw))
       (hash-set patch key raw)]
      [(and (eq? key 'updateBaseUrl)
            (string? raw)
            (or (string=? raw "") (regexp-match? #px"^https://" raw)))
       (hash-set patch key raw)]
      [(and (eq? key 'theme) (member raw valid-themes))
       (hash-set patch key raw)]
      [(and (eq? key 'language) (member raw valid-languages))
       (hash-set patch key raw)]
      [else (error who "field '~a' has an invalid value" key)])))

;; ---------- backup (payback.backup v1, docs/data-format.md) ----------

;; Canonicalizes one backup record. `who` and `context` name the failure in
;; user-visible messages; `tombstoned?` picks which list the record came
;; from (live devices must not carry a tombstone, trash must).
(define (validate-backup-record raw today tombstoned? who context)
  (unless (hash? raw)
    (error who "backup ~a: each record must be a JSON object" context))
  (define id (hash-ref raw 'id #f))
  (unless (and (string? id)
               (<= 1 (string-length id) 100)
               (regexp-match? #px"^[A-Za-z0-9_-]+$" id))
    (error who "backup ~a: record 'id' must be 1-100 letters, digits, '-' or '_'" context))
  (define name
    (string-trim (hash-ref raw 'name #f)))
  (unless (and (string? name) (<= 1 (string-length name) max-name-chars))
    (error who "backup ~a: record ~a has an invalid 'name'" context id))
  (define icon
    (let ([v (hash-ref raw 'icon "📦")])
      (unless (and (string? v) (<= 1 (string-length v) max-icon-chars))
        (error who "backup ~a: record ~a has an invalid 'icon'" context id))
      v))
  (define category (hash-ref raw 'category #f))
  (unless (member category categories)
    (error who "backup ~a: record ~a has an invalid 'category'" context id))
  (define price (hash-ref raw 'priceMinor #f))
  (unless (and (exact-integer? price) (<= 1 price max-price-minor))
    (error who "backup ~a: record ~a has an invalid 'priceMinor'" context id))
  (define currency (hash-ref raw 'currency #f))
  (unless (canonical-currency? currency)
    (error who "backup ~a: record ~a has an invalid 'currency'" context id))
  (define purchase-date (hash-ref raw 'purchaseDate #f))
  (unless (valid-date-range? purchase-date today)
    (error who "backup ~a: record ~a has an invalid 'purchaseDate'" context id))
  (define willing (hash-ref raw 'willingPerDayMinor 'null))
  (unless (or (eq? willing 'null)
              (and (exact-integer? willing) (<= 1 willing max-willing-minor)))
    (error who "backup ~a: record ~a has an invalid 'willingPerDayMinor'" context id))
  (define notes (hash-ref raw 'notes ""))
  (unless (and (string? notes) (<= (string-length notes) max-notes-chars))
    (error who "backup ~a: record ~a has an invalid 'notes'" context id))
  (define deleted-at (hash-ref raw 'deletedAt 'null))
  (if tombstoned?
      (unless (string? deleted-at)
        (error who "backup ~a: trash record ~a must carry a 'deletedAt' timestamp" context id))
      (unless (eq? deleted-at 'null)
        (error who "backup ~a: record ~a must not carry a 'deletedAt' in the devices list" context id)))
  (define (meta-string key)
    (define v (hash-ref raw key ""))
    (unless (string? v)
      (error who "backup ~a: record ~a has an invalid '~a'" context id key))
    v)
  (hasheq 'id id
          'name name
          'icon icon
          'category category
          'priceMinor price
          'currency currency
          'purchaseDate purchase-date
          'willingPerDayMinor willing
          'notes notes
          'createdAt (meta-string 'createdAt)
          'updatedAt (meta-string 'updatedAt)
          'editedBy (meta-string 'editedBy)
          'deletedAt deleted-at))

;; Validates a full backup payload and returns
;; (values devices trash preferences) with canonical records. Used by both
;; the validate preview and the restore commit, so a backup that passes the
;; preview restores byte-identically.
(define (validate-backup-payload payload today who)
  (unless (hash? payload)
    (error who "backup must be a JSON object"))
  (unless (and (equal? (hash-ref payload 'schema #f) "payback.backup")
               (equal? (hash-ref payload 'version #f) 1))
    (error who "backup must use schema \"payback.backup\" version 1"))
  (define data (hash-ref payload 'data #f))
  (unless (hash? data)
    (error who "backup 'data' must be a JSON object"))
  (define raw-devices (hash-ref data 'devices #f))
  (define raw-trash (hash-ref data 'trash #f))
  (unless (and (list? raw-devices) (list? raw-trash))
    (error who "backup 'devices' and 'trash' must be lists"))
  (unless (and (<= (length raw-devices) max-backup-devices)
               (<= (length raw-trash) max-backup-devices))
    (error who "backup devices and trash are capped at ~a records each" max-backup-devices))
  (define prefs (hash-ref data 'preferences #f))
  (unless (hash? prefs)
    (error who "backup 'preferences' must be a JSON object"))
  (define currency (hash-ref prefs 'currency #f))
  (unless (canonical-currency? currency)
    (error who "backup preferences 'currency' must be an ISO 4217 code"))
  (define theme (hash-ref prefs 'theme #f))
  (unless (member theme valid-themes)
    (error who "backup preferences 'theme' must be one of: ~a"
           (string-join valid-themes ", ")))
  (define language (hash-ref prefs 'language #f))
  (unless (member language valid-languages)
    (error who "backup preferences 'language' must be one of: ~a"
           (string-join valid-languages ", ")))
  (define preferences
    (hasheq 'currency currency 'theme theme 'language language))
  ;; ids must be globally unique across the two lists, or a restore would
  ;; write two different records for one id
  (define seen-ids (make-hash))
  (define (claim-id! id context)
    (when (hash-has-key? seen-ids id)
      (error who "backup ~a: device id '~a' appears more than once" context id))
    (hash-set! seen-ids id #t))
  (define devices
    (for/list ([raw (in-list raw-devices)] [i (in-naturals)])
      (define record
        (validate-backup-record raw today #f who (format "devices[~a]" i)))
      (claim-id! (hash-ref record 'id) (format "devices[~a]" i))
      record))
  (define trash
    (for/list ([raw (in-list raw-trash)] [i (in-naturals)])
      (define record
        (validate-backup-record raw today #t who (format "trash[~a]" i)))
      (claim-id! (hash-ref record 'id) (format "trash[~a]" i))
      record))
  (values devices trash preferences))
