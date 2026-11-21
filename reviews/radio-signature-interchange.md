# Radio Signature Interchange (OffGridPete/radio-signature-interchange)

**Repo:** https://github.com/OffGridPete/radio-signature-interchange
**Author:** Off Grid Pete LLC / OffGridPete
**License:** No license specified in this repository; public visibility is not a redistribution grant. The separately inspected Fieldwatch implementation is MIT; that does not license this specification repository.
**Reviewed:** 2026-11-21 (UTC)
**Revision:** `23549d07b66849b06d368d2d06e3d2498e10eaa6`; RSI-1 document revision 1.0.0, published 2026-11-15. Entire four-file tree inspected; PDF and Python document generator are the principal sources.
**Implementation cross-check:** Fieldwatch `a7d9e6a5d9883a6bfe986e59915ef706551ff930`, app version 1.2.1; targeted exchange, matcher, decode, storage, tests and catalog review, not a whole-app audit. Public latest release v1.2.1 dated 2026-11-20.
**Verification:** Static review; independent JSON parse/count of the published catalog. No source execution, builds, Android tests, hardware access, RF collection/transmission, deployment or live security probes.
**Stack:** UTF-8 JSON interchange; Python 3 + ReportLab document generator. Separate implementation: Android/Kotlin, kotlinx.serialization JSON 1.7.3.
**What it is:** A proposed interchange format for libraries of rules that label already-parsed BLE advertisements and Wi-Fi beacons, optionally decoding cleartext payload fields. It is not an RF fingerprinting model, IQ recording format, cryptographic signature scheme or radio receiver.

---

## Verdict

⚠️ **Interesting — a concrete interoperability proposal, not yet a dependable cross-application contract.** RSI-1 specifies useful matching details and honest limits on identification. A real public Fieldwatch implementation now exists beyond the proposal's future-tense release plan, but static inspection finds parser and persistence edge cases, while independent interoperability and detection accuracy remain unproved. Clarify licensing and close conformance gaps before adopting it as a durable exchange boundary.

## What It Is

The exchange unit is a catalog, not a captured transmission. Each signature contains a label and rules over fields a receiver already parsed: name/SSID, MAC prefix, advertised service UUID, manufacturer identifier/data or Wi-Fi vendor information elements. Every signature is evaluated independently; application-specific label suppression is outside the specification. Connecting, transmitting, GATT reads, decryption, distance inference and person identification are explicitly out of scope. [S1 §§1–2, 9–16, 24]

The README describes a proposal for comment, not an adopted Bluetooth SIG, IEEE or IETF standard. It names Fieldwatch through 1.1.44 as the older baseline and says 1.2.0 will conform. That is a dated author plan, not the current release state: the separate public repository now has 1.2.1, RSI export/parser code and catalog 114. A displayed support badge remains the application's own claim, not certification. [S1 §§5, 22–23; S2; I1–I3]

## Stack

| Layer | Technology and scope |
|---|---|
| Specification | 17-page PDF, generated from Python/ReportLab prose and tables |
| Wire format | One UTF-8 JSON object, optional BOM on input, recommended .rsi extension |
| Reference implementation inspected | Fieldwatch Android/Kotlin exchange, compiled matcher and payload decoder |
| Persistence inspected | Fieldwatch JSON config file and stock-catalog overlay |
| Machine validation | No JSON Schema, standalone validator, matcher library or automated tests in the four-file specification repository |
| Authentication | No cryptographic publisher identity or signed-catalog protocol specified |

## Key Features

### Explicit schema, defaults and units

The root contains a required `fleets` array, format marker, schema `formatVersion` and separate publisher-local `catalogVersion`. Empty fleets is valid in the specification. Signature id/name/rules are required; matchAny defaults true. Rules default enabled, null radio, empty text/payload prefix and companyId 0. The company identifier is numeric, 16-bit Bluetooth assigned-number semantics; MAC addresses are 48-bit, OUI prefixes commonly 24-bit. UUID equivalence preserves custom 128-bit identifiers rather than collapsing them to a short Bluetooth UUID. [S1 §§6, 9, 13–15]

There are eleven baseline rule kinds. NAME_GLOB is whole-name matching with only * and ? as wildcards; regex punctuation is literal. Manufacturer-data companyId 0 is a wildcard, whereas MANUFACTURER_ID 0 means company zero specifically. SERVICE_DATA without a UUID has substring/reversed-byte-pair behavior, not simply prefix matching. Known other-radio rules are ignored in ALL mode, but unsupported radio/rule tokens fail required tests closed. These details matter to a compatible implementation. [S1 §§10–17]

Optional decode maps use zero-based byte offsets, explicit widths, little-endian by default, integer/float/bit/text/address types, conditional gates and raw × scale + offsetAdd, with optional modulo before scale. Units are free-form display labels, not a normalized physical-unit ontology. No RF sample rate, center-frequency, RSSI calibration or location coordinate system is defined. The optional group profile uses a seconds-based peer window (default 60), default group count 3 and a last-16-address-bits distance threshold of 64. [S1 §§18–20]

### Compatibility is deliberate, but partial results need caution

Baseline clients reject unknown enum names and higher schema versions; conforming parsers retain useful known portions and report newer formats. For version-1 unknown required rules, ALL mode fails closed, while ANY mode can still match a known alternative. Higher schema versions are different: the document recommends reading understood members even when semantics have changed, provided partial results are not presented as complete. An application must surface that warning, not silently treat a partially understood future catalog as authoritative. [S1 §§5, 7, 21–23]

The publisher/id identity rule helps migration: equal ids merge when publishers match or either is absent. It is not a transitive equivalence relation: publisher A is compatible with an absent publisher, which is compatible with B, although A and B differ. The spec does not fully settle a three-way ambiguous merge. Fieldwatch's indexOfSame uses explicit preference rules, including its own publisher when incoming publisher is absent; another reader could choose differently. Publisher tokens are names, not authenticated ownership. [S1 §8; I2]

### Implementation exists, but the badge is not proof

Fieldwatch implements raw preservation of unknown rules, unknown-class display fallback, per-field decode rejection, radio-scoped matching and publisher-aware export. Its checked-in tests cover unsupported radios, mixed-radio ALL matching, UUID behavior and publisher migration. Its Android CI workflow runs unit tests before building an APK. These are verified code/test definitions, not tests run in this review. [I2–I6]

Concrete static findings:

- **Empty catalogs disagree:** RSI §6 explicitly permits an empty fleets array; SignatureExchange.parsePack throws when it is empty. The same parser does not explicitly enforce formatVersion >= 1, and format defaults to fieldwatch-signatures when omitted. Strict format/schema validation is therefore not demonstrated. [S1 §6; I2]
- **Publisher-only manual import can be lost:** merge fills a missing publisher but counts that branch as skipped, with added=0 and merged=0. ConfigStore.importFleets returns without writing when both counters are zero. The unit test checks the returned merged list, not persistence through ConfigStore. Thus a publisher-only manual import does not persist that migration on this inspected path; stock overlay uses a different path. [I2, I5, I6]
- **Do not substitute app labels for raw conformance results:** SignatureEngine.match calls product-specific suppression functions; fleetHits also has an id-specific iBeacon exception. The specification permits post-match display policy, but the app-level result is not an independent core-matcher oracle. [S1 §§2, 10; I3]

## Architecture and Trust Boundaries

The specification repository implements document production only: a ReportLab flow assembles prose, tables and examples into the committed PDF. There is no bundled capture or recognition runtime. Its dependency is named in the README, without a lockfile or reproducible PDF-build test. The separate Fieldwatch chain is bounded file input → JSON deserialization/custom serializers → catalog merge/store → compiled rules → optional payload decode → application-specific display decisions. [S2–S3; I2–I5]

### Validation and untrusted input

The proposal is detailed on matching but incomplete as an adversarial-input contract. It does not set catalog/rule/string/depth limits, fully define malformed/odd hex handling, duplicate JSON members, oversized offsets, numeric overflow or truncated decode payload behavior. Section 20 refers unknown endian/gate operations back to §5.3, which explicitly spells out source/type handling but not those two cases. More machine-readable negative vectors would reduce implementation drift. [S1 §§5–6, 12, 20; Appendix A]

Fieldwatch improves the boundary with an 8 MiB signature import/download cap, timeout-bounded stock retrieval, tolerant unknown-field serializers and bounds checks plus exception containment around individual decoded field formatting. Still, glob compilation translates * into regex .*, with no per-pattern complexity budget in that function, and decode gates recurse through and. Large adversarial patterns/nesting merit offline fuzzing; this review did not demonstrate a denial of service. [I3–I4]

CatalogRemote fetches a fixed public HTTPS raw-GitHub stock URL with redirects enabled. Neither RSI nor the inspected fetch path establishes a content-signature trust chain. A publisher string or increasing catalog number cannot authenticate a library. Importing a malicious rule library can change labels and decoded interpretations without executing embedded code. Treat catalogs as untrusted policy/data, render labels as text, bound work and review provenance. No server auth/CORS deployment applies to the specification itself. [I4; S1 §§6–8]

### Privacy and accuracy

The author explicitly prohibits treating a match alone as proof of a person, medical/safety event or particular physical object. Names and OUIs can be shared or spoofed, and no ground-truth dataset, precision/recall study, spoof-resistance evaluation or cross-device field trial is included. Appendix A is a useful semantic conformance table, not evidence that model labels are accurate in the wild. [S1 §24, Appendix A]

The statement that the file contains no location/owner/credential describes intended fields, not an enforced privacy guarantee. Free-text notes, exact MAC rules and payload decoders can carry identifiers; exporting a custom library deserves inspection. This is concrete in the implementation: SignatureEngine.suggestFleet starts with the full MAC as a rule and writes that MAC into notes. RSI observations also have addresses and group recency. Although position is not required by RSI, a receiving application's logs may correlate observations with locations. This review did not audit Fieldwatch's broader logging/location/export system. [S1 §§9, 18, 24; I3]

### Persistence and recovery

RSI requires storage-capable consumers to preserve application metadata, local mute/extra rules and bookmarks during overlays, and not collapse distinct known publishers. It does not specify transactions, backups, crash recovery or a universal update transport. Ignoring unknown object members is not lossless preservation of every future field. [S1 §§5, 8, 19, 23]

Fieldwatch overlays retain local enabled and extra rules and gate stock updates by catalogVersion. ConfigStore writes a temporary config then renames before updating memory; however rename failure falls back to overwriting the live file, with no fsync/backup protocol shown. Load/parse failure reseeds and writes defaults over the config. That is useful normal-path discipline but not demonstrated crash-safe recovery; retain exports before major catalog migrations. The publisher-only manual-import issue above is a separate state-loss edge. [I2, I5]

## Maturity, Evidence and Verification

Unauthenticated public GitHub metadata on 2026-11-21 reported 68 stars, 5 forks and 0 open issues for the specification, last push 2026-11-15T14:31:01Z. Its release and tag lists were empty; 1.0.0 is a document revision, not a GitHub release. Popularity and lack of open issues do not establish conformance. The source tree contains exactly README, badge SVG, PDF and its Python generator. [M1]

Independent local checks parsed Fieldwatch's public dist/fieldwatch-signatures.rsi using the Python standard-library JSON parser: radio-signatures, formatVersion 1, catalogVersion 114, 328 signatures and 7,118 rules; all 328 signature publisher values are fieldwatch, with zero duplicate publisher/id pairs. This verifies catalog structure/counts only, not rule correctness or recognition accuracy. No private observations were used.

The PDF SHA-256 is `b0f7668a5195fa2205d1534ff22fb0ac8b1d8aa0253c72f3badc547d488c9298`. PDF text was extracted and read alongside generator source; the PDF was not rebuilt. Fieldwatch tests/CI definitions were inspected but not executed, and no CI success claim is made. No independent second implementation or interoperability round-trip was verified. No APK was installed or run.

## Comparison

| Need | Better fit / tradeoff |
|---|---|
| Share model-label rules over parsed BLE/Wi-Fi observations | RSI is directly aimed at this; presently vendor-led and needs conformance/licensing clarification |
| Share recorded IQ/RF samples plus capture metadata | [SigMF](https://github.com/sigmf/SigMF) addresses recording portability, not interchangeable RSI recognition rules |
| Receive/decode many sub-GHz sensor protocols | [rtl_433](https://github.com/merbanan/rtl_433) is a receiver/decoder ecosystem, not an RSI reader verified here; RSI's 433 MHz profile remains undefined |
| Use the existing Android implementation | [Fieldwatch](https://github.com/OffGridPete/Fieldwatch) already has RSI paths and public tests, but its app policies/privacy/storage are broader than the interchange contract |

The SigMF and rtl_433 comparisons use their public README scope statements, not a comparative benchmark or claim of compatibility. They operate at different layers rather than serving as drop-in alternatives.

## Self-Hosting Notes

There is no RSI service to deploy. Evaluate the document and exchange boundary offline before integrating it into an existing receiver. Do not assume a new radio token is supported merely because a library names it. A useful next milestone is a licensed, machine-readable schema plus conformance fixtures for empty/invalid files, three-way publisher merges, future-version warnings, malformed decode fields and round-trip recovery, tested by two independent implementations. The document generator is optional tooling, not required to consume .rsi.

## Evidence Links

- **S1:** [RSI-1 PDF at reviewed commit](https://github.com/OffGridPete/radio-signature-interchange/blob/23549d07b66849b06d368d2d06e3d2498e10eaa6/docs/papers/Radio_Signature_Interchange.pdf); section/page citations above refer to this 17-page document.
- **S2:** [README/status and badge disclaimer](https://github.com/OffGridPete/radio-signature-interchange/blob/23549d07b66849b06d368d2d06e3d2498e10eaa6/README.md).
- **S3:** [Complete specification generator](https://github.com/OffGridPete/radio-signature-interchange/blob/23549d07b66849b06d368d2d06e3d2498e10eaa6/docs/papers/build_signature_spec.py).
- **I1:** [Fieldwatch release v1.2.1](https://github.com/OffGridPete/Fieldwatch/releases/tag/v1.2.1), [revision tree](https://github.com/OffGridPete/Fieldwatch/tree/a7d9e6a5d9883a6bfe986e59915ef706551ff930), [MIT license](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/LICENSE).
- **I2:** [SignatureExchange.kt](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/SignatureExchange.kt).
- **I3:** [SignatureEngine.kt](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/SignatureEngine.kt), [Models.kt](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/Models.kt).
- **I4:** [SignatureRuleJson.kt](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/SignatureRuleJson.kt), [SignatureFieldDecoder.kt](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/domain/SignatureFieldDecoder.kt), [ImportFiles.kt](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/ImportFiles.kt), [CatalogRemote.kt](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/CatalogRemote.kt).
- **I5:** [ConfigStore.kt](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/main/java/app/fieldwatch/data/ConfigStore.kt).
- **I6:** [SignatureExchangeTest.kt](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/app/src/test/java/app/fieldwatch/domain/SignatureExchangeTest.kt), [Android CI](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/.github/workflows/android.yml), [catalog inspected](https://github.com/OffGridPete/Fieldwatch/blob/a7d9e6a5d9883a6bfe986e59915ef706551ff930/dist/fieldwatch-signatures.rsi).
- **M1:** [Public repository metadata](https://api.github.com/repos/OffGridPete/radio-signature-interchange), [releases](https://api.github.com/repos/OffGridPete/radio-signature-interchange/releases), [tags](https://api.github.com/repos/OffGridPete/radio-signature-interchange/tags). Mutable metadata retrieved 2026-11-21.

---

**Attribution:** Radio Signature Interchange, Off Grid Pete LLC / OffGridPete; no license specified. Fieldwatch cross-check: Off Grid Pete LLC, MIT. Original analysis only; no source-code or specification redistribution.
