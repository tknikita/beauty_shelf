# Spec Delta

## ADDED Requirements

### Requirement: Product card marks opened packages

The system SHALL mark a product whose packaging is opened on its card, so the
period-after-opening date is understandable at a glance.

#### Scenario: Opened product

- **WHEN** a product is marked as opened
- **THEN** the card shows an opened-package indicator next to the status badge

#### Scenario: Closed product

- **WHEN** a product is not marked as opened
- **THEN** the card shows no opened-package indicator
