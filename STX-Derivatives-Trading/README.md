# STX Derivatives Exchange - Options Trading Platform

A comprehensive decentralized options trading platform built on the Stacks blockchain that enables creation, trading, and settlement of call and put options on STX tokens.

## Features

- **Option Creation**: Create customizable call and put options with flexible strike prices and expiration dates
- **Primary Market Trading**: Buy options directly from writers
- **Secondary Market Trading**: List and trade options on the secondary market
- **Automatic Settlement**: Automated settlement of expired options
- **Portfolio Management**: Track all your written and held options
- **Real-time Valuation**: Calculate intrinsic value of options based on current market prices

## Option Types Supported

- **Call Options**: Right to buy STX at a specified strike price
- **Put Options**: Right to sell STX at a specified strike price

## Contract Architecture

### Data Structures

- **Options Ledger**: Core registry storing all option contract details
- **Portfolio Tracking**: Separate tracking for writers and holders
- **Platform Statistics**: Volume, premiums, and activity metrics

### Key Constants

- Maximum options per user: 100
- Minimum expiration time: 144 blocks (~24 hours)
- Supported option types: Call (1) and Put (2)
- Option statuses: Active, Exercised, Expired, Listed for Sale

## Public Functions

### Option Creation

#### `create-option-contract`
```clarity
(create-option-contract 
    (asset-symbol (string-ascii 32))
    (strike-price uint)
    (premium-amount uint)
    (expiration-height uint)
    (option-type uint)
    (contract-size uint))
```

Creates a new option contract with specified parameters.

**Parameters:**
- `asset-symbol`: The underlying asset symbol (e.g., "STX")
- `strike-price`: The strike price in microSTX
- `premium-amount`: The premium cost in microSTX
- `expiration-height`: Block height when option expires
- `option-type`: 1 for call, 2 for put
- `contract-size`: Number of tokens covered by the contract

**Returns:** Option ID of the newly created contract

### Primary Market Trading

#### `buy-option-from-writer`
```clarity
(buy-option-from-writer (option-id uint))
```

Purchase an option directly from its writer by paying the premium.

### Secondary Market Trading

#### `list-option-for-sale`
```clarity
(list-option-for-sale (option-id uint) (sale-price uint))
```

List your option for sale on the secondary market.

#### `cancel-option-listing`
```clarity
(cancel-option-listing (option-id uint))
```

Cancel an active listing and remove option from secondary market.

#### `buy-option-from-market`
```clarity
(buy-option-from-market (option-id uint))
```

Purchase an option from the secondary market at the listed price.

### Option Exercise

#### `exercise-call-option`
```clarity
(exercise-call-option (option-id uint))
```

Exercise a call option by paying the strike price to acquire the underlying asset.

#### `exercise-put-option`
```clarity
(exercise-put-option (option-id uint))
```

Exercise a put option by selling the underlying asset at the strike price.

### Settlement

#### `settle-expired-option`
```clarity
(settle-expired-option (option-id uint))
```

Settle an expired option that was not exercised.

## Read-Only Functions

### `get-option-details`
```clarity
(get-option-details (option-id uint))
```

Retrieve complete details of a specific option contract.

### `get-platform-statistics`
```clarity
(get-platform-statistics)
```

Get platform-wide statistics including total options created, volume traded, and premiums collected.

### `get-writer-portfolio` / `get-holder-portfolio`
```clarity
(get-writer-portfolio (writer principal))
(get-holder-portfolio (holder principal))
```

Retrieve all option IDs associated with a specific writer or holder.

### `get-options-for-sale`
```clarity
(get-options-for-sale)
```

List all options currently available for purchase on the secondary market.

### `calculate-option-value`
```clarity
(calculate-option-value (option-id uint) (current-asset-price uint))
```

Calculate the intrinsic value of an option based on current market price.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 1000 | ERR-UNAUTHORIZED-ACCESS | User not authorized for this action |
| 1001 | ERR-INVALID-OPTION-ID | Option ID does not exist |
| 1002 | ERR-OPTION-EXPIRED | Option has already expired |
| 1003 | ERR-OPTION-ALREADY-EXERCISED | Option has already been exercised |
| 1004 | ERR-INSUFFICIENT-BALANCE | Insufficient STX balance |
| 1005 | ERR-INVALID-EXPIRATION-DATE | Invalid expiration date |
| 1006 | ERR-INVALID-STRIKE-PRICE | Invalid strike price |
| 1007 | ERR-NOT-OPTION-HOLDER | Caller is not the option holder |
| 1008 | ERR-OPTION-NOT-FOR-SALE | Option is not listed for sale |
| 1009 | ERR-INVALID-SALE-PRICE | Invalid sale price |
| 1010 | ERR-NOT-OPTION-WRITER | Caller is not the option writer |

## Usage Examples

### Creating a Call Option
```clarity
;; Create a call option for STX with strike price 100, premium 5, expiring in 1000 blocks
(contract-call? .options-platform create-option-contract 
    "STX" 
    u100000000  ;; 100 STX in microSTX
    u5000000    ;; 5 STX premium
    u1000       ;; expires in 1000 blocks
    u1          ;; call option
    u100        ;; contract size
)
```

### Buying an Option
```clarity
;; Buy option with ID 1 from writer
(contract-call? .options-platform buy-option-from-writer u1)
```

### Listing an Option for Sale
```clarity
;; List option ID 1 for sale at 7 STX
(contract-call? .options-platform list-option-for-sale u1 u7000000)
```

### Exercising a Call Option
```clarity
;; Exercise call option ID 1
(contract-call? .options-platform exercise-call-option u1)
```

## Security Considerations

- All functions include comprehensive input validation
- Options cannot be exercised after expiration
- Premium payments are processed atomically
- Portfolio tracking prevents double-spending
- Access controls ensure only authorized users can perform actions

## Deployment

1. Deploy the contract to the Stacks blockchain
2. The deployer becomes the contract owner
3. Users can immediately begin creating and trading options

## Integration

This contract can be integrated with:
- Front-end trading interfaces
- Price oracles for real-time asset pricing
- Portfolio management applications
- DeFi protocols for additional yield strategies