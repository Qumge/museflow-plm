# BOM version comparison with your Agent

[English](capability.en.md) | [简体中文](capability.zh-CN.md)

Compare two BOM CSV/XLSX versions: added/deleted parts, quantity and specification changes, duplicate keys, with source file/sheet/row references.

Use the [Qumge task guide](https://qumge.com/en/docs/industrial) for current availability, input mappings, private uploads, billing authority and authenticated result downloads. No installation of this project is needed. This repository's full management workflows remain available for teams who need persistent business records and collaboration.

1. Ask your Agent to search Qumge for `compare BOM versions`. Read the matching live contract and price; stop if no matching operation exists.
2. Start with the synthetic CSV files in [examples/industrial](../examples/industrial). These examples contain no customer data.
3. Upload each file to `POST https://qumge.com/v1/industrial/files` using the calling buyer's Qumge key. Preserve identifiers as text and use explicit mappings; examples use ASCII field names while real files may use Chinese headers.
4. After spending authorization, call `compare_bom` on `museflow-bom-comparison` with the returned file IDs. Use a stable idempotency key and poll the platform job ID.
5. Download the private Excel/JSON reports using the same buyer key or buyer's logged-in browser. Trace every issue to the source row.

Limits: CSV UTF-8/XLSX, 512 KiB per file, 2,000 data rows, 32 columns; choose a sheet for multi-sheet XLSX. Export formulas to values and store dates as ISO text. Files and reports expire after 24 hours. Qumge processes these operations without sending file contents to a model. Uploading is an explicit action; the self-hosted application never automatically uploads business data.

Map part/quantity and optional parent/specification/unit/description in both versions. Duplicate keys are flagged rather than guessed. The sample has one added, one removed and one changed part, plus one duplicate-key issue. This does not inspect CAD geometry or approve changes.

Hosted Cap availability/pricing are separate from this MIT project. Synthetic examples and connection checks do not prove real paid delivery.
