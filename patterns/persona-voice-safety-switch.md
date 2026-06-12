# Persona Voice Safety Switch

**Source:** [Lagunaswift/RockyVoice](https://github.com/Lagunaswift/RockyVoice)
**License:** MIT for repo code; do not reuse named fictional characters or voice samples without rights clearance
**Reviewed:** 2026-06-11

## Pattern

When building a strong persona or voice layer for an AI assistant, make the persona persistent but subordinate to correctness, safety, and user control.

The reusable structure:

- persona applies to the full conversation once activated;
- user has explicit stop phrases that immediately return to normal mode;
- exact facts, code, commands, numbers, and warnings are never stylized incorrectly;
- dangerous or irreversible actions force a plain-language safety override;
- long or dense details can be moved into files while the persona gives a short spoken summary;
- optional voice output is implemented as a side channel, not by weakening the assistant's reasoning.

## Why It Works

Persona skills are fun until style starts hiding risk. The safety switch preserves the emotional/interaction layer while keeping hard technical content exact.

For voice assistants, this matters even more. Spoken output is transient, easy to mishear, and poorly suited to dense commands or irreversible operations. A good persona voice system must know when to stop performing and speak plainly.

## Implementation Notes

- Define the activation and deactivation phrases in the skill itself.
- Add an explicit "speak plainly" rule for danger warnings, irreversible actions, command ordering, code, numbers, and legal/security-sensitive language.
- Keep the persona layer out of code blocks and machine-readable artifacts.
- If using a TTS hook, strip Markdown tables, code blocks, URLs, and inline code before speech.
- Cap spoken text length so runaway responses do not create excessive audio generation.
- Keep local TTS hooks local unless the server has authentication, origin controls, and request limits.

## Good Fit

This pattern is useful for companion modes, playful local assistants, accessibility experiments, and voice-first prototypes where the personality is part of the experience.

## Caveats

Do not reuse copyrighted characters, distinctive voices, or training samples unless you have the necessary rights. For production work, use an original persona and licensed or owned voice assets.

---

**Attribution:** Lagunaswift/RockyVoice, MIT License.
