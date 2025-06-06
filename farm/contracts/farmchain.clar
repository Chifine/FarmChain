;; FarmChain Core Contract - Supply Chain Transparency
;; Tracks products from farm to market with timestamps and geo-tags

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PRODUCT_NOT_FOUND (err u101))
(define-constant ERR_INVALID_STAGE (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u104))
(define-constant ERR_INVALID_INPUT (err u105))
(define-constant ERR_INVALID_ID (err u106))
(define-constant ERR_INVALID_COORDINATES (err u107))

;; Input validation functions
(define-private (is-valid-string (input (string-ascii 500)))
  (and (> (len input) u0) (<= (len input) u500))
)

;; Utility functions
(define-private (min-uint (a uint) (b uint))
  (if (< a b) a b)
)

(define-private (is-valid-short-string (input (string-ascii 100)))
  (and (> (len input) u0) (<= (len input) u100))
)

(define-private (is-valid-medium-string (input (string-ascii 50)))
  (and (> (len input) u0) (<= (len input) u50))
)

(define-private (is-valid-coordinates (lat int) (lng int))
  (and (>= lat -90000000) (<= lat 90000000) 
       (>= lng -180000000) (<= lng 180000000))
)

;; Data Variables
(define-data-var next-product-id uint u1)
(define-data-var platform-fee-percentage uint u250) ;; 2.5%

;; Data Maps
(define-map products
  { product-id: uint }
  {
    farmer: principal,
    product-name: (string-ascii 100),
    category: (string-ascii 50),
    origin-farm: (string-ascii 100),
    created-at: uint,
    current-stage: (string-ascii 50),
    is-active: bool,
    total-tips: uint
  }
)

(define-map product-journey
  { product-id: uint, stage-id: uint }
  {
    stage-name: (string-ascii 50),
    location: (string-ascii 100),
    latitude: int,
    longitude: int,
    timestamp: uint,
    handler: principal,
    notes: (string-ascii 500),
    verified: bool
  }
)

(define-map product-stage-count
  { product-id: uint }
  { count: uint }
)

(define-map verified-handlers
  { handler: principal }
  { verified: bool, handler-type: (string-ascii 50) }
)

(define-map farmer-profiles
  { farmer: principal }
  {
    name: (string-ascii 100),
    farm-name: (string-ascii 100),
    location: (string-ascii 100),
    certification: (string-ascii 100),
    total-products: uint,
    total-tips-received: uint,
    reputation-score: uint
  }
)

;; Read-only functions
(define-read-only (get-product (product-id uint))
  (map-get? products { product-id: product-id })
)

(define-read-only (get-product-journey (product-id uint) (stage-id uint))
  (map-get? product-journey { product-id: product-id, stage-id: stage-id })
)

(define-read-only (get-product-stage-count (product-id uint))
  (default-to { count: u0 } (map-get? product-stage-count { product-id: product-id }))
)

(define-read-only (get-farmer-profile (farmer principal))
  (map-get? farmer-profiles { farmer: farmer })
)

(define-read-only (is-verified-handler (handler principal))
  (match (map-get? verified-handlers { handler: handler })
    handler-data (get verified handler-data)
    false
  )
)

(define-read-only (get-next-product-id)
  (var-get next-product-id)
)

(define-read-only (get-platform-fee-percentage)
  (var-get platform-fee-percentage)
)

;; Public functions

;; Register a new farmer profile
(define-public (register-farmer (name (string-ascii 100)) (farm-name (string-ascii 100)) 
                               (location (string-ascii 100)) (certification (string-ascii 100)))
  (let ((farmer tx-sender)
        (validated-name (unwrap! (if (is-valid-short-string name) (some name) none) (err u105)))
        (validated-farm (unwrap! (if (is-valid-short-string farm-name) (some farm-name) none) (err u105)))
        (validated-location (unwrap! (if (is-valid-short-string location) (some location) none) (err u105)))
        (validated-cert (unwrap! (if (is-valid-short-string certification) (some certification) none) (err u105))))
    (asserts! (is-none (map-get? farmer-profiles { farmer: farmer })) ERR_ALREADY_EXISTS)
    (ok (map-set farmer-profiles
      { farmer: farmer }
      {
        name: validated-name,
        farm-name: validated-farm,
        location: validated-location,
        certification: validated-cert,
        total-products: u0,
        total-tips-received: u0,
        reputation-score: u100
      }
    ))
  )
)

;; Register a new product
(define-public (register-product (product-name (string-ascii 100)) (category (string-ascii 50)) 
                                (origin-farm (string-ascii 100)))
  (let (
    (product-id (var-get next-product-id))
    (farmer tx-sender)
    (validated-name (unwrap! (if (is-valid-short-string product-name) (some product-name) none) (err u105)))
    (validated-category (unwrap! (if (is-valid-medium-string category) (some category) none) (err u105)))
    (validated-farm (unwrap! (if (is-valid-short-string origin-farm) (some origin-farm) none) (err u105)))
  )
    (asserts! (is-some (map-get? farmer-profiles { farmer: farmer })) ERR_UNAUTHORIZED)
    
    (map-set products
      { product-id: product-id }
      {
        farmer: farmer,
        product-name: validated-name,
        category: validated-category,
        origin-farm: validated-farm,
        created-at: stacks-block-height,
        current-stage: "registered",
        is-active: true,
        total-tips: u0
      }
    )
    
    (map-set product-stage-count { product-id: product-id } { count: u0 })
    
    (match (map-get? farmer-profiles { farmer: farmer })
      farmer-data (map-set farmer-profiles
        { farmer: farmer }
        (merge farmer-data { total-products: (+ (get total-products farmer-data) u1) })
      )
      false
    )
    
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

;; Add a journey stage
(define-public (add-journey-stage (product-id uint) (stage-name (string-ascii 50)) 
                                 (location (string-ascii 100)) (latitude int) (longitude int)
                                 (notes (string-ascii 500)))
  (let (
    (validated-id (unwrap! (if (> product-id u0) (some product-id) none) (err u106)))
    (validated-stage (unwrap! (if (is-valid-medium-string stage-name) (some stage-name) none) (err u105)))
    (validated-location (unwrap! (if (is-valid-short-string location) (some location) none) (err u105)))
    (validated-notes (unwrap! (if (is-valid-string notes) (some notes) none) (err u105)))
    (product-data (unwrap! (map-get? products { product-id: validated-id }) ERR_PRODUCT_NOT_FOUND))
    (stage-count-data (get-product-stage-count validated-id))
    (new-stage-id (+ (get count stage-count-data) u1))
    (handler tx-sender)
  )
    (asserts! (get is-active product-data) ERR_INVALID_STAGE)
    (asserts! (is-valid-coordinates latitude longitude) (err u107))
    
    (map-set product-journey
      { product-id: validated-id, stage-id: new-stage-id }
      {
        stage-name: validated-stage,
        location: validated-location,
        latitude: latitude,
        longitude: longitude,
        timestamp: stacks-block-height,
        handler: handler,
        notes: validated-notes,
        verified: (is-verified-handler handler)
      }
    )
    
    (map-set product-stage-count { product-id: validated-id } { count: new-stage-id })
    
    (map-set products
      { product-id: validated-id }
      (merge product-data { current-stage: validated-stage })
    )
    
    (ok new-stage-id)
  )
)

;; Tip a farmer
(define-public (tip-farmer (product-id uint) (tip-amount uint))
  (let (
    (validated-id (unwrap! (if (> product-id u0) (some product-id) none) (err u106)))
    (validated-amount (unwrap! (if (>= tip-amount u1000000) (some tip-amount) none) (err u104)))
    (product-data (unwrap! (map-get? products { product-id: validated-id }) ERR_PRODUCT_NOT_FOUND))
    (farmer (get farmer product-data))
    (platform-fee (/ (* validated-amount (var-get platform-fee-percentage)) u10000))
    (farmer-amount (- validated-amount platform-fee))
  )
    (try! (stx-transfer? farmer-amount tx-sender farmer))
    (try! (stx-transfer? platform-fee tx-sender CONTRACT_OWNER))
    
    (map-set products
      { product-id: validated-id }
      (merge product-data { total-tips: (+ (get total-tips product-data) validated-amount) })
    )

    (match (map-get? farmer-profiles { farmer: farmer })
      farmer-data
        (map-set farmer-profiles
          { farmer: farmer }
          (merge farmer-data {
            total-tips-received: (+ (get total-tips-received farmer-data) farmer-amount),
            reputation-score: (min-uint u1000 (+ (get reputation-score farmer-data) u5))
          })
        )
      false
    )

    (ok farmer-amount)
  )
)

;; Verify a handler (only contract owner)
(define-public (verify-handler (handler principal) (handler-type (string-ascii 50)))
  (let ((validated-type (unwrap! (if (is-valid-medium-string handler-type) (some handler-type) none) (err u105))))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set verified-handlers
      { handler: handler }
      { verified: true, handler-type: validated-type }
    ))
  )
)

;; Update platform fee (only contract owner)
(define-public (update-platform-fee (new-fee-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-fee-percentage u1000) ERR_INVALID_STAGE) ;; Max 10%
    (ok (var-set platform-fee-percentage new-fee-percentage))
  )
)

;; Deactivate product (farmer or contract owner only)
(define-public (deactivate-product (product-id uint))
  (let (
    (validated-id (unwrap! (if (> product-id u0) (some product-id) none) (err u106)))
    (product-data (unwrap! (map-get? products { product-id: validated-id }) ERR_PRODUCT_NOT_FOUND))
  )
    (asserts! (or (is-eq tx-sender (get farmer product-data)) (is-eq tx-sender CONTRACT_OWNER)) ERR_UNAUTHORIZED)
    (ok (map-set products
      { product-id: validated-id }
      (merge product-data { is-active: false })
    ))
  )
)
