# Spec Delta

## ADDED Requirements

### Requirement: Product card shows the effective expiry date

The system SHALL show a product's effective expiry date on its card, formatted as
`до DD.MM.YYYY`, without labelling which limit (printed expiry or period after
opening) produced the date.

#### Scenario: Opened product

- **WHEN** a product is opened with a known open date
- **THEN** the card shows only the effective expiry date, with no binding-limit label

#### Scenario: Product not opened

- **WHEN** a product is not opened
- **THEN** the card shows the printed expiry date, with no binding-limit label

## REMOVED Requirements

### Requirement: Product card indicates which limit is binding

**Reason**: The binding-limit suffix (`· после вскрытия` / `· срок производителя`)
was removed from the card — it cluttered the date line and delivered little value;
users only need the effective date.

**Migration**: `Product.expiryBasis` remains available on the model for any
future use, but the card renders only `до DD.MM.YYYY`. See the ADDED
requirement "Product card shows the effective expiry date".
