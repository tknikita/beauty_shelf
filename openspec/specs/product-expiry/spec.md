# product-expiry Specification

## Purpose

Defines how the app derives a product's effective expiry date, remaining days,
and status from the manufacturer's printed expiry date and the period-after-
opening (PAO), so that a product is treated as usable only while both limits
still hold.

## Requirements

### Requirement: Effective expiry is the earlier of the printed expiry and the PAO limit

The system SHALL compute a product's effective expiry date as the earlier of the
manufacturer's printed expiry date and `opened_date + expiry_days_after_open`
whenever the product is opened and an open date is known. The period-after-
opening limit MUST NOT extend the effective expiry beyond the manufacturer's
printed date.

#### Scenario: Product not opened

- **WHEN** a product is not marked as opened
- **THEN** the effective expiry is the printed expiry date

#### Scenario: Opened product whose PAO ends before the printed date

- **WHEN** a product is opened with an open date, and
  `opened_date + PAO` is earlier than the printed expiry date
- **THEN** the effective expiry is `opened_date + PAO`

#### Scenario: Opened product whose PAO would extend past the printed date

- **WHEN** a product is opened with an open date, and
  `opened_date + PAO` is later than the printed expiry date
- **THEN** the effective expiry is the printed expiry date

#### Scenario: Opened product without an open date

- **WHEN** a product is marked as opened but has no open date
- **THEN** the effective expiry is the printed expiry date

#### Scenario: Product with no printed expiry date (PAO-only)

- **WHEN** a product has no printed expiry date but is opened with an open date
  and a PAO value
- **THEN** the effective expiry is `opened_date + PAO`

### Requirement: Remaining days and status derive from the effective expiry

The system SHALL derive a product's remaining days and expiry status from its
effective expiry date, not from the printed expiry date alone. Remaining days
MUST be the whole number of calendar days between today and the effective expiry
date.

#### Scenario: Countdown for an opened product

- **WHEN** an opened product's effective expiry is N calendar days from today
- **THEN** the remaining days equal N

#### Scenario: Expired product

- **WHEN** the effective expiry is before today
- **THEN** the product status is expired

#### Scenario: Status thresholds

- **WHEN** remaining days are fewer than 0
- **THEN** the status is expired
- **WHEN** remaining days are 0 up to fewer than 30
- **THEN** the status is danger
- **WHEN** remaining days are 30 up to fewer than 60
- **THEN** the status is warning
- **WHEN** remaining days are 60 or more
- **THEN** the status is ok

### Requirement: Expiry-dependent queries apply the same effective-expiry rule

The system SHALL apply the same effective-expiry rule when selecting products by
expiry proximity, so filters and notifications match the values shown on cards.

#### Scenario: Opened product included because PAO is within the window

- **WHEN** an opened product's printed expiry is beyond the query window but
  `opened_date + PAO` falls within it
- **THEN** the product is included in the expiring set

#### Scenario: Opened product included because the printed date is within the window

- **WHEN** an opened product's `opened_date + PAO` is beyond the query window but
  the printed expiry falls within it
- **THEN** the product is included in the expiring set

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

### Requirement: Product card marks opened packages

The system SHALL mark a product whose packaging is opened on its card, so the
period-after-opening date is understandable at a glance.

#### Scenario: Opened product

- **WHEN** a product is marked as opened
- **THEN** the card shows an opened-package indicator next to the status badge

#### Scenario: Closed product

- **WHEN** a product is not marked as opened
- **THEN** the card shows no opened-package indicator
