# SubPulse Privacy Policy

SubPulse is designed as a local-first macOS app.

## Local Data

Subscriptions, categories, payment methods, settings and backup files are stored locally on your Mac through SwiftData and user-selected JSON exports.

SubPulse does not upload your subscription data to a SubPulse server.

## Exchange Rates

If currency conversion is enabled or refreshed, SubPulse can request public exchange-rate data from the Central Bank of Russia endpoint:

```text
https://www.cbr.ru/scripts/XML_daily.asp
```

Only the standard HTTPS request for exchange-rate data is made. Your subscription names, prices and payment methods are not sent with this request.

## Reminders and Notifications

SubPulse can request permission to:

- show local macOS notifications for upcoming payments;
- create or update reminders in Reminders.app when you use the Reminders sync button.

These permissions are used only for subscription reminders that you configure in the app.

## Screenshot/Text Import

The import tool recognizes text from a screenshot or pasted text locally. It is not a private App Store receipt reader and does not access hidden App Store purchase history.

Always review recognized subscriptions before saving them.
