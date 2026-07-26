# NetManager's Privacy Policy

**Effective Date:** July 25, 2026

**Last Updated:** July 25, 2026

**NetManager** is a free and open-source mobile network monitoring application built with privacy in mind. This policy explains how we handle your data.

## Controller Identity & Contact

* **Data Controller:** NetManager Open Source Project (DottoXD)
* **Contact & Inquiries:** You can open an issue on our [GitHub Repository](https://github.com/DottoXD/NetManager)`.

## Data Collection & Processing

We strictly follow data minimization principles:

* **Personal Data:** NetManager does **not** collect, track, store, or sell any personal data, user accounts, or behavioral analytics.
* **Local Data Storage:** All cellular metrics, event handoff logs, imported databases (`.ntm`, `.clf`), and recorded trip logs are processed and stored on your local device only.

## Opt-In Features

### Crash & Error Reporting

* **Default Status:** Disabled by default (Opt-In).
* **Data Processing:** If manually enabled in settings, anonymous crash logs and stack traces are collected using the open-source **Sentry Dart SDK** and sent to **Bugsink** (an EU-hosted, open-source crash reporting platform).
* **Anonymity & Retention:** Error logs cannot be linked to your identity. Anonymous reports are periodically cleaned up and never retained longer than **180 days**. You can revoke consent at any time by toggling error reporting off in settings.

### Update Checker

* **Default Status:** Disabled by default (Opt-In).
* **Data Processing:** If enabled in settings, the app queries the official [GitHub REST API](https://api.github.com/repos/DottoXD/NetManager/tags) to compare your current build commit hash against the latest tag release.
* **Network Logs:** Connecting to GitHub's API transmits your device's **IP address** to GitHub servers to process the request, subject to [GitHub's Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement). No personal telemetry or usage details are sent.

## External Services & International Data Transfers

To display map tiles, execute speed tests, or perform update checks, NetManager connects directly to third-party services:

* **OpenStreetMap (OSM):** Map rendering and tile loading ([Privacy Policy](https://wiki.osmfoundation.org/wiki/Privacy_Policy)).
* **LibreSpeed:** On-demand network speed testing.
* **GitHub, Inc.:** Opt-in software update checks.

### Network Logs & IP Address Transmission

When your device connects to these external services, your **IP address** is transmitted to the destination server to process the request.

### Cross-Border Transfers (EU to US)

When using features that connect to GitHub servers located in the United States, your IP address may be transferred internationally. GitHub, Inc. relies on recognized legal safeguards for cross-border transfers under GDPR, including participation in the **EU-U.S. Data Privacy Framework (DPF)** and Standard Contractual Clauses (SCCs).

### End-User Control

You have full control over where your app connects. Both OpenStreetMap tile servers and LibreSpeed backend URLs can be customized or pointed to self-hosted endpoints directly within the app settings.

## Your Data Rights

Under international standards (including the EU GDPR and US state privacy laws), you hold the following rights regarding your data in NetManager:

* **Right to Access & Export:** All app metrics and trip logs are held locally and can be exported at any time via built-in export tools.
* **Right to Erasure:** Clearing the app's storage or uninstalling NetManager removes all locally stored data immediately and permanently.
* **Right to Withdraw Consent:** You can opt in or out of error reporting and update checks at any time in the app settings.
* **Right to Lodge a Complaint:** You have the legal right to file a complaint with a supervisory authority if you believe your data protection rights have been infringed.

## Policy Administration & Updates

Whenever this privacy policy is updated:

1. The updated policy will be committed directly to this `PRIVACY.md` file in our GitHub repository.
2. Users will receive an in-app pop-up dialog following an update, providing an option to review the revised terms and accept or reject them.