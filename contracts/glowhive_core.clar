;; GlowHive Core Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-rating (err u103))
(define-constant err-edit-timelock (err u104))

;; Edit timelock (in blocks)
(define-constant edit-timelock u144) ;; ~24 hours

;; Data Variables
(define-data-var next-review-id uint u0)
(define-data-var next-routine-id uint u0)
(define-data-var next-collection-id uint u0)

;; Data Maps
(define-map users principal 
  {
    username: (string-ascii 50),
    reputation: uint,
    review-count: uint,
    last-updated: uint
  }
)

(define-map reviews uint 
  {
    author: principal,
    product-name: (string-ascii 100),
    rating: uint,
    content: (string-utf8 1000),
    votes: uint,
    created-at: uint,
    last-edited: (optional uint)
  }
)

(define-map routines uint
  {
    author: principal,
    title: (string-ascii 100),
    steps: (string-utf8 2000),
    created-at: uint
  }
)

(define-map collections uint 
  {
    author: principal,
    name: (string-ascii 100),
    description: (string-utf8 500),
    products: (list 20 (string-ascii 100)),
    created-at: uint
  }
)

(define-map votes-given principal 
  {
    reviews: (list 100 uint),
    last-vote: uint
  }
)

;; Events
(define-data-var last-event-id uint u0)

(define-map events uint 
  {
    event-type: (string-ascii 20),
    user: principal,
    data: (optional (string-utf8 200)),
    timestamp: uint
  }
)

;; Helper Functions
(define-private (emit-event (event-type (string-ascii 20)) (data (optional (string-utf8 200))))
  (let
    ((event-id (var-get last-event-id)))
    (map-set events event-id
      {
        event-type: event-type,
        user: tx-sender,
        data: data,
        timestamp: block-height
      }
    )
    (var-set last-event-id (+ event-id u1))
    true
  )
)

(define-private (validate-rating (rating uint))
  (and (>= rating u1) (<= rating u5))
)

;; Public Functions

;; User Management
(define-public (register-user (username (string-ascii 50)))
  (let
    (
      (user-exists (default-to false (get username (map-get? users tx-sender))))
    )
    (if user-exists
      err-already-exists
      (begin
        (map-set users tx-sender {
          username: username,
          reputation: u0,
          review-count: u0,
          last-updated: block-height
        })
        (emit-event "user-registered" (some username))
        (ok true)
      )
    )
  )
)

(define-public (update-username (new-username (string-ascii 50)))
  (let
    ((user-data (unwrap! (map-get? users tx-sender) err-not-authorized)))
    (map-set users tx-sender (merge user-data {
      username: new-username,
      last-updated: block-height
    }))
    (emit-event "username-updated" (some new-username))
    (ok true)
  )
)

;; Review Management
(define-public (post-review (product-name (string-ascii 100)) (rating uint) (content (string-utf8 1000)))
  (let
    (
      (review-id (var-get next-review-id))
      (user-data (unwrap! (map-get? users tx-sender) err-not-authorized))
    )
    (asserts! (validate-rating rating) err-invalid-rating)
    (map-set reviews review-id {
      author: tx-sender,
      product-name: product-name,
      rating: rating,
      content: content,
      votes: u0,
      created-at: block-height,
      last-edited: none
    })
    (var-set next-review-id (+ review-id u1))
    (map-set users tx-sender (merge user-data {
      review-count: (+ (get review-count user-data) u1)
    }))
    (emit-event "review-posted" (some product-name))
    (ok review-id)
  )
)

(define-public (edit-review (review-id uint) (new-content (string-utf8 1000)) (new-rating uint))
  (let
    ((review (unwrap! (map-get? reviews review-id) err-not-found)))
    (asserts! (is-eq tx-sender (get author review)) err-not-authorized)
    (asserts! (validate-rating new-rating) err-invalid-rating)
    (asserts! (< (- block-height (get created-at review)) edit-timelock) err-edit-timelock)
    (map-set reviews review-id (merge review {
      content: new-content,
      rating: new-rating,
      last-edited: (some block-height)
    }))
    (emit-event "review-edited" (some (get product-name review)))
    (ok true)
  )
)

;; [Rest of the contract remains unchanged...]
