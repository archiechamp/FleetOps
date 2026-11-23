# Feature 001 Interface Contract

**Status**: Review draft; [openapi.json](openapi.json) is the proposed machine-readable contract.
B-001/B-002 are resolved by the user's authorized table addition and UTF-16 rule.
No generated client, API route or UI component is created by this planning step.

## API Surface and Permissions

| Interface | Permission | Success | Key failure behavior |
| --- | --- | --- | --- |
| GET /api/v1/me | Valid current identity | 200 active own memberships/capabilities, paginated | 401 invalid/revoked identity; 503 status cannot be verified |
| GET /api/v1/vehicles | fleet.vehicle.read in verified X-Tenant-Id | 200 tenant-scoped page | 403 missing/unverified carrier; no foreign counts |
| GET /api/v1/vehicles/{vehicle_id} | fleet.vehicle.read in verified X-Tenant-Id | 200 matching own record | Same safe 404 for unknown and foreign-carrier record |
| POST /api/v1/vehicles | fleet.vehicle.read + fleet.vehicle.create in verified X-Tenant-Id | 201 after commit; same original result on an authorized replay | 403 capability denial; 422 invalid/extra fields; 409 unit/key conflict |

The general database companion's “CRUD” wording does not authorize update/delete workflows:
the approved feature spec excludes them. ROWVERSION tests remain database compatibility checks.
There is no AI, export, import, driver-data or finance endpoint in this feature.

## Request Context and Validation Order

1. Verify the bearer token using the selected provider SDK and configured signature/issuer/
   authorized party/expiry checks; verify current provider session status before SQL transactions.
2. Resolve the verified provider+subject to the active internal user. Unknown/unprovisioned or
   disabled internal business access is denied; no automatic tenant creation from JWT claims.
3. For vehicle routes, require X-Tenant-Id, parse a UUID and verify current active membership.
   Missing selection or an unauthorized selection is 403; a malformed nonempty UUID is 422.
   This explicit dependency behavior must not accidentally become FastAPI's default missing-header
   422. GET /me requires no selected tenant and returns only the verified user's memberships.
4. Resolve feature capabilities from tenant role bindings. Client roles, tenant_id in the body
   and Clerk organization identifiers are not permission authority.
5. Apply strict request validation, normalize trim-only fields and bind the verified request
   context to repositories and SQL session. Reject extra create fields, including tenant_id,
   role, asset_id, status and actor attribution. Contradictory body ownership is 422 without writes.
6. Reauthorize before returning any replay result; no SQL/HTTP error includes token, SQL text,
   raw provider error or another carrier's record metadata.

The live revocation/status query uses a bounded adapter before any DB transaction. Provider outage
is 503, not valid identity. Exact SDK behavior requires the real Clerk development spike.
All dependencies are configuration; never accept a client-controlled issuer or provider endpoint.

## Data and Pagination

VehicleCreate contains only unit_number, make, model, model_year and ownership_type; the JSON
schema defines mandatory fields and strict ownership values. Canonicalization trims outer
whitespace and retains display case. Case-insensitive collation controls uniqueness and equality
search. The Unicode contract below governs both registration and the exact unit-number filter.

Vehicle responses use fleet.vehicles.id, not the asset ID, and expose verified tenant_id,
submitted identifying values and a UTC created_at. No raw audit/user/permission-table records,
nullable optional finance fields or dispatch eligibility/status are returned.

The vehicle list defaults to 50 results, with a maximum of 100. Sort by normalized unit_number
under the chosen collation, then vehicle ID for a deterministic tie-breaker. unit_number is an
exact case-insensitive filter. Use parameterized keyset continuation; cursor contents are versioned,
authenticated and bound to user, carrier, filter and sort. Reject tampered or context-mismatched
cursors with 422; never interpolate them as SQL. /me uses its own user-bound stable membership
cursor. Responses carry no cross-carrier total count. Cache-Control is no-store for scoped reads.

## Unicode and Length Contract

FR-004 applies to normalized values, with **UTF-16 code units**, not code points, bytes or visible
graphemes. Valid supplementary characters are accepted and each consumes two units.

| Field | Accepted normalized length | Unchanged SQL column |
| --- | --- | --- |
| unit_number (create/response/search) | 1–30 UTF-16 code units | fleet.assets.unit_number NVARCHAR(30) |
| make | 1–80 UTF-16 code units | fleet.assets.make NVARCHAR(80) |
| model | 1–80 UTF-16 code units | fleet.assets.model NVARCHAR(80) |

The identical outer trim set for browser/API is U+0009–000D, U+0020, U+00A0, U+1680,
U+2000–200A, U+2028, U+2029, U+202F, U+205F, U+3000 and U+FEFF (ECMAScript whitespace
and line terminators). Do not substitute Python's broader default strip set. Preserve interior
characters, letter case and Unicode composition; no NFC/NFKC conversion or case folding.
Reject lone high/low surrogates rather than replacing them; supplementary surrogate pairs
represent a valid scalar. Validate well-formedness, trim, then count.

- Browser: count normalized JavaScript string.length after well-formedness checks, not
  Array.from/iteration/grapheme length. Provide a linked field error and code-unit counter,
  explaining that some symbols use two units. Keep over-limit input editable; do not rely on
  native maxlength or slicing, which can silently prevent/truncate entry and disagree on trim.
  Over-limit or malformed input sends no POST. A valid value is sent canonically, unchanged.
- FastAPI/Pydantic: strict string validation and the same explicit trim, then strict UTF-16-LE
  encoding byte length divided by two (no BOM). Translate unpaired-surrogate failures into
  422 field errors. Python len and Pydantic max_length alone do not enforce this contract.
  Direct over-limit API input is 422 before SQL, never a truncation/driver 500.
- OpenAPI: x-utf16-min-code-units/x-utf16-max-code-units, x-trim-set and
  x-unicode-well-formed declare the custom constraint. Generic JSON Schema maxLength is omitted
  on these request/search strings: it does not express post-trim UTF-16 capacity. The client
  adapter and server validator must implement the annotations and pass shared vectors; generation
  alone does not prove validation. Response fields use the same annotations and normalized values.
  Exported OpenAPI/drift checks must preserve these extensions.
- SQL Server: retain NVARCHAR(30/80) and explicit Latin1_General_100_CI_AS_SC collation.
  Parameter binding must preserve full Unicode without truncating casts; require ANSI_WARNINGS ON.
  Verify persisted bytes with DATALENGTH(value)/2 and exact round trips; LEN is not the UTF-16
  capacity oracle. Direct SQL overflow probes must fail without a truncated row; required/nonblank
  checks remain service rules, not additions to the unchanged physical CHECK constraints.
  Database capacity is a final boundary, not a replacement for accessible API validation.

### Shared Boundary Vectors

Use the same proposed tests/fixtures/vehicle_registration_vectors.json in API unit, web unit,
SQL integration and Selenium parameterization. Repeat notation below describes fixture values;
there is no literal “×” in submitted data. U+1F69A (🚚) is a supplementary character.

| Vector | Values after trim | Expected |
| --- | --- | --- |
| UC-01 | Blank/trim-only; one ASCII character | Reject blank; accept one for all three fields |
| UC-02 | Unit: 30 / 31 ASCII characters; make/model: 80 / 81 | Accept exact limit; reject one over |
| UC-03 | Unit: 15 × 🚚; 14 × 🚚 + A; 15 × 🚚 + A; 16 × 🚚 | 30/29 accepted, 31/32 rejected |
| UC-04 | Unit: 28 × A + 🚚; 29 × A + 🚚 | 30 accepted; 31 rejected despite only 30 code points |
| UC-05 | Each of make/model: 40 × 🚚; 39 × 🚚 + A; 40 × 🚚 + A; 41 × 🚚 | 80/79 accepted; 81/82 rejected |
| UC-06 | Each of make/model: 78 × A + 🚚; 79 × A + 🚚 | 80 accepted; 81 rejected despite only 80 code points |
| UC-07 | Exact-limit valid strings surrounded by each trim-set member; interior whitespace; U+0085 | Trim only listed outer characters; same lengths/hash as trimmed value. Interior whitespace and U+0085 remain and count |
| UC-08 | Lone high surrogate U+D800; lone low surrogate U+DC00; valid 🚚 pair | Reject malformed scalars in UI/API without a write; accept valid pair and round-trip without replacement |
| UC-09 | Unit: 15 × (e + U+0301); make/model: 40 × (e + U+0301), then append A | 30/80 accepted, 31/81 rejected; no grapheme-based counting or Unicode normalization |

Repeated-unit fixtures run in isolated test state so collation equality does not turn a length
test into a duplicate test. Exact response/read/replay values must retain supplementary characters.
Selenium covers accepted and rejected BMP/mixed/supplementary limits through actual form entry
and visible errors, correction, save and refresh. Lone-surrogate transport coverage is UI unit
and direct raw-JSON API coverage; browser automation must not silently replace invalid scalars.

## Registration and Replay

A valid submission carries an Idempotency-Key UUID. Authenticate and authorize read/create in
the selected tenant before any key lookup; recheck current internal authorization after waiting
for the SQL key lock and before disclosing a result. The key's scope is tenant, versioned
operation and membership, not just the UUID. No lookup uses another tenant/member as a fallback.

The [data model](../data-model.md#transaction-and-provenance) specifies exact canonical hashing,
typed response_reference, runtime grants and transaction protocol. After the locked lookup:

- Absent key: commit asset, vehicle, audit and complete retry receipt in the same SQL transaction.
  Return 201 only after that commit. A distinct-key unit conflict is VEHICLE_UNIT_CONFLICT (409)
  after full rollback, with no orphan successful receipt/audit.
- Equal key and canonical payload hash: authorize the referenced own record and return the
  original 201 body and Location, including after process replacement or SQL reconnect. Use the
  hash-verified retry's five input values and the immutable stored vehicle ID/tenant/created_at.
  Do not insert again, recompute creation time, or return current mutable identifying values.
- Equal scoped key with different valid canonical payload: IDEMPOTENCY_CONFLICT (409), with no
  original response disclosure or row change. Invalid payloads still fail field validation (422).
- Another membership/carrier's same raw UUID is a different scope: normal authorization,
  creation and unit-conflict rules apply; never return the first actor's original result.
  Revoked identity is 401; revoked membership/create permission is 403 even for saved results.
- Lock failure or unavailable/malformed stored result: safe 503, no successful response and no
  replacement create. A precommit failure leaves no truck/audit/receipt; an ambiguous postcommit
  disconnect is resolved only by retrying the same key and unchanged payload.

The original public result has exactly id, tenant_id, unit_number, make, model, model_year,
ownership_type and created_at (UTC with three fractional digits and Z). Location is
/api/v1/vehicles/{id}. Per-request correlation headers may differ. No public retry-table endpoint.
Receipts have no automatic expiry or purge in Feature 001; the required expires_at uses the
maximum DATETIME2(3) sentinel. A finite window or expanded response needs separate review.

## UI Contract

| Route | Visible behavior |
| --- | --- |
| /vehicles | Current verified carrier selection, paginated vehicle list, exact unit search and accessible distinct loading/empty/error states. Read/create users see Register truck; read-only users do not receive an enabled action. |
| /vehicles/new | Authorized registration form with labeled unit/make/model/year/ownership, required feedback, visible focus, pending/save/conflict/access-error states. Direct read-only navigation is denied. |
| /vehicles/{vehicle_id} | Read-only own-carrier identifying details and UTC-derived display time with explicit zone. Unknown/foreign IDs use the same non-disclosing not-found view. |

Form submission uses the shared OpenAPI-validated client and the current token/tenant context.
Client route guards improve navigation; backend dependencies remain authoritative. Disable
duplicate clicks while a request is pending, but rely on server guarantees for concurrency.
Keep correctable inputs after validation/unit conflict. Never render optimistic success before
the commit response.

Create a new submission key for a new validated attempt; retain it and its unchanged payload
across uncertain-response retry. A corrected payload after a definite validation/unit-conflict
starts a new attempt; do not silently reuse the old key with new data. The form keeps this state
only for the current identity/carrier and clears it on switch/logout.

Query keys contain verified user and tenant context. Switch/logout increments a scope generation,
cancels outstanding requests and clears caches, detail state, form drafts, submission keys and
success messages. Ignore old-scope responses even if cancellation loses a race. Revalidate on
browser history/pageshow; do not redisplay privileged data from an old cached page before scope
is confirmed. SB-06 tests both switch and sign-out in the same browser.

## Error and Test Contracts

The shared envelope is error { code, message, details } plus request_id. Field details identify
only offending fields and safe corrections; raw payloads are not echoed. For authenticated B,
A's ID and an unknown ID both yield RESOURCE_NOT_FOUND and the same message/status, apart from
the non-sensitive request correlation ID.

Real FastAPI-exported OpenAPI must be normalized and compared with this reviewed contract during
implementation; drift requires review. Unit validation, SQL behavior, Selenium feedback and
contracts must agree on permission, duplicate and string rules.
[Test mappings](../test-plan.md) provide all 22 acceptance case locations and CI commands.
