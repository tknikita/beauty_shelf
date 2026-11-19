# Spec Delta

## Purpose

Lets a user attach a photo to a product by capturing one with the camera or
choosing one from the device's own gallery app, and guarantees the chosen photo
is cropped, persisted locally, and never silently lost when Android interrupts
the selection.

## ADDED Requirements

### Requirement: Gallery selection opens the device's own gallery app

On Android, choosing a gallery image from the product form SHALL open the
device's own gallery application when one is installed. The app MUST NOT hand
the request to Google Photos while a real gallery app is available. When no
gallery application is present, the system photo picker SHALL be used instead.

#### Scenario: Gallery app is preferred over Google Photos

- **WHEN** the user taps "Галерея" on a device where both an OEM gallery and Google Photos can handle image picking
- **THEN** the OEM gallery application is opened
- **AND** Google Photos is not launched as the picker

#### Scenario: No gallery app installed

- **WHEN** the user taps "Галерея" on a device with no gallery application
- **THEN** the system photo picker is opened
- **AND** every image on the device is visible in it

#### Scenario: Non-Android platforms are unchanged

- **WHEN** the app runs on iOS, web, or desktop
- **THEN** gallery selection keeps that platform's existing behaviour

### Requirement: A chosen photo is cropped, stored, and attached

After the user selects a photo, the system SHALL offer a square (1:1) crop, then
persist the cropped image to local storage and attach it to the product being
edited. Cancelling the crop MUST leave the product's current image unchanged.
A failure while storing the image MUST be reported to the user and MUST NOT
leave the product in a partially updated state.

#### Scenario: Successful attach

- **WHEN** the user picks a photo and confirms the square crop
- **THEN** the cropped image is saved to local storage
- **AND** the product form shows the new image
- **AND** a confirmation message is displayed

#### Scenario: Crop cancelled

- **WHEN** the user dismisses the crop screen without confirming
- **THEN** the product's existing image is left unchanged
- **AND** no new file is persisted

#### Scenario: Storage failure

- **WHEN** persisting the cropped image fails
- **THEN** the user is shown an error message
- **AND** the product's existing image is left unchanged

### Requirement: An interrupted selection is recovered

If the operating system destroys the app's activity while the camera or picker
is in the foreground, the app SHALL recover the lost selection on next launch
and SHALL NOT present the user with a lost photo and no indication of what
happened. Recovery MUST be attempted once for each interrupted selection and
MUST be idempotent.

#### Scenario: Activity destroyed during picking

- **WHEN** the app is terminated by the operating system while the camera or gallery picker is open, and the user completes the selection
- **THEN** on the next launch the app restores the lost selection
- **AND** continues the normal crop-and-attach flow for it

#### Scenario: Nothing was lost

- **WHEN** the app starts and no interrupted selection exists
- **THEN** recovery performs no action and the user sees no prompt

### Requirement: Photo selection requires no additional media permissions

Selecting a gallery photo SHALL NOT require the app to hold broad media-library
permissions. The app MUST NOT request read access to the user's whole photo
library in order to attach a single product photo.

#### Scenario: No broad media permission requested

- **WHEN** the user picks a photo from the gallery
- **THEN** the app does not request permission to read the entire photo library
- **AND** access is limited to the item the user selected
