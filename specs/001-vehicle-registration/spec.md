# Feature Specification: Feature 001 — Vehicle Registration

**Feature Branch**: Not created; this workspace has no Git repository.

**Feature Directory**: `specs/001-vehicle-registration`

**Created**: 2026-11-23

**Status**: Revised planning draft — B-001/B-002 decisions incorporated on 2026-11-23

**Input**: User description: "Define Feature 001 for FleetOps: vehicle registration. An authorized
dispatcher can register a truck and see it after refreshing the Vehicles page. A read-only dispatcher
cannot register a truck. A dispatcher from another carrier cannot see that truck. Use the FleetOps
constitution, root spec.md, and spec-kit/feature-test-generation.md. Include acceptance criteria for
unit tests, FastAPI integration tests against SQL Server, and Selenium browser tests."

**Authority and traceability**: [FleetOps constitution v1.0.0](../../.specify/memory/constitution.md),
[root specification](../../spec.md) AUTH-01, AUTH-02, FLT-01 and DEV-008;
[architecture notes](../../docs/architecture-notes.md) ADR-003, ADR-004 and ADR-008;
[feature test generation instructions](../../spec-kit/feature-test-generation.md).
This is the first registration slice of FLT-01, not completion of the entire truck lifecycle.

## User Scenarios & Testing *(mandatory)*

All three stories are P1 release requirements. Each can be tested with independent setup; no
test may depend on another test registering a truck first. The technical verification criteria
below are explicitly requested acceptance constraints, not an implementation design.

### User Story 1 - Register and Find a Truck After Refresh (Priority: P1)

As a dispatcher with permission to read and create vehicles for my carrier, I can open Vehicles,
register a truck, receive confirmation and find the saved truck after refreshing the page.
This gives my carrier a persistent, identifiable fleet record.

**Why this priority**: Registration and durable visibility are the feature's primary user value.

**Independent Test**: Sign in as Carrier A's authorized dispatcher, register a truck with a fresh
unit number and valid identifying details, then refresh Vehicles and search for that number.
Exactly one result belongs to Carrier A and displays the submitted details.

**Acceptance Scenarios**:

1. **US1-AC1 — Given** an active Carrier A membership with vehicle read/create permissions and a
   unit number not used in A, **When** the dispatcher submits valid registration details,
   **Then** one truck is saved for A, success is shown only after the save completes, and the
   saved truck is available in Vehicles with the submitted unit number, make, model, year and
   ownership type.
2. **US1-AC2 — Given** that registration succeeded, **When** the dispatcher refreshes Vehicles and
   searches for the unit number, **Then** exactly one matching truck remains and its details
   match the saved values.
3. **US1-AC3 — Given** the registration form, **When** a required value is missing, blank or
   invalid, **Then** the relevant field has an accessible error, no truck is saved, and the user
   can correct the value and submit successfully.
4. **US1-AC4 — Given** A already has the submitted unit number, **When** the dispatcher submits a
   new registration with that number, **Then** a duplicate conflict is shown, the existing truck
   is unchanged, and no second truck is saved.
5. **US1-AC5 — Given** a registration saved but its response was lost, **When** the authorized
   dispatcher retries the same submission, including after service restart, **Then** the original
   result is recovered and refresh shows one truck, with no second successful registration event.
   Reusing that submission identity with different valid normalized details produces a conflict.

---

### User Story 2 - Browse Without Registration Permission (Priority: P1)

As a dispatcher with vehicle read permission only, I can inspect my carrier's trucks while being
prevented from registering trucks, including by bypassing normal page controls.

**Why this priority**: A role label or visible page must never grant unauthorized business access.

**Independent Test**: Use a read-only dispatcher with a seeded truck in their own carrier. Verify
that the truck is readable, registration is unavailable, and a direct create attempt is denied
without changing the carrier's fleet.

**Acceptance Scenarios**:

1. **US2-AC1 — Given** an active read-only dispatcher, **When** they open Vehicles, **Then** their
   own carrier's trucks are visible and no enabled registration action is offered.
2. **US2-AC2 — Given** the same read-only dispatcher, **When** they directly open the registration
   address or submit a create request outside the normal UI, **Then** access is denied and no
   truck or partial registration is saved.
3. **US2-AC3 — Given** a dispatcher opened the form while authorized, **When** their create
   permission or membership is revoked before submission, **Then** the next submission is denied,
   no truck is saved, and the user is shown an access error rather than success.
4. **US2-AC4 — Given** no valid sign-in session, **When** a user attempts to read or register
   vehicles, **Then** access requires sign-in and no protected records are returned or created.

---

### User Story 3 - Keep Each Carrier's Trucks Private (Priority: P1)

As a dispatcher, I can see only trucks belonging to a carrier where I have verified membership
and vehicle read permission. Knowing another carrier's truck number or record address grants
no access.

**Why this priority**: Carrier isolation is a mandatory data-security boundary.

**Independent Test**: Seed Carrier A with an A-only truck and seed both A and B with their own
`TRK-001`. In an independent browser session, sign in as B's read-only dispatcher. Confirm that
B's own `TRK-001` is visible, the A-only number yields no result, and A's direct record address
reveals no details.

**Acceptance Scenarios**:

1. **US3-AC1 — Given** an A-only truck and B's authorized reader, **When** B lists or searches
   Vehicles for the A-only number, **Then** the truck and its identifying details are absent and
   the search displays the ordinary empty state.
2. **US3-AC2 — Given** B knows A's truck identifier or record address, **When** B attempts direct
   access, **Then** the result is indistinguishable from an unknown record and discloses no
   existence, ownership or truck details.
3. **US3-AC3 — Given** both carriers have a truck numbered `TRK-001`, **When** each dispatcher
   opens that number under their own carrier, **Then** each sees only their carrier's distinct
   record. A unit number is not globally unique.
4. **US3-AC4 — Given** a dispatcher selects an unauthorized carrier or supplies another carrier
   in a registration request, **When** access is evaluated, **Then** the request cannot read or
   create records in that carrier.
5. **US3-AC5 — Given** a user has switched from authorized Carrier A to authorized Carrier B, or
   signed out of A and signed in as a B-only user in the same browser, **When** Vehicles loads,
   **Then** A's prior records and registration result are cleared and only B's authorized data
   can appear, including after refresh and browser back navigation.

---

### Edge Cases

- Whitespace-only unit number, make or model; overlong UTF-16 values; malformed Unicode;
  missing or out-of-range year; missing or unsupported ownership type: identify the field and
  save nothing. Supplementary Unicode characters count as two code units, not one; valid
  exact-limit values round-trip unchanged, while one-code-unit-over values fail without truncation.
- Two independent submissions race for the same unit number in one carrier: one registration
  succeeds and the other reports a duplicate conflict; no partial or duplicate truck remains.
- A unit number differs only in surrounding whitespace or letter case: apply the same documented
  normalization and uniqueness rule to registration, conflict checks and search.
- An expired/invalid token, revoked identity, inactive membership or missing verified carrier
  context: deny access before reading or writing protected records.
- Permissions change while a form is open, or between a successful submission and its retry:
  recheck current authorization; never disclose a saved result to a now-unauthorized caller.
- A save fails before completion: show a recoverable error without success or a partial truck.
  An uncertain response after commit: resolve the original submission through retry, not a second
  registration.
- The list is loading, empty, filtered to no matches or unavailable: show distinct accessible
  states; an outage must not be presented as a verified empty fleet.
- Registration requires no assignment, safety clearance, HOS assessment, GPS data or financial
  record. Saving a truck must not imply that it is legally eligible or available to dispatch.

### Required Verification — DEV-008

These criteria define tests to generate with application code. They are not claims that tests
already exist or passed. The feature plan MUST map every case below to its executable file/name,
fixture, user action and observable assertion before implementation.

#### Fixtures and Test Boundaries

- Use fictional Carrier A and Carrier B, each with a distinct truck record numbered `TRK-001`.
  A's primary dispatcher has vehicle read/create permissions; B's primary dispatcher has read
  permission only. Add a separate A read-only member to distinguish role denial from tenant
  denial, and an explicitly authorized A/B member for carrier-switch coverage.
- Use a unique new unit number for each independent test. Seed each cross-carrier test's A-only
  truck in that test's setup; do not depend on the registration browser test.
- Use the real application authorization path. Controlled identity boundary doubles/test
  identities are permitted, but FastAPI token verification and membership/permission checks
  MUST remain active. No production data, credentials or restricted driver information is allowed.

#### Unit Test Acceptance

| Case | Requirements / scenarios | Action and required observation |
| --- | --- | --- |
| UT-01 — `test_vehicle_create_requires_create_permission` | FR-001–003; US1-AC1, US2-AC1–3 | Exercise the production permission decision with read/create, read-only, inactive and revoked memberships. Only active authorized membership in the selected carrier permits creation; a dispatcher role name alone never suffices. |
| UT-02 — registration validation | FR-004–005, FR-008; US1-AC3–5 | Cover missing/blank and boundary-length fields, integer year boundaries, ownership choices and unit-number normalization. Invalid values are rejected; valid boundary values remain valid. Include shared BMP/supplementary/combining UTF-16 vectors at 29/30/31 and 79/80/81 units, identical trimming, lone-surrogate rejection and canonical payload-hash determinism/change detection. |
| UT-03 — required unit form feedback | FR-004, FR-010; US1-AC3 | Submit with no unit number. An error identifies the field accessibly and no create request is sent. Correct valid input can be submitted. Run the shared Unicode vectors in browser validation: overflow stays editable with an accessible error and no POST; valid supplementary boundaries submit unchanged. |
| UT-04 — permission and request states | FR-003, FR-010; US2-AC1, US1-AC1 | Read-only UI has no enabled registration action. Form/list components expose loading, empty, access-denied, duplicate and unavailable states. Success is absent while a save is pending or failed. |
| UT-05 — carrier-session changes | FR-002, FR-011; US3-AC5 | Change carrier or sign out while a previous list/save response is pending. Previously scoped data is cleared, and a late response cannot populate the new carrier's view. |

#### FastAPI Integration Test Acceptance Against SQL Server

Run through production FastAPI request handling and the application's Alembic-migrated, isolated
SQL Server database. Assertions MUST cover both HTTP outcomes and committed state using runtime
database permissions for application actions. SQLite, mocked repositories and reference-DDL-only
rehearsals do not satisfy these criteria.

| Case | Requirements / scenarios | Action and required observation |
| --- | --- | --- |
| IT-01 — authorized registration and persisted read | FR-001–004, FR-007, FR-009; US1-AC1–2 | A creates a valid truck. Initial creation returns 201 with its stable record identifier and saved details. A subsequent independent list/detail request returns the same truck. Exactly one asset and one associated vehicle exist in A, with the authenticated creator and creation time; no other carrier changes. Exactly one success audit and one complete actor-scoped retry receipt commit with that pair. |
| IT-02 — `test_duplicate_unit_is_scoped_to_tenant` | FR-005; US1-AC4, US3-AC3 | A creates a fresh unit, then submits the same normalized unit with a different request key. The latter returns 409 and inserts nothing. Read each carrier's seeded `TRK-001` and assert distinct authorized IDs; cover case/outer-whitespace variants. |
| IT-03 — `test_read_only_member_cannot_create_vehicle` | FR-001–003; US2-AC1–2 | Both B's reader and A's separate read-only member can read their own carrier's trucks, but valid create attempts return 403 with zero new asset/vehicle records. Client-supplied roles cannot change the result. |
| IT-04 — invalid identity and revoked access | FR-001, FR-008; US2-AC3–4 | Missing, invalid, expired or revoked credentials return 401. A valid identity with disabled/revoked membership or missing verified carrier context is denied with 403. After revoking create permission, both a new submission and a saved-result retry are denied. No denied write changes fleet state. |
| IT-05 — cross-carrier list, ID and write probes | FR-002, FR-006; US3-AC1–4 | B's list/search excludes A's unique truck; A's ID and an unknown ID both return non-disclosing 404 responses to B. A's creator cannot select B or forge B ownership: reject unverified carrier context with 403; reject ownership input contradicting verified context with 422 and no write in either carrier. |
| IT-06 — concurrent duplicate registration | FR-005, FR-007; edge cases | Two independently authorized requests/connections create the same new A unit with different request keys. Exactly one returns 201 and the other 409; only one complete asset/vehicle pair remains. Exactly one success audit and one receipt remain; the losing distinct key leaves no receipt. |
| IT-07 — durable retry and payload conflict | FR-008; US1-AC5 | Discard the committed response, replace the serving process while keeping SQL state, then retry the same authorized key/canonical payload: identical original 201 body/Location (including timestamp), exactly one asset/vehicle/audit/receipt. Concurrent same-key requests also return that result. Changed valid payload, including display-case-only change, returns 409 with no mutation. Another member/carrier's same raw key cannot retrieve the original. Revoked access denies replay. Verify no automatic expiry/key reuse, normalization/hash stability, and fail-closed behavior if the stored reference is unavailable. |
| IT-08 — server validation and atomic failure | FR-004, FR-007; US1-AC3 | Direct invalid fields, over-limit UTF-16 values or lone surrogates return safe 422 with zero inserts. Accepted supplementary/mixed boundaries persist/read/replay without truncation or replacement. Fail after each asset/vehicle/audit/receipt insert, including immediately before commit: all four roll back. Precommit process loss leaves none; a subsequent unchanged-key retry succeeds once. |
| IT-09 — reused connections and missing context | FR-001–002, FR-006; US3-AC1–4 | Exercise A, B, missing-context and A requests using the application's connection pool. Every result stays within its verified carrier; missing context reveals nothing. Attempts to attach a vehicle to another carrier's asset fail. Retry records also obey A/B/no-context RLS; wrong-tenant retry actor references fail. |
| IT-10 — migration and creation provenance | FR-007–009, FR-012 | A fresh database upgraded by application migrations supports the cases above with required tenant/uniqueness constraints. Validate drift and upgrade from an earlier application revision when one exists. Saved provenance identifies the verified membership, carrier and UTC creation time; a replay creates no second successful registration event. Verify the unchanged 17-table baseline plus the exact added idempotency table: 18 domain tables, 166 columns, 42 FKs and 50 tenant predicates. Test populated 0002→0003 as well as fresh upgrade; retry hash/reference/expiry/grants and SQL UTF-16 storage boundaries match the reviewed contract. |

#### Selenium Browser Test Acceptance

Use Selenium WebDriver with headless Chrome by default against the built React application, running
FastAPI service and separately seeded SQL Server test environment. Each case MUST start with its own
browser session, use accessible/stable selectors and observable-condition waits, and close the
session even on failure.

| Case | Requirements / scenarios | Action and required observation |
| --- | --- | --- |
| SB-01 — `test_dispatcher_registers_vehicle` | FR-001–004, FR-009–010; US1-AC1–2 | Sign in as A's creator, open Vehicles and register a fresh unit with valid details. Observe success, refresh the page and search for the unit. Exactly one result remains; open it and confirm every submitted detail. |
| SB-02 — read-only dispatcher | FR-001, FR-003, FR-010; US2-AC1–2 | Sign in as a read-only member and confirm their seeded truck is visible. There is no enabled registration action. Open the known registration address directly: access is denied, no usable form is exposed and refresh shows no new truck. Direct request bypass is independently asserted by IT-03. |
| SB-03 — `test_other_carrier_cannot_see_created_vehicle` | FR-002, FR-006; US3-AC1–3 | Independently seed an A-only truck. Sign in as B, find B's `TRK-001`, then search for A's unique unit and see the empty state. Open A's record address: see a non-disclosing not-found view and no A details. |
| SB-04 — validation and duplicate feedback | FR-004–005, FR-010; US1-AC3–4 | Submit with the unit missing using the keyboard; focus/error association identifies it and nothing is saved. Correct the form using A's existing unit; see the duplicate conflict. Change to a fresh unit, submit successfully and refresh to confirm exactly one new truck. Include BMP, supplementary and mixed exact-limit/one-unit-over unit/make/model values: visible error and no save on overflow, no silent truncation; corrected boundary values save and survive refresh unchanged. |
| SB-05 — access revoked during entry | FR-001, FR-003, FR-010; US2-AC3 | Open the form as A's creator, revoke create permission in controlled setup, then submit valid details. See access denial and no success; persisted fleet state is unchanged. |
| SB-06 — tenant switch and sign-out cleanup | FR-002, FR-011; US3-AC5 | View A's records, switch the authorized multi-carrier member to B, then refresh/back-navigate. Repeat by signing out of A and signing in as B's reader in the same browser. A's records, search results and prior save details never remain visible. |
| SB-07 — empty, loading and service failure | FR-010; edge cases | Exercise an empty own-carrier fleet, a delayed list/save and a controlled unavailable service. Show loading while pending, a genuine empty state only after a successful empty read, and a recoverable error on failure. Never show save success for a failed request. |

#### Required Execution Evidence

- Generate `make test-unit`, `make test-integration`, `make test-selenium` and aggregate
  `make test` with this first application slice. Required PR checks named `unit`, `integration`
  and `selenium` MUST invoke the same root commands and pass on the implementation commit.
- Follow DEV-008 suite locations, pytest/Vitest/React Testing Library runners, pinned dependencies,
  browser/driver pairing and equivalent VS Code tasks in the generation instructions.
- SQL Server checks MUST run on supported Linux x86-64. Integration/browser jobs MUST start
  isolated Compose environments, wait for readiness with bounded timeouts, apply application
  migrations, seed synthetic data and always clean up their own resources.
- Reports MUST contain suite/case counts, failures/skips, commit SHA, JUnit XML and CI links;
  browser failures include sanitized screenshots/diagnostics. Missing SQL Server/browser,
  setup failure, zero tests or skipped required cases MUST fail the check.
- Prove failure propagation with a deliberately failing scaffold assertion, restore it and
  record the subsequent passing run. Keep reference-database rehearsal separate from the
  migrated application database. No execution or deployment success is asserted by this spec.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** (AUTH-01–02): Every vehicle read and registration MUST require a verified identity,
  active carrier membership and the applicable current permission. A role label alone MUST NOT
  grant access. Authorization MUST be rechecked at submission and before returning retry results.
- **FR-002** (AUTH-02): Every truck MUST belong to one verified carrier. Server-side scope MUST
  govern lists, searches, direct reads and creation; browser-supplied carrier/role values MUST
  NOT grant access or override ownership.
- **FR-003** (AUTH-02): A member with vehicle read/create permissions MUST be able to register
  trucks in that carrier. A read-only member MUST retain authorized browsing but have no enabled
  registration action; direct navigation or submission MUST still be denied on the server.
- **FR-004** (FLT-01): Registration MUST capture unit number, make, model, model year and ownership
  type. Unit number MUST contain 1–30 UTF-16 code units after trimming outer whitespace; make and
  model MUST each contain 1–80 UTF-16 code units after the same trim. Valid supplementary Unicode
  characters consume two units and MUST be preserved. Malformed unpaired surrogates and values
  over capacity MUST be rejected, never truncated. Browser/API/search/storage MUST apply the
  same rule and fixed trim set in [the Unicode contract](contracts/README.md#unicode-and-length-contract).
  Model year MUST be an integer from 1900 to 2100 inclusive; ownership MUST be Owned, Leased or
  Contracted. Missing/invalid values MUST yield actionable field errors and no saved truck.
- **FR-005** (FLT-01): Unit numbers MUST be unique within the owning carrier, including concurrent
  submissions. Outer whitespace is ignored and letter-case variants count as the same unit.
  The same unit number MAY exist in another carrier. Duplicate attempts MUST leave the existing
  truck unchanged and explain the conflict only to an authorized caller.
- **FR-006** (AUTH-02): A truck belonging to another carrier MUST NOT appear in the caller's list,
  search, result counts or details. Direct access MUST disclose no more than an unknown record.
- **FR-007** (FLT-01): Registration MUST persist a complete truck or nothing. A failure before
  persistence completes MUST NOT leave orphan asset/vehicle records, success history or a saved
  retry receipt. The truck, success audit and completed retry receipt MUST commit together.
  A lost response after successful persistence follows FR-008.
  Concurrent duplicate attempts MUST produce exactly one complete registration.
- **FR-008** (spec.md §8): A registration submission MUST have a durable identity scoped to
  carrier, operation and submitting membership. An identical authorized retry MUST return the
  original 201 result (same identifier, normalized details, creation time and Location) without
  another truck, registration event or retry receipt, including after a service restart.
  Concurrent identical-key retries MUST resolve to that same result after commit. Reusing that
  identity with different valid normalized details MUST produce a 409 conflict with no mutation.
  Current authorization and resource ownership MUST be verified before replay. No automatic
  expiry or key reuse is introduced by this slice; finite retention requires explicit review.
- **FR-009** (FLT-01): Successful registration MUST retain the verified creator and creation time.
  Confirmation MUST follow persistence. On refresh, Vehicles MUST retrieve the saved truck;
  unit-number search and a readable record view MUST show its submitted identifying details.
- **FR-010** (spec.md §5): Vehicles and registration MUST provide labeled fields, keyboard access,
  visible focus and accessible validation; distinguish loading, empty, unavailable, forbidden,
  duplicate and successful states; preserve correctable input after validation/conflict errors.
- **FR-011** (AUTH-02): Switching carriers or signing out MUST clear previously scoped vehicle
  data and pending registration results. Responses from an earlier scope MUST NOT populate the
  current view, including after refresh or browser history navigation.
- **FR-012** (DEV-008): Executable unit, FastAPI integration against actual SQL Server and Selenium
  browser tests MUST ship with the application code for this feature. All cases and evidence
  requirements in Required Verification MUST be satisfied locally and in pull-request CI;
  a reference database rehearsal alone MUST NOT satisfy application acceptance.

### Key Entities *(include if feature involves data)*

- **Carrier (tenant)**: The organization owning a truck and defining its visibility and unit-number
  namespace.
- **Dispatcher membership**: A verified person's active relationship to a carrier and effective
  vehicle read/create permissions. Permission applies to that carrier, not globally.
- **Truck registration**: A stable truck identity, owning carrier, unit number, make, model, year,
  ownership type, creator and creation time. It is not a dispatch assignment or compliance claim.
- **Registration submission**: The durable identity and outcome of one member's registration
  attempt, allowing an authorized retry without duplicating a truck.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In every authorized-registration acceptance run, the dispatcher receives a save
  confirmation and finds exactly one matching truck with unchanged submitted details after
  refreshing Vehicles.
- **SC-002**: All read-only, invalid-session and revoked-access acceptance attempts create zero
  trucks; read-only dispatchers can still find their own carrier's seeded trucks.
- **SC-003**: All cross-carrier list, search, direct-address and session-switch acceptance cases
  disclose zero unauthorized truck records or identifying details while preserving access to
  each carrier's own `TRK-001`.
- **SC-004**: Repeated and concurrent registration scenarios leave exactly one truck per carrier
  and normalized unit number, with no partial registration; different carriers can each retain
  their own identically numbered truck.
- **SC-005**: The complete registration and validation-correction journey is operable using only
  a keyboard, with identifiable fields, visible focus and understandable success/error feedback.
  All defined accessibility acceptance cases pass.
- **SC-006**: Every required unit, service-integration and browser acceptance case has an executed
  passing result from the same feature revision before the feature is accepted; zero required
  cases are missing or skipped.

## Assumptions

- **Scope**: This slice delivers manual truck registration, vehicle list/unit-number search and
  read-only record detail. It excludes editing/deleting trucks, bulk imports, trailers, driver
  assignment, dispatch, maintenance, GPS, finance, documents and Copilot. Full FLT-01 remains
  broader; no later workflow is implicitly implemented.
- **Registration fields**: Required make/model/year/ownership and their limits align with the
  proposed [vehicle dictionary](../../docs/database/data-dictionary.md) and
  [constraints](../../docs/database/constraints-and-indexes.md). VIN, plates, odometer,
  registration/insurance metadata and optional vehicle attributes are deferred from this slice.
  This avoids inventing VIN/legal validation policy. No placeholder business values may fill
  missing required fields.
- **Unit-number convention**: Trim surrounding whitespace, retain the entered letter case for
  display and compare without letter-case distinction. Interior characters remain significant.
  This is an explicit registration/search default; planning MUST align storage uniqueness with it.
- **Identity and permissions**: Test membership setup is controlled and synthetic; an existing
  application authentication system is not assumed. The first slice MUST establish verified
  identity and internal permissions. The reference seed uses `fleet.vehicle.read` and
  `fleet.vehicle.create`; planning MUST reconcile these with architecture capability examples
  instead of assuming a dispatcher role grants creation. Clerk remains subject to ADR-004.
- **Foundations**: This is a planning kit, not a running application. Gate 0 must supply the
  runnable stack and all three test suites. On 2026-11-23 the user authorized the proposed G00
  17-table foundation plus the kit's existing integration.idempotency_keys design, solely for
  FR-008. The resulting 18-table set is dependency-closed; this is not approval of other G03 or
  integration tables, global foundation reclassification, or any executable migration.
  SQL Server driver/TLS, migration/runtime permissions and tenant isolation require actual
  validation before implementation is accepted.
- **Workflow**: This first registration flow is online; offline creation is excluded. Handling a
  lost response and retry remains required. Creating a record does not assign equipment or
  certify dispatch, safety or regulatory eligibility.
- **Delivery boundaries**: Detailed contracts, data model, migration/backout design and executable
  test file mappings belong in `$speckit-plan`. Application code, tests, CI execution, publishing
  and deployment are not performed by this specification command.
