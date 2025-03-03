;; Task Bounty System Contract with Rating System and Enhanced Security

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-task-not-found (err u101))
(define-constant err-already-claimed (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-not-claimant (err u104))
(define-constant err-task-not-completed (err u105))
(define-constant err-already-rated (err u106))
(define-constant err-invalid-rating (err u107))
(define-constant err-already-completed (err u108))
(define-constant err-task-expired (err u109))
(define-constant err-invalid-deadline (err u110))
(define-constant err-invalid-bounty (err u111))
(define-constant min-bounty u100) ;; Minimum bounty amount
(define-constant max-rating u5)   ;; Maximum rating value
(define-constant min-rating u1)   ;; Minimum rating value

;; Task Status Enumeration
(define-data-var task-status-none uint u0)
(define-data-var task-status-open uint u1)
(define-data-var task-status-claimed uint u2)
(define-data-var task-status-completed uint u3)
(define-data-var task-status-expired uint u4)

;; [Previous data structures remain the same...]

;; Enhanced private functions
(define-private (validate-rating (rating uint))
  (and (>= rating min-rating) (<= rating max-rating))
)

(define-private (update-user-rating (user principal) (new-rating uint))
  (begin
    (asserts! (validate-rating new-rating) err-invalid-rating)
    (let (
      (current-stats (get-user-rating user))
      (new-total (+ (get total-rating current-stats) new-rating))
      (new-count (+ (get rating-count current-stats) u1))
    )
    (map-set user-ratings
      { user: user }
      {
        total-rating: new-total,
        rating-count: new-count,
        avg-rating: (/ new-total new-count)
      }
    ))
  )
)

;; Enhanced public functions
(define-public (create-task (bounty uint) (description (string-utf8 256)) (deadline uint))
  (let (
    (task-id (+ (var-get task-counter) u1))
  )
  (asserts! (>= bounty min-bounty) err-invalid-bounty)
  (asserts! (> deadline block-height) err-invalid-deadline)
  (asserts! (>= (stx-get-balance tx-sender) bounty) err-insufficient-funds)
  (begin
    (try! (stx-transfer? bounty tx-sender (as-contract tx-sender)))
    (map-set tasks
      { task-id: task-id }
      {
        creator: tx-sender,
        bounty: bounty,
        description: description,
        is-claimed: false,
        claimant: none,
        is-completed: false,
        worker-rating: none,
        creator-rating: none,
        deadline: deadline,
        status: (var-get task-status-open)
      }
    )
    (var-set task-counter task-id)
    (try! (emit-event "task-created" task-id))
    (ok task-id)
  ))
)

;; [Remaining functions stay the same...]
