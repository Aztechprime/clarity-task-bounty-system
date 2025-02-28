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

;; Task Status Enumeration
(define-data-var task-status-none uint u0)
(define-data-var task-status-open uint u1)
(define-data-var task-status-claimed uint u2)
(define-data-var task-status-completed uint u3)
(define-data-var task-status-expired uint u4)

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
        creator-rating: (optional uint),
        deadline: uint,
        status: uint
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

;; Events
(define-data-var last-event-id uint u0)

(define-map events
    { event-id: uint }
    {
        event-type: (string-utf8 24),
        task-id: uint,
        user: principal,
        timestamp: uint
    }
)

;; Event helper function
(define-private (emit-event (event-type (string-utf8 24)) (task-id uint))
    (let ((event-id (+ (var-get last-event-id) u1)))
        (map-set events
            { event-id: event-id }
            {
                event-type: event-type,
                task-id: task-id,
                user: tx-sender,
                timestamp: block-height
            }
        )
        (var-set last-event-id event-id)
        (ok event-id)
    )
)

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

;; Private functions
(define-private (is-task-expired (deadline uint))
    (>= block-height deadline)
)

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
(define-public (create-task (bounty uint) (description (string-utf8 256)) (deadline uint))
    (let (
        (task-id (+ (var-get task-counter) u1))
    )
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

;; Additional functions remain the same but with enhanced status checks
;; and event emissions (not shown for brevity)
