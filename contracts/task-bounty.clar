;; Task Bounty System Contract with Rating System

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

;; Data structures
(define-map tasks 
    { task-id: uint }
    {
        creator: principal,
        bounty: uint,
        description: (string-utf8 256),
        is-claimed: bool,
        claimant: (optional principal),
        is-completed: bool,
        worker-rating: (optional uint),
        creator-rating: (optional uint)
    }
)

(define-map user-ratings
    { user: principal }
    {
        total-rating: uint,
        rating-count: uint,
        avg-rating: uint
    }
)

(define-data-var task-counter uint u0)

;; Read only functions
(define-read-only (get-task (task-id uint))
    (map-get? tasks { task-id: task-id })
)

(define-read-only (get-task-count)
    (ok (var-get task-counter))
)

(define-read-only (get-user-rating (user principal))
    (default-to 
        { total-rating: u0, rating-count: u0, avg-rating: u0 }
        (map-get? user-ratings { user: user })
    )
)

;; Rating helper function
(define-private (update-user-rating (user principal) (new-rating uint))
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

;; Public functions
(define-public (create-task (bounty uint) (description (string-utf8 256)))
    (let (
        (task-id (+ (var-get task-counter) u1))
    )
    (if (>= (stx-get-balance tx-sender) bounty)
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
                    creator-rating: none
                }
            )
            (var-set task-counter task-id)
            (ok task-id)
        )
        err-insufficient-funds
    ))
)

(define-public (claim-task (task-id uint))
    (let (
        (task (unwrap! (get-task task-id) err-task-not-found))
    )
    (if (get is-claimed task)
        err-already-claimed
        (begin
            (map-set tasks
                { task-id: task-id }
                (merge task {
                    is-claimed: true,
                    claimant: (some tx-sender)
                })
            )
            (ok true)
        )
    ))
)

(define-public (complete-task (task-id uint))
    (let (
        (task (unwrap! (get-task task-id) err-task-not-found))
    )
    (asserts! (is-eq (some tx-sender) (get claimant task)) err-not-claimant)
    (asserts! (not (get is-completed task)) err-already-completed)
    (begin
        (try! (as-contract (stx-transfer? (get bounty task) tx-sender (get creator task))))
        (map-set tasks
            { task-id: task-id }
            (merge task { is-completed: true })
        )
        (ok true)
    ))
)

(define-public (rate-worker (task-id uint) (rating uint))
    (let (
        (task (unwrap! (get-task task-id) err-task-not-found))
    )
    (asserts! (is-eq tx-sender (get creator task)) err-owner-only)
    (asserts! (get is-completed task) err-task-not-completed)
    (asserts! (is-none (get worker-rating task)) err-already-rated)
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
    (begin
        (update-user-rating (unwrap! (get claimant task) err-task-not-found) rating)
        (map-set tasks
            { task-id: task-id }
            (merge task { worker-rating: (some rating) })
        )
        (ok true)
    ))
)

(define-public (rate-creator (task-id uint) (rating uint))
    (let (
        (task (unwrap! (get-task task-id) err-task-not-found))
    )
    (asserts! (is-eq (some tx-sender) (get claimant task)) err-not-claimant)
    (asserts! (get is-completed task) err-task-not-completed)
    (asserts! (is-none (get creator-rating task)) err-already-rated)
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
    (begin
        (update-user-rating (get creator task) rating)
        (map-set tasks
            { task-id: task-id }
            (merge task { creator-rating: (some rating) })
        )
        (ok true)
    ))
)

(define-public (cancel-task (task-id uint))
    (let (
        (task (unwrap! (get-task task-id) err-task-not-found))
    )
    (asserts! (is-eq tx-sender (get creator task)) err-owner-only)
    (asserts! (not (get is-claimed task)) err-already-claimed)
    (begin
        (try! (as-contract (stx-transfer? (get bounty task) tx-sender tx-sender)))
        (map-delete tasks { task-id: task-id })
        (ok true)
    ))
)
