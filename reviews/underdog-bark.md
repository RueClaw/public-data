# Underdog Bark 3.0

**Source:** https://underdog.ai/bark (HTML canonical verified)
**Author / publisher:** Underdog; model publisher Conway Research / ConwayResearch. No individual page byline.
**Date:** No publication/update date found on the product page. Standard/Clean repositories last updated October 15, 2026; comparison baselines dated October 9.
**Reviewed / retrieved:** 2026-10-21 UTC.
**Content hash:** Complete public HTML, 86,150 bytes; SHA-256: f60bb68f2acab4f0cb9cf5b235f07bb8025d844a11462edf4874a159eafae17e.
**Revision:** Standard model/code: 85db2ad18ab41e534a222ee253c29191d77ed919. Clean card: 6d34ed8639b2b9a33e764acf06748519bbb950cf.
**Verification:** Public-page acquisition and static inspection of model cards, inventories, standard Python loaders/runtime, NOTICE and Core ML license. No model downloads, source execution, app signup, inference, traffic capture or benchmark reproduction.
**Topic:** Compact English automatic speech recognition (ASR), local dictation and meeting transcription.
**License:** Model declared CC-BY-4.0; proprietary Underdog app has separate personal-use terms.

---

## Verdict

⚠️ **Interesting: credible compact-ASR implementation, not an independently proven accuracy or privacy win.** Worth evaluating for English dictation on local hardware, especially when download size matters. Public loaders make the compression story inspectable, but 163 MB is not a working-memory budget, the headline score is not the default Clean model's score, and the app has account, telemetry and permission boundaries beyond its speech model.

## Summary

This is **Underdog / Conway Research's speech-to-text Bark**, not Suno's generative Bark text-to-audio model, a child-monitoring service, or voice cloning. It is a post-trained/compressed derivative of NVIDIA Parakeet TDT 0.6B v3 via Moondream parakeet-ultra. Intended uses are dictation and meeting transcription; the model itself does not supply meeting understanding or a general assistant. [1,2]

The page distinguishes Standard (reported 163 MB / 4.94% mean word error rate), Plus (180 MB / 4.76%), Pro (1.254 GB / 4.29%) and Clean (180 MB / 5.83%). **Clean is the Underdog default** and removes disfluencies. Standard/Plus are selectable in Speak; Pro is described as Hugging Face only. All scores are publisher measurements, not this review's measurements. [1–3]

The models are more than a waitlist: public Hugging Face APIs expose ungated repositories, weight-file inventories and readable loaders. This confirms publication metadata/code, not successful weight retrieval or inference. The Mac app is a separate availability question: the homepage says invite-only beta on Apple silicon; Windows is beta, an iOS 18+ app needs no invite, and Linux/Android are forthcoming. The standard card's standalone iOS Core ML path explicitly says **not yet tested on iPhone/iPad**. App availability does not validate every runtime. [2–4]

The visible contribution is distribution efficiency: entropy-coded low-bit weights with Transformers/PyTorch and MLX bridges. The proposition is plausible, but deployment decisions need target-device memory, real recordings, transcript fidelity and pinned software—not just a download-size chart.

## Key Claims and Evidence

| Claim | Assessment |
|---|---|
| Beats Parakeet at 15× smaller | Vendor AMI result: 7.82% versus 9.42%. Seven-set averages both round to 4.94%; the card's 4.937 versus 4.941 is only 0.004 percentage points. No uncertainty interval establishes a meaningful overall win. Bark is worse on several individual sets, including LibriSpeech and Earnings-22. |
| Beats Whisper at 57× smaller | Vendor compares 163 MB with 9,261 MB of Whisper weights, and 4.94% with 6.04% WER. Not a comparison with every quantized Whisper build or equal-memory runtime; not 57× less RAM or 57× faster. |
| 595× real-time | Page reports five minutes in roughly half a second on M5 Max in Underdog. Card separately reports 41× on M2 with stock mlx-audio. Hardware/runtime differ; cold/warm conditions and end-to-end costs are insufficiently specified. Neither result reproduced. |
| Clean writes what you meant | Clean reports 4.08% WER against cleaned DisfluencySpeech references and 13.85% against verbatim; Standard reports 16.53% / 3.15%. Different objectives, not guaranteed intent preservation. Clean's card lists older Bark 2.0 at 3.83% on cleaned references: 3.0 is not uniformly better. |
| Nothing is sent anywhere | Plausible for local audio inference, not the complete product. The privacy policy discloses account records, optional usage counts, ordinary Mac daily check-ins and website ad measurement. No network audit performed. |

### Reproducibility and methodology

The card names seven full English test sets: LibriSpeech clean/other, AMI, Earnings-22, GigaSpeech, SPGISpeech and VoxPopuli, including leaderboard-cleaned variants. Average means a mean across sets, not pooled corpus WER. Standard inference adds 0.25 seconds of leading silence; Clean uses none. These details help reproduction. [2,3]

However, the card explicitly says Bark results were **reported separately, not leaderboard entries**, with competing rows copied as of October 9. A linked benchmark and inference code are not independent validation. The inspected inventories contain no complete training recipe, evaluation predictions, confidence intervals or turnkey benchmark runner. Training-data overlap, accent/demographic coverage, noise robustness and long-recording behavior remain unverified. The leaderboard README links its evaluation paper, not an independent reproduction of Bark. [9]

## Implementation and Architecture

Static scope: standard README, bark_loader.py, bark_mlx.py, runtime/transcribe_bark.py, Windows requirements, NOTICE, coreml/LICENSE and public file inventory; Clean card/inventory. Plus/Pro figures are assessed as claims in those documents, not separate implementation audits.

- **Packed format:** bark_loader.py reads a length-prefixed JSON header and tensor blobs. Encoder matrices use FP16 row levels and entropy-coded symbols; other matrices use integer symbols/row scales; small tensors use FP16. Selected side blobs use LZMA. This is concrete evidence of compact distribution, not proof of numerical equivalence.
- **PyTorch:** weights are reconstructed into floating point and loaded into ParakeetForTDT, with FP32 default execution. NVIDIA generation configuration and processor are fetched via from_pretrained without a pinned upstream revision. Local audio inference still needs prepared dependencies for air-gapped operation.
- **MLX:** names/layouts are transformed and cached in safetensors before mlx-audio recognition. CLI defaults to FP16; optional affine 4/8-bit re-quantization changes the representation and cannot simply inherit every published score. Cache reuse checks file existence rather than the source model hash.
- **Memory:** MLX loader comments estimate about 6 GB for unpacking. The card reports a ten-minute file peaking around 15 GB on a 16 GB M2 and recommends segmentation. Clean's card says 1.25 GB of unpacked weights. File size is not a RAM/VRAM requirement.
- **Runtime wrapper:** Windows entry point checks paths, empty/nonfinite audio and accelerator availability, then dynamically imports the chosen model-folder loader. Core ML package inventories and fixed-window guidance exist, but their code and numerical parity were not audited.

No CI/test suite was visible in the inspected model-repository inventory. This is a model distribution with scripts, not proof of a production-qualified SDK. No tests were run.

## Privacy and Security Boundaries

The inspected recognition functions process local arrays; no audio-upload call was found there. Dependencies, native app binaries and the complete stack were not audited. The app's native Swift/MLX implementation and pinned size/SHA-256 checks are **vendor claims**, not verified by the public Python path. [2]

The loader reads whole files, trusts header dimensions and decompresses blobs without explicit resource limits. Treat model files as trusted inputs, not arbitrary uploads. No built-in pinned checksum was visible in the standalone Python loaders. The wrapper executes the selected loader as code. Pin revisions, verify downloaded bytes and use isolated execution. These are trust-boundary findings, not demonstrated exploits.

The [privacy policy][5], effective October 14, says the Mac service stores account identifiers and membership. Daily feature/model/device usage counts can be disabled, but daily check-ins still run in the ordinary configuration. Counts and account details remain until account deletion; server logs have an unspecified “limited period.” Voluntary crash reports and member posts can leave the device. Website Meta pixel/conversion measurement includes hashed identifiers and regional consent/opt-out rules. Thus “100% private” does not mean zero metadata collection. The policy separately claims no Underdog account/telemetry for iOS. These are policy disclosures, not packet-level verification.

The [security page][6] claims local encryption, Keychain protection, signed/notarized releases, CASA Level 1 completion and Google approval. Named penetration tests remain “under way”; completed findings are not posted there, and the validation letter is available on request. These statements do not establish immunity to prompt injection, local compromise or transcript leakage. The homepage's Naval mode is a claimed stronger network configuration, not tested here.

Dictation requires Accessibility authority. Recording consent is the user's responsibility. Custom dictation servers, MCP and settings sync change the security boundary. Avoid connecting unrelated mail/browser/payment capabilities merely to evaluate ASR. For legal, medical or evidentiary transcripts, use verbatim output and verify names, numbers and negations against consensually retained audio. Clean's intentional omissions make it unsuitable for unverified exact quotations. Local inference does not eliminate endpoint, backup or consent risks. [7]

## Pricing, Availability and Licenses

The actual offer is **free**, not a metered ASR API. The pricing page initially shows a satirical $1,999/month “Good Boy” plan, then explicitly overturns it with “100% free”; terms confirm no current charge. No paid transcription cap, seat fee or minute limit is disclosed in the checked pages. Hardware, electricity and integration still cost money; invites/membership restrict the Mac app. The stated business model earns a share from user-authorized purchases through the assistant. “Free forever” appears on pricing, while terms reserve changes with notice. No enrollment or purchase attempted. [4,7,8]

Model card and NOTICE declare **CC-BY-4.0**, naming NVIDIA/Moondream and Conway Research post-training/compression. The Core ML directory includes the full license. Commercial reuse is permitted with attribution, license linkage and change notices; preserve notices and avoid implied endorsement. This does not license the proprietary Underdog app: its terms grant a nontransferable personal license, restrict build redistribution and tie use to membership. No separate software-specific license was found for top-level loader scripts in the inspected inventory; do not silently relabel them MIT/Apache. No source components are extracted here.

## Strengths

- A real inspectable compressed-model loader, not just marketing or a closed endpoint.
- Explicit distinctions between verbatim and cleanup targets, including unfavorable measurements.
- Practical memory/platform caveats in model cards and a clear upstream attribution chain.
- Local inference can reduce audio exposure when the complete application and dependencies are configured appropriately.

## Alternatives and Gaps

| Option | Prefer it when | Tradeoff |
|---|---|---|
| NVIDIA Parakeet TDT 0.6B v3 | Multilingual ASR and direct upstream integration matter | Upstream card supports 25 European languages; Bark is English-only. Compare deployment formats, not only repository download bytes. |
| Whisper / whisper.cpp | Multilingual support and established quantized local deployments matter | Bark's vendor English table favors Bark, but is not an equal-runtime comparison with quantized whisper.cpp. |
| Bark Plus / Pro | Same-family verbatim quality matters more than smallest download | Better reported WER, larger files; Pro not in the app's Speak selector on this page. |
| Bark Clean | Readable personal dictation matters more than exact wording | Intentional omissions; Standard/Plus scores are not Clean scores. |

The product page says no word timings, no individual speaker names, and no Bark 3.0 support for its custom words list. These matter for subtitle workflows, speaker-attributed meeting archives and specialist terminology. Separate alignment/diarization tooling may be necessary; do not assume it exists in Bark. [1]

## Adoption Gate

Evaluate on a bounded, consented corpus before replacing an existing pipeline. Pin source/weights, record versions and cache provenance, prepare offline dependencies, and measure peak memory plus cold/warm latency on actual hardware. Test short/long recordings, proper nouns, numbers, negations and cleanup omissions separately. Validate storage/retention and outbound connections before sensitive use. This review establishes public availability and implementation plausibility—not reproduced performance, a security certification or production readiness.

## Sources

1. [Product page][1] — full public HTML and canonical inspected.
2. [Standard model/card/code at reviewed revision][2].
3. [Clean card at reviewed revision][3].
4. [Homepage][4] — platform availability and business model.
5. [Privacy policy][5].
6. [Security statements][6].
7. [Terms][7] — effective September 1, 2026.
8. [Pricing][8].
9. [Open ASR Leaderboard README][9] — methodology reference, not Bark reproduction.
10. [NVIDIA upstream card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3) and [whisper.cpp](https://github.com/ggml-org/whisper.cpp) — alternatives, not full comparative audits.

[1]: https://underdog.ai/bark
[2]: https://huggingface.co/ConwayResearch/Underdog-Bark-3.0/tree/85db2ad18ab41e534a222ee253c29191d77ed919
[3]: https://huggingface.co/ConwayResearch/Underdog-Bark-3.0-Clean/blob/6d34ed8639b2b9a33e764acf06748519bbb950cf/README.md
[4]: https://underdog.ai/
[5]: https://underdog.ai/privacy
[6]: https://underdog.ai/security
[7]: https://underdog.ai/terms
[8]: https://underdog.ai/pricing
[9]: https://huggingface.co/spaces/hf-audio/open_asr_leaderboard/blob/main/README.md

---

**Attribution:** Underdog / Conway Research; upstream NVIDIA and Moondream. Model license: CC-BY-4.0. Performance and app-security claims are publisher claims unless explicitly identified as static findings.
