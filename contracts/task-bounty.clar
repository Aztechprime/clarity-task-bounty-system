;; Task Bounty System Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-task-not-found (err u101))
(define-constant err-already-claimed (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-not-claimant (err u104))
(define-constant err-task-not-completed (err u105))

;; Data structures
(define-map tasks 
    { task-id: uint }
    {
        creator: principal,
        bounty: uint,
        description: (string-utf8 256),
        is-claimed: bool,
        claimant: (optional principal),
        is-completed: bool
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
                    is-completed: false
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
    (if (is-eq (some tx-sender) (get claimant task))
        (begin
            (try! (as-contract (stx-transfer? (get bounty task) tx-sender (get creator task))))
            (map-set tasks
                { task-id: task-id }
                (merge task { is-completed: true })
            )
            (ok true)
        )
        err-not-claimant
    ))
)

(define-public (cancel-task (task-id uint))
    (let (
        (task (unwrap! (get-task task-id) err-task-not-found))
    )
    (if (is-eq tx-sender (get creator task))
        (begin
            (try! (as-contract (stx-transfer? (get bounty task) tx-sender tx-sender)))
            (map-delete tasks { task-id: task-id })
            (ok true)
        )
        err-owner-only
    ))
)
