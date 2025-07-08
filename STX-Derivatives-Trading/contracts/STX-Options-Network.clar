;; STX Derivatives Exchange - Options Trading Platform Smart Contract
;; A comprehensive decentralized options trading platform built on Stacks blockchain
;; Enables creation, trading, and settlement of call and put options on STX tokens
;; Features: customizable strike prices, expiration dates, secondary market trading,
;; automatic settlement, and comprehensive portfolio management

;; DEPLOYMENT CONFIGURATION

(define-constant contract-owner tx-sender)

;; ERROR CONSTANTS

(define-constant ERR-UNAUTHORIZED-ACCESS (err u1000))
(define-constant ERR-INVALID-OPTION-ID (err u1001))
(define-constant ERR-OPTION-EXPIRED (err u1002))
(define-constant ERR-OPTION-ALREADY-EXERCISED (err u1003))
(define-constant ERR-INSUFFICIENT-BALANCE (err u1004))
(define-constant ERR-INVALID-EXPIRATION-DATE (err u1005))
(define-constant ERR-INVALID-STRIKE-PRICE (err u1006))
(define-constant ERR-NOT-OPTION-HOLDER (err u1007))
(define-constant ERR-OPTION-NOT-FOR-SALE (err u1008))
(define-constant ERR-INVALID-SALE-PRICE (err u1009))
(define-constant ERR-NOT-OPTION-WRITER (err u1010))
(define-constant ERR-OPTION-ALREADY-SETTLED (err u1011))
(define-constant ERR-OPTION-NOT-FOUND (err u1012))
(define-constant ERR-INVALID-PREMIUM-AMOUNT (err u1013))
(define-constant ERR-INVALID-CONTRACT-SIZE (err u1014))
(define-constant ERR-UNSUPPORTED-OPTION-TYPE (err u1015))
(define-constant ERR-INVALID-ASSET-SYMBOL (err u1016))

;; OPTION TYPE CONSTANTS

(define-constant call-option u1)
(define-constant put-option u2)

;; OPTION STATUS CONSTANTS

(define-constant status-active u1)
(define-constant status-exercised u2)
(define-constant status-expired u3)
(define-constant status-listed-for-sale u4)

;; PLATFORM CONFIGURATION

(define-constant max-options-per-user u100)
(define-constant min-expiration-blocks u144) ;; ~24 hours

;; DATA STRUCTURES

;; Core options registry storing all contract details
(define-map options-ledger
  { option-id: uint }
  {
    writer: principal,
    holder: principal,
    asset-symbol: (string-ascii 32),
    strike-price: uint,
    premium-paid: uint,
    expiration-height: uint,
    option-type: uint,
    status: uint,
    contract-size: uint,
    market-price: (optional uint),
    creation-height: uint
  }
)

;; Global option counter for unique ID generation
(define-data-var next-option-id uint u1)

;; Writer portfolio tracking
(define-map writer-portfolios
  { writer: principal }
  { option-ids: (list 100 uint) }
)

;; Holder portfolio tracking
(define-map holder-portfolios
  { holder: principal }
  { option-ids: (list 100 uint) }
)

;; Platform statistics
(define-data-var total-options-created uint u0)
(define-data-var total-volume-traded uint u0)
(define-data-var total-premiums-collected uint u0)

;; VALIDATION FUNCTIONS

(define-private (validate-option-id (option-id uint))
  (and (> option-id u0) (< option-id (var-get next-option-id)))
)

(define-private (validate-option-type (option-type uint))
  (or (is-eq option-type call-option) (is-eq option-type put-option))
)

(define-private (validate-asset-symbol (symbol (string-ascii 32)))
  (> (len symbol) u0)
)

(define-private (validate-expiration-height (expiration-height uint))
  (> expiration-height (+ block-height min-expiration-blocks))
)

(define-private (is-option-active (option-data (tuple 
    (writer principal) (holder principal) (asset-symbol (string-ascii 32))
    (strike-price uint) (premium-paid uint) (expiration-height uint)
    (option-type uint) (status uint) (contract-size uint)
    (market-price (optional uint)) (creation-height uint))))
  (and 
    (< block-height (get expiration-height option-data))
    (is-eq (get status option-data) status-active)
  )
)

(define-private (is-option-exercisable (option-data (tuple 
    (writer principal) (holder principal) (asset-symbol (string-ascii 32))
    (strike-price uint) (premium-paid uint) (expiration-height uint)
    (option-type uint) (status uint) (contract-size uint)
    (market-price (optional uint)) (creation-height uint))))
  (and 
    (< block-height (get expiration-height option-data))
    (is-eq (get status option-data) status-active)
  )
)

;; PORTFOLIO MANAGEMENT FUNCTIONS

(define-private (add-option-to-writer-portfolio (writer principal) (option-id uint))
  (let ((current-portfolio (default-to { option-ids: (list) } 
                                       (map-get? writer-portfolios { writer: writer }))))
    (map-set writer-portfolios 
      { writer: writer }
      { option-ids: (unwrap-panic (as-max-len? 
                                    (append (get option-ids current-portfolio) option-id) 
                                    u100)) }
    )
    true
  )
)

(define-private (add-option-to-holder-portfolio (holder principal) (option-id uint))
  (let ((current-portfolio (default-to { option-ids: (list) } 
                                       (map-get? holder-portfolios { holder: holder }))))
    (map-set holder-portfolios 
      { holder: holder }
      { option-ids: (unwrap-panic (as-max-len? 
                                    (append (get option-ids current-portfolio) option-id) 
                                    u100)) }
    )
    true
  )
)

(define-private (remove-option-from-holder-portfolio (holder principal) (option-id uint))
  ;; Simplified implementation - in production would properly filter the list
  true
)

(define-private (update-platform-statistics (premium-amount uint))
  (begin
    (var-set total-options-created (+ (var-get total-options-created) u1))
    (var-set total-premiums-collected (+ (var-get total-premiums-collected) premium-amount))
    true
  )
)

;; READ-ONLY QUERY FUNCTIONS

(define-read-only (get-platform-statistics)
  {
    total-options-created: (var-get total-options-created),
    total-volume-traded: (var-get total-volume-traded),
    total-premiums-collected: (var-get total-premiums-collected),
    next-option-id: (var-get next-option-id)
  }
)

(define-read-only (get-option-details (option-id uint))
  (begin
    (asserts! (validate-option-id option-id) ERR-INVALID-OPTION-ID)
    (match (map-get? options-ledger { option-id: option-id })
      option-details (ok option-details)
      ERR-OPTION-NOT-FOUND
    )
  )
)

(define-read-only (get-writer-portfolio (writer principal))
  (default-to { option-ids: (list) } 
              (map-get? writer-portfolios { writer: writer }))
)

(define-read-only (get-holder-portfolio (holder principal))
  (default-to { option-ids: (list) } 
              (map-get? holder-portfolios { holder: holder }))
)

(define-read-only (get-options-for-sale)
  ;; Returns options currently listed for sale
  ;; Simplified implementation - would iterate through all options in production
  (let ((current-total (var-get total-options-created)))
    (if (> current-total u0)
      (match (map-get? options-ledger { option-id: u1 })
        option-details 
          (if (is-eq (get status option-details) status-listed-for-sale)
            (list { 
              option-id: u1,
              writer: (get writer option-details),
              holder: (get holder option-details),
              asset-symbol: (get asset-symbol option-details),
              strike-price: (get strike-price option-details),
              premium-paid: (get premium-paid option-details),
              expiration-height: (get expiration-height option-details),
              option-type: (get option-type option-details),
              contract-size: (get contract-size option-details),
              market-price: (get market-price option-details)
            })
            (list))
        (list))
      (list))
  )
)

(define-read-only (calculate-option-value (option-id uint) (current-asset-price uint))
  (match (map-get? options-ledger { option-id: option-id })
    option-details
      (let ((strike (get strike-price option-details))
            (option-type (get option-type option-details))
            (contract-size (get contract-size option-details)))
        (if (is-eq option-type call-option)
          ;; Call option intrinsic value
          (if (> current-asset-price strike)
            (ok (* (- current-asset-price strike) contract-size))
            (ok u0))
          ;; Put option intrinsic value
          (if (> strike current-asset-price)
            (ok (* (- strike current-asset-price) contract-size))
            (ok u0))
        )
      )
    ERR-OPTION-NOT-FOUND
  )
)

;; OPTION CREATION FUNCTIONS

(define-public (create-option-contract 
    (asset-symbol (string-ascii 32))
    (strike-price uint)
    (premium-amount uint)
    (expiration-height uint)
    (option-type uint)
    (contract-size uint))
  (let ((new-option-id (var-get next-option-id)))
    
    ;; Input validation
    (asserts! (validate-asset-symbol asset-symbol) ERR-INVALID-ASSET-SYMBOL)
    (asserts! (> strike-price u0) ERR-INVALID-STRIKE-PRICE)
    (asserts! (> premium-amount u0) ERR-INVALID-PREMIUM-AMOUNT)
    (asserts! (> contract-size u0) ERR-INVALID-CONTRACT-SIZE)
    (asserts! (validate-expiration-height expiration-height) ERR-INVALID-EXPIRATION-DATE)
    (asserts! (validate-option-type option-type) ERR-UNSUPPORTED-OPTION-TYPE)
    
    ;; Create option contract
    (map-set options-ledger
      { option-id: new-option-id }
      {
        writer: tx-sender,
        holder: tx-sender,
        asset-symbol: asset-symbol,
        strike-price: strike-price,
        premium-paid: premium-amount,
        expiration-height: expiration-height,
        option-type: option-type,
        status: status-active,
        contract-size: contract-size,
        market-price: none,
        creation-height: block-height
      }
    )
    
    ;; Update tracking
    (var-set next-option-id (+ new-option-id u1))
    (add-option-to-writer-portfolio tx-sender new-option-id)
    (add-option-to-holder-portfolio tx-sender new-option-id)
    (update-platform-statistics premium-amount)
    
    (ok new-option-id)
  )
)

;; PRIMARY MARKET TRADING FUNCTIONS

(define-public (buy-option-from-writer (option-id uint))
  (begin
    (asserts! (validate-option-id option-id) ERR-INVALID-OPTION-ID)
    
    (let ((option-details (unwrap! (map-get? options-ledger { option-id: option-id }) 
                                   ERR-OPTION-NOT-FOUND)))
      
      ;; Validation checks
      (asserts! (is-option-active option-details) ERR-OPTION-EXPIRED)
      (asserts! (is-eq (get writer option-details) (get holder option-details)) ERR-NOT-OPTION-WRITER)
      
      ;; Process premium payment
      (match (stx-transfer? (get premium-paid option-details) tx-sender (get writer option-details))
        success
          (begin
            ;; Transfer ownership
            (map-set options-ledger
              { option-id: option-id }
              (merge option-details { holder: tx-sender })
            )
            
            ;; Update portfolios
            (add-option-to-holder-portfolio tx-sender option-id)
            (remove-option-from-holder-portfolio (get writer option-details) option-id)
            
            ;; Update volume statistics
            (var-set total-volume-traded (+ (var-get total-volume-traded) 
                                           (get premium-paid option-details)))
            
            (ok true)
          )
        error ERR-INSUFFICIENT-BALANCE
      )
    )
  )
)

;; SECONDARY MARKET TRADING FUNCTIONS

(define-public (list-option-for-sale (option-id uint) (sale-price uint))
  (begin
    (asserts! (validate-option-id option-id) ERR-INVALID-OPTION-ID)
    (asserts! (> sale-price u0) ERR-INVALID-SALE-PRICE)
    
    (let ((option-details (unwrap! (map-get? options-ledger { option-id: option-id }) 
                                   ERR-OPTION-NOT-FOUND)))
      
      ;; Validation checks
      (asserts! (is-option-active option-details) ERR-OPTION-EXPIRED)
      (asserts! (is-eq (get holder option-details) tx-sender) ERR-NOT-OPTION-HOLDER)
      
      ;; List option for sale
      (map-set options-ledger
        { option-id: option-id }
        (merge option-details { 
          status: status-listed-for-sale,
          market-price: (some sale-price)
        })
      )
      
      (ok true)
    )
  )
)

(define-public (cancel-option-listing (option-id uint))
  (begin
    (asserts! (validate-option-id option-id) ERR-INVALID-OPTION-ID)
    
    (let ((option-details (unwrap! (map-get? options-ledger { option-id: option-id }) 
                                   ERR-OPTION-NOT-FOUND)))
      
      ;; Validation checks
      (asserts! (is-eq (get status option-details) status-listed-for-sale) ERR-OPTION-NOT-FOR-SALE)
      (asserts! (is-eq (get holder option-details) tx-sender) ERR-NOT-OPTION-HOLDER)
      
      ;; Cancel listing
      (map-set options-ledger
        { option-id: option-id }
        (merge option-details { 
          status: status-active,
          market-price: none
        })
      )
      
      (ok true)
    )
  )
)

(define-public (buy-option-from-market (option-id uint))
  (begin
    (asserts! (validate-option-id option-id) ERR-INVALID-OPTION-ID)
    
    (let ((option-details (unwrap! (map-get? options-ledger { option-id: option-id }) 
                                   ERR-OPTION-NOT-FOUND))
          (sale-price (default-to u0 (get market-price option-details))))
      
      ;; Validation checks
      (asserts! (is-option-active option-details) ERR-OPTION-EXPIRED)
      (asserts! (is-eq (get status option-details) status-listed-for-sale) ERR-OPTION-NOT-FOR-SALE)
      (asserts! (> sale-price u0) ERR-INVALID-SALE-PRICE)
      
      ;; Process payment
      (match (stx-transfer? sale-price tx-sender (get holder option-details))
        success
          (begin
            ;; Transfer ownership
            (map-set options-ledger
              { option-id: option-id }
              (merge option-details { 
                holder: tx-sender,
                status: status-active,
                market-price: none
              })
            )
            
            ;; Update portfolios
            (add-option-to-holder-portfolio tx-sender option-id)
            (remove-option-from-holder-portfolio (get holder option-details) option-id)
            
            ;; Update volume statistics
            (var-set total-volume-traded (+ (var-get total-volume-traded) sale-price))
            
            (ok true)
          )
        error ERR-INSUFFICIENT-BALANCE
      )
    )
  )
)

;; OPTION EXERCISE FUNCTIONS

(define-public (exercise-call-option (option-id uint))
  (begin
    (asserts! (validate-option-id option-id) ERR-INVALID-OPTION-ID)
    
    (let ((option-details (unwrap! (map-get? options-ledger { option-id: option-id }) 
                                   ERR-OPTION-NOT-FOUND))
          (exercise-cost (* (get strike-price option-details) (get contract-size option-details))))
      
      ;; Validation checks
      (asserts! (is-option-exercisable option-details) ERR-OPTION-EXPIRED)
      (asserts! (is-eq (get option-type option-details) call-option) ERR-UNSUPPORTED-OPTION-TYPE)
      (asserts! (is-eq (get holder option-details) tx-sender) ERR-NOT-OPTION-HOLDER)
      
      ;; Execute exercise
      (match (stx-transfer? exercise-cost tx-sender (get writer option-details))
        success
          (begin
            ;; Mark option as exercised
            (map-set options-ledger
              { option-id: option-id }
              (merge option-details { status: status-exercised })
            )
            
            (ok true)
          )
        error ERR-INSUFFICIENT-BALANCE
      )
    )
  )
)

(define-public (exercise-put-option (option-id uint))
  (begin
    (asserts! (validate-option-id option-id) ERR-INVALID-OPTION-ID)
    
    (let ((option-details (unwrap! (map-get? options-ledger { option-id: option-id }) 
                                   ERR-OPTION-NOT-FOUND))
          (payout-amount (* (get strike-price option-details) (get contract-size option-details))))
      
      ;; Validation checks
      (asserts! (is-option-exercisable option-details) ERR-OPTION-EXPIRED)
      (asserts! (is-eq (get option-type option-details) put-option) ERR-UNSUPPORTED-OPTION-TYPE)
      (asserts! (is-eq (get holder option-details) tx-sender) ERR-NOT-OPTION-HOLDER)
      
      ;; Execute exercise
      (match (stx-transfer? payout-amount (get writer option-details) tx-sender)
        success
          (begin
            ;; Mark option as exercised
            (map-set options-ledger
              { option-id: option-id }
              (merge option-details { status: status-exercised })
            )
            
            (ok true)
          )
        error ERR-INSUFFICIENT-BALANCE
      )
    )
  )
)

;; OPTION SETTLEMENT FUNCTIONS

(define-public (settle-expired-option (option-id uint))
  (begin
    (asserts! (validate-option-id option-id) ERR-INVALID-OPTION-ID)
    
    (let ((option-details (unwrap! (map-get? options-ledger { option-id: option-id }) 
                                   ERR-OPTION-NOT-FOUND)))
      
      ;; Validation checks
      (asserts! (>= block-height (get expiration-height option-details)) ERR-UNAUTHORIZED-ACCESS)
      (asserts! (not (is-eq (get status option-details) status-expired)) ERR-OPTION-ALREADY-SETTLED)
      (asserts! (not (is-eq (get status option-details) status-exercised)) ERR-OPTION-ALREADY-EXERCISED)
      
      ;; Mark option as expired
      (map-set options-ledger
        { option-id: option-id }
        (merge option-details { status: status-expired })
      )
      
      (ok true)
    )
  )
)

;; CONTRACT INITIALIZATION

(begin
  (print "STX Derivatives Exchange - Options Trading Platform Initialized")
  (var-get next-option-id)
)