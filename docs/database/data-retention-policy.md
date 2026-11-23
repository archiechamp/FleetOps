# Proposed retention, recovery and classification policy

Pending legal, operational, contractual and security review. No automated purge is approved by this document. Every table and column has classification and retention metadata in model.json. Access is least privilege; exports and AI source disclosures inherit restrictions. GDPR/state laws and motor-carrier-specific rules must be assessed for actual operating jurisdiction; this document does not establish legal compliance.

| Data | Proposed default | Safeguard |
|---|---|---|
| raw GPS | 90 days | preserve required mileage/IFTA evidence and legal holds; retain latest projection safely |
| chat messages | 90 days, configurable | authorized history, deletion requests, tool results and sources included |
| AI usage | 12 months | minimize identifiers; provider retention reviewed separately |
| transient import/failure payloads | 30 days | do not delete authoritative financial or compliance evidence |
| audit | 1–3 years | append-only runtime; controlled archival and access audit |
| vehicle, driver, trip, docs, finance | approved lifecycle and statutory schedule | hold overrides; no cascading deletion |
| backups | propose PITR and approved windows | encrypted, restore tests, separate access, lifecycle aligned to legal policy |

Policy implementation must include data owner, retention trigger date, hold check, export/deletion authorization, dependency order, dry-run count, approval, audit, restore testing, and provider deletion where applicable. Define RPO/RTO and test restore before production; proposed pilot target RPO <= 24 hours and RTO <= 4 hours pending business approval (managed PITR may support stronger objectives). Do not log secrets, unrestricted PII, raw AI payloads, or sensitive financial data. Rotate credentials and restrict document signing. Preserve regulatory evidence when deleting general telemetry; no ad hoc production purge jobs.
