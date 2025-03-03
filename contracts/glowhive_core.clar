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

;; [Previous code remains unchanged until reviews map...]

;; Add read-only function to get review
(define-read-only (get-review (review-id uint))
  (map-get? reviews review-id)
)

;; [Previous helper functions remain unchanged...]

(define-public (edit-review (review-id uint) (new-content (string-utf8 1000)) (new-rating uint))
  (let
    ((review (unwrap! (map-get? reviews review-id) err-not-found)))
    (asserts! (is-eq tx-sender (get author review)) err-not-authorized)
    (asserts! (validate-rating new-rating) err-invalid-rating)
    ;; Fixed timelock check - now prevents edits after timelock period
    (asserts! (> edit-timelock (- block-height (get created-at review))) err-edit-timelock)
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
