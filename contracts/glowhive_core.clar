;; GlowHive Core Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))

;; Data Variables
(define-data-var next-review-id uint u0)
(define-data-var next-routine-id uint u0)

;; Data Maps
(define-map users principal 
  {
    username: (string-ascii 50),
    reputation: uint,
    review-count: uint
  }
)

(define-map reviews uint 
  {
    author: principal,
    product-name: (string-ascii 100),
    rating: uint,
    content: (string-utf8 1000),
    votes: uint,
    created-at: uint
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

(define-map votes-given principal (list 100 uint))

;; Public Functions

;; User Management
(define-public (register-user (username (string-ascii 50)))
  (let
    (
      (user-exists (default-to false (get username (map-get? users tx-sender))))
    )
    (if user-exists
      err-already-exists
      (ok (map-set users tx-sender {
        username: username,
        reputation: u0,
        review-count: u0
      }))
    )
  )
)

;; Review Management
(define-public (post-review (product-name (string-ascii 100)) (rating uint) (content (string-utf8 1000)))
  (let
    (
      (review-id (var-get next-review-id))
      (user-data (unwrap! (map-get? users tx-sender) err-not-authorized))
    )
    (map-set reviews review-id {
      author: tx-sender,
      product-name: product-name,
      rating: rating,
      content: content,
      votes: u0,
      created-at: block-height
    })
    (var-set next-review-id (+ review-id u1))
    (map-set users tx-sender (merge user-data {
      review-count: (+ (get review-count user-data) u1)
    }))
    (ok review-id)
  )
)

;; Routine Management
(define-public (share-routine (title (string-ascii 100)) (steps (string-utf8 2000)))
  (let
    (
      (routine-id (var-get next-routine-id))
    )
    (map-set routines routine-id {
      author: tx-sender,
      title: title,
      steps: steps,
      created-at: block-height
    })
    (var-set next-routine-id (+ routine-id u1))
    (ok routine-id)
  )
)

;; Voting System
(define-public (vote-review (review-id uint))
  (let
    (
      (review (unwrap! (map-get? reviews review-id) err-not-found))
      (voter-votes (default-to (list) (map-get? votes-given tx-sender)))
    )
    (asserts! (not (is-eq (get author review) tx-sender)) err-not-authorized)
    (asserts! (not (is-some (index-of voter-votes review-id))) err-already-exists)
    
    (map-set reviews review-id (merge review {
      votes: (+ (get votes review) u1)
    }))
    (map-set votes-given tx-sender (unwrap-panic (as-max-len? (append voter-votes review-id) u100)))
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-user-info (user principal))
  (map-get? users user)
)

(define-read-only (get-review (review-id uint))
  (map-get? reviews review-id)
)

(define-read-only (get-routine (routine-id uint))
  (map-get? routines routine-id)
)