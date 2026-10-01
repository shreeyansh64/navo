# Navodhaya API contract - v2.1

Base URL: `http://127.0.0.1:8000/api` (local). Interactive docs: `/api/docs/`. OpenAPI schema: `/api/schema/`.

JSON requests use `Content-Type: application/json`. Profile completion uses `multipart/form-data`. Authenticated endpoints use `Authorization: Bearer <access_token>`.

Registration and password reset accept `@akgec.ac.in` and `@gmail.com` emails. Login accepts any email (so gate admins with other domains can sign in). Emails are trimmed and lowercased by the server.

## App flow

```text
REGISTER
email + password + confirm_password -> OTP emailed
verify OTP -> account created -> access + refresh tokens
complete-profile -> profile + QR

LOGIN
email + password -> access + refresh tokens
(no "profile" in response = call complete-profile)

FORGOT PASSWORD
email -> OTP emailed
verify OTP (optional check step)
email + otp + password + confirm_password -> password changed, all sessions logged out
```

An account is created only after the registration OTP is verified. Unverified emails never create a user.

## Error format

Every non-success response:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed.",
    "fields": {"email": ["Only AKGEC (@akgec.ac.in) or Gmail (@gmail.com) email addresses are allowed."]},
    "meta": {"retry_after": 60}
  }
}
```

`fields` appears for invalid request fields. `meta` appears for retry counters. Branch on `error.code` and HTTP status, not on `message`.

## Rate limits

- All `/auth/*` endpoints except `/auth/refresh/` and `/auth/complete-profile/`: 20 requests per minute per IP. Exceeding it returns `429 throttled`.
- OTP limits are separate (below).

## OTP rules

- 6 digits, valid for 600 seconds, single use
- Resend cooldown: 60 seconds
- Max 3 sends per hour per email and purpose
- Max 5 wrong attempts per OTP
- Registration and password reset OTPs are separate and not interchangeable

## Authentication

### `POST /auth/register/` - 200

Request:

```json
{"email":"a@akgec.ac.in","password":"min8chars","confirm_password":"min8chars"}
```

Password must be at least 8 characters and pass Django's validators (not too common, not all numeric, not too similar to the email).

Response:

```json
{"detail":"OTP sent.","expires_in":600,"resend_after":60,"attempts_remaining":5}
```

Errors: `400 validation_error` (bad domain, weak or short password, mismatch), `409 account_exists`, `429 otp_cooldown` / `otp_send_limit` / `throttled`, `503 otp_delivery_failed`.

### `POST /auth/verify-registration-otp/` - 201

Request: `{"email":"a@akgec.ac.in","otp":"123456"}`

Response:

```json
{"is_new_user":true,"tokens":{"access":"...","refresh":"..."}}
```

Errors: `400 invalid_otp` / `otp_expired` / `validation_error`, `409 account_exists`, `429 otp_attempt_limit` / `throttled`. After a failed attempt, `meta.attempts_remaining` is provided.

Password is not sent here. It was captured at `/auth/register/`.

### `POST /auth/login/` - 200

Request: `{"email":"user@example.com","password":"..."}`

Any email domain is accepted.

Response:

```json
{"is_new_user":false,"tokens":{"access":"...","refresh":"..."},"profile":{...}}
```

`profile` is omitted if the user has not completed their profile yet.

Errors: `400 validation_error`, `401 invalid_credentials`, `429 throttled`.

### `POST /auth/forgot-password/` - 200

Request: `{"email":"a@akgec.ac.in"}`

Response:

```json
{"detail":"If an account exists, an OTP has been sent.","expires_in":600,"resend_after":60,"attempts_remaining":5}
```

The response is identical whether or not the account exists, including when the cooldown or hourly send limit is active or email delivery fails. Clients should not rely on receiving an email; the UI should offer "resend" after `resend_after` seconds.

Errors: `400 validation_error`, `429 throttled`.

### `POST /auth/verify-forgot-password-otp/` - 200

Request: `{"email":"a@akgec.ac.in","otp":"123456"}`

Response: `{"detail":"OTP verified."}`

This only checks the OTP. It does not consume it. The same OTP must be sent again to `/auth/reset-password/`. Wrong guesses here count toward the 5 attempt limit.

Errors: `400 invalid_otp` / `otp_expired` / `validation_error`, `429 otp_attempt_limit` / `throttled`.

### `POST /auth/reset-password/` - 200

Request:

```json
{"email":"a@akgec.ac.in","otp":"123456","password":"min8chars","confirm_password":"min8chars"}
```

Response: `{"detail":"Password reset successfully."}`

Passwords are validated (including Django's validators) before the OTP is consumed, so a bad password does not burn the OTP.

After a successful reset, all existing refresh tokens for the user are invalidated. Other devices get `401 token_not_valid` on their next refresh and must log in again. Access tokens already issued remain valid until they expire (up to 30 minutes).

Errors: `400 validation_error` / `invalid_otp` / `otp_expired` / `invalid_request`, `429 otp_attempt_limit` / `throttled`.

### `POST /auth/refresh/` - 200

Request: `{"refresh":"<refresh token>"}`. Response is the rotated pair. The old refresh token is blacklisted after rotation. Invalid, expired, or blacklisted refresh tokens return `401 token_not_valid`. Access token lifetime is 30 minutes, refresh token lifetime is 7 days.

## Student profile and QR

### `POST /auth/complete-profile/` - 201

Bearer token: normal access token. Form fields: `full_name`, `section`, `year` (`1` or `2`), `branch` (one of `ME`, `ECE`, `EE`, `CSE`, `CSE(HINDI)`, `AIML`, `CSE(DS)`, `CSE(AIML)`, `IT`, `CS`, `CS IT`, `CE`), `student_number`, `image` (required; JPEG, PNG or WebP, max 5 MB).

Response:

```json
{"profile":{...},"qr_token":"...","qr_code_data_uri":"data:image/png;base64,..."}
```

`qr_code_data_uri` is usable directly as `<img src>`.

Errors: `400 validation_error`, `401 not_authenticated`, `409 profile_exists` / `student_number_taken`.

### `GET /me/` - 200

Bearer token: access token. Returns `profile`, `qr_token`, `qr_code_data_uri`.

Errors: `401`, `404 profile_incomplete`.

The QR token changes on each call (it embeds a timestamp) but every issued token stays valid. A QR is revoked only by changing the profile's `qr_id` in the admin. QR tokens are signed with the server `SECRET_KEY`; rotating that key invalidates every issued QR.

## Gate administration

Both endpoints need an access token for a user with role `admin` (or a Django staff user). Others get `403 permission_denied`.

### `POST /gate/scan/` - 200

Request: `{"qr_token":"<scanned QR content>"}`

Response: `{"valid":true,"student":{...}}`

Errors: `400 invalid_qr`, `401`, `403`.

### `POST /gate/assign-token/` - 201

Request: `{"qr_token":"<scanned QR content>","token_number":"42"}`

Response:

```json
{"detail":"Gate token assigned.","entry":{"id":1,"student_number":"...","token_number":"42","scanned_at":"..."}}
```

Errors: `400 invalid_qr` / `validation_error`, `401`, `403`, `409 gate_token_exists`.

A token number is unique per student, not globally. Two different students can be given the same `token_number`.

## Status-code rules

`200` success; `201` created; `400` malformed input or invalid OTP/QR; `401` missing, invalid or expired token, or bad credentials; `403` insufficient role; `404` missing resource; `409` uniqueness or state conflict; `429` OTP limits or request throttling; `503` OTP email delivery failure (register only).