# BroML Platform — Privacy & Security Policy

**Last Updated:** October 31, 2026

## 1. Information We Collect
BroML collects information required to provide secure model registry services and threat defense:
- **Account Data:** Email address, display name, user ID, profile avatar URL.
- **Authentication Metadata:** Two-Factor Authentication enrollment status, timestamp of last authentication, active session identifiers. (We **never** store plaintext passwords, TOTP secret seeds in logs, or raw recovery codes).
- **Security Telemetry:** Origin IP addresses, Cloudflare Ray IDs, user-agent signatures, failed authentication counts, and challenge resolution statuses.

## 2. How We Protect Your Data
- **Cryptographic Hashing:** Passwords are hashed using strong adaptive hashing functions (PBKDF2/Argon2id) with unique per-user salts.
- **Strict Row-Level Authorization:** Cloud Firestore Security Rules enforce owner-only modification and deletion policies on registered models.
- **Cloudflare Edge Shields:** Traffic is routed through Cloudflare's secure edge with TLS 1.3 encryption and HSTS headers.
- **Redaction in Logs:** All internal and cloud logs automatically redact authorization headers, tokens, and sensitive credentials.

## 3. Session & Cookie Policy
- BroML uses secure cookies and local storage tokens (`HttpOnly`, `Secure`, `SameSite=Strict`) strictly for maintaining authenticated sessions and theme preferences.
- Users can revoke all active sessions at any time via the Security Dashboard.

## 4. Log Retention & Right to Erasure
- Security telemetry logs are retained for 30 days for incident investigation and attack trend analysis, after which they are purged.
- Users may request account deletion and data erasure by contacting support@broml.ai.

