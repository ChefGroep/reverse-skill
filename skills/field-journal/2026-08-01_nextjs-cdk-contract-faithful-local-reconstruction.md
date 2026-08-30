# Contract-Faithful Local Reconstruction of the Next.js CDK Order Center

> Date: 2026-08-01
>
> Scenario: Web / API / JS reverse engineering and local reconstruction
>
> De-identification: target domain and ports use standard placeholders; credentials, CDK, order identifiers, and private paths retain only their category — original values are not recorded

## Scenario Classification

Web / API / JS reverse engineering

## Target Overview

Built a four-source evidence chain — "entry snapshot, static bundle, runtime pages, public OpenAPI" — for a Next.js single-page order center, and reconstructed a runnable local project with the same information architecture, same browser request shape, same response projection, and same order-state semantics, without connecting to real payment, worker, or checking services.

## Scope Summary (de-identified)

- auth_basis: user supplied the entry point and requested analysis plus an identical local implementation
- network_profile: read-only review of the public entry point and public OpenAPI; build and acceptance both pointed at loopback addresses
- asset_types: [web, frontend_js, public_openapi, screenshot, local_source]
- fixture_profile: synthetic CDK, synthetic credentials, synthetic payment links, deterministic worker/check/payment adapters

## Roles

- lead_role: lead
- specialists: [cre, doc]

## Complete Execution Chain

1. Froze the entry HTML, response headers, public OpenAPI, and SHA-256; reused the existing static package and browser forensics.
2. Extracted routes, request body fields, headers, Storage keys, polling periods, conditional rendering, and the state vocabulary from the main page bundle.
3. Modeled the page's internal legacy API and the public v1 API separately, establishing their own serializers to avoid field drift from a shared DTO.
4. Computed desktop geometry, mobile breakpoints, card hierarchy, control states, and the copy baseline from runtime full-page screenshots, DOM, and CSS.
5. Established the canonical domain model, CDK ledger, and deterministic state machine; external capabilities were handled through the `CHECK_FN`, `PAYMENT_PROVIDER`, `WORKER_GATEWAY` fixture adapters.
6. Immediately reduced credentials and payment links to digests, types, and safety hints at request time; the persistence model has no original-value slots.
7. Ran contract tests over single, batch, detail, cancel, resubmit, pagination, dual authentication, and the OpenAPI docs.
8. Verified visuals with desktop and mobile browser screenshots; formed delivery evidence with a production build, API smoke tests, secret scanning, and re-verification from an extracted archive.

## Evidence Chain Summary (de-identified)

| E-id | source_type | reusable command pattern | linked finding |
|------|-------------|----------------|----------|
| E-001 | network/file | `curl -D headers -o page https://{target_domain}/<entry>; shasum -a 256 page` | framework entry and timestamp baseline |
| E-002 | frontend_js/openapi | `rg 'sessionStorage|/api/|productType|customerToken' {formatted_chunk}`; `jq '{info,paths,securitySchemes}' openapi.json` | legacy requests, states, browser storage, and the v1 contract |
| E-003 | runtime_visual/local_qa | `chromium --headless ...; screenshot + DOMRect`; `npm test && npm run build && BASE_URL=... npm run smoke` | desktop/mobile geometry, conditional rendering, and the local contract loop |

## Finding / Path Summary

- top_finding: the page's internal legacy API and the public v1 API share business semantics, but their request fields, authentication entry points, and response projections differ; reconstruction requires "one domain model, two boundary serializers".
- path_type: callflow
- path_one_liner: form input -> page field mapping -> legacy Route Handler -> canonical service -> fixture adapters/ledger -> legacy serializer -> polling render.

## Pitfall Records

| Problem | Cause | Solution | Time Spent |
|------|------|---------|------|
| Building the interface only by route name still left page fields blank | the response fields of legacy and v1 are not the same DTO | reverse the serializers from the bundle's property read points, and run contract tests on both boundaries separately | ~45 min |
| The page's initial form and its bound form were mixed together | multiple cards, hints, buttons, and lists are conditionally rendered | first freeze the unbound baseline, then build the interaction matrix by CDK/order state | ~30 min |
| The batch interface needed to express partial success and ledger consistency at the same time | promoting a single-item error into a whole-batch exception loses the original page's per-item result semantics | parse item by item first, then produce created/duplicate/failed in order within a single store mutation, validate the ledger at the end, and atomically persist | ~35 min |
| Ambiguity between the docs' required fields and the properties names | OpenAPI and the page's internal call surface evolved independently | keep the canonical fields while identifying compatible aliases at the boundary; report the adjudication rationale in a separate column | ~15 min |
| Visuals looked close but vertical error kept accumulating | small deviations in card padding, line-height, and gap stack up | use full page height, main column width, and key DOMRects as constraints, regressing screenshots section by section | ~40 min |
| Fixture hint copy broke the identical first screen | implementation notes leaked straight into the product UI | the UI keeps the forensic baseline and fixture notes go in the README; inputs still use deterministic examples | ~15 min |

## Toolchain Findings

- The static bundle's property read points are better for recovering response DTOs than the interface paths themselves.
- Layering legacy/v1 serializers lets page compatibility and public API stability hold simultaneously.
- `fullPage` screenshots need to combine viewport width, total page height, and DOMRects; plain pixel similarity gets amplified by font anti-aliasing.
- Batch orders should retain per-item created/duplicate/failed; dedup, capacity deduction, and ledger validation belong in the same mutation, ending with a single atomic file replacement.
- Secret scanning should cover source code, the runtime store, test logs, and the final archive's extraction directory, not just the Git working tree.

## Key Code/Commands

```bash
# Static call surface and state fields
rg -n 'customerToken|productType|upiExpiresAt|customerResubmitCount|sessionStorage' {formatted_chunk}

# Public API structure
jq '{openapi,info,paths:(.paths|keys),security:.components.securitySchemes}' openapi.json

# Local quality gates
npm run lint
npm test
npx tsc --noEmit
npm run build
BASE_URL=http://127.0.0.1:{port} npm run smoke
```

## Improvement Suggestions for This Package

1. `js-reverse` gains a "legacy UI API and public API dual serializer" checklist.
2. The report template gains a "visual baseline geometry table" and an "initial/bound/order-state matrix".
3. The QA template gains batch partial success and atomic persistence, dual-auth OR, OpenAPI schema/actual response consistency, and delivered-package extraction scanning.

## Reusable Patterns/Script Fragments

1. **Four-source cross-check**: the entry snapshot pins the version, the static bundle recovers the call surface, runtime recovers conditional rendering, and OpenAPI recovers the public contract.
2. **One core, two projections**: the canonical domain keeps state and ledger unified, while the legacy/public serializers keep boundary fidelity.
3. **Initial state first, then the state matrix**: lock the unbound first screen first, then verify bound, created, in-progress, completed, cancelled, resubmitted.
4. **Request-time reduction**: raw input entering the service is immediately converted into SHA-256, type, and mask; logs and the store only receive the reduced results.
5. **Delivered-package second re-verification**: extract the archive to a new directory, then reinstall, test, and build, avoiding leftover working-directory residue masking problems.

## Evolution Actions

- [ ] Updated the routing matrix
- [ ] Updated tool-index
- [ ] Updated bootstrap-manifest
- [ ] Updated the sub-skill docs
- [x] Added pitfalls records
- [ ] No updates needed

## Environment Info

- OS: macOS
- Tool versions: Node.js 24, Next.js 16.2.12 App Router, React, TypeScript 5.9.3, Chrome/Playwright
- Target platform/version: Next.js App Router / React / OpenAPI 3.1

## Final Acceptance Records

- ESLint, TypeScript 5.9.3, Next.js 16.2.12 production build: passed.
- Node tests: 8/8 passed.
- HTTP smoke: 15 contract groups passed.
- Playwright: 11 state/viewport screenshots and 10 assertion groups passed; browser console and page errors both empty.
- The 1440 px initial page measured 1440×1294, identical to the baseline; RGB MAE 2.301148, share of pixels within the per-channel threshold 0.945085.

## De-identification Review

- [x] Target domain replaced with `{target_domain}`
- [x] Original CDK, order numbers, tokens, cookies, JWTs, and payment links not written
- [x] Real IPs, ports, and local private paths not written
- [x] Run commands use `{port}` and placeholders
- [x] Delivered experience retains only methods, structures, and verification patterns

---
<!-- [Community contribution] After finishing, ask the user whether to PR to the main repository. -->