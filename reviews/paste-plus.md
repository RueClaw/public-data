# Paste-Plus (Techno-gen/Paste-Plus)

*Review #274 | Source: https://github.com/Techno-gen/Paste-Plus | License: MIT | Author: TechnoGen | Reviewed: 2026-03-27 | Stars: 22*

## Rating: 🔥🔥🔥

---

## What It Is

A Python CLI that types text by emulating keystrokes — simulating a human typing rather than doing a direct paste. Takes input from clipboard, file, or stdin; outputs keystroke sequences via pyautogui. The use case is bypassing copy-paste detection in LMS/exam platforms, code editors that disable paste, or any web app that watches for paste events vs. keystroke events.

Fresh repo (created 2026-03-24). Small, focused, clean Python.

---

## What It Does

**The humanization engine is the interesting part.** Five layers of noise:

1. **Typos** — QWERTY adjacency map (full keyboard graph hardcoded). When a typo fires: type the adjacent wrong key, brief pause, backspace, type correct key. The adjacency map is accurate and covers the full keyboard including numbers and punctuation.

2. **Post-hoc corrections** — plans typo "seeds" before typing begins. Plants wrong characters at random positions, continues typing everything else correctly, then navigates back after the fact to fix them. This simulates the human behavior of not noticing a typo immediately and catching it later.

3. **Retype events** — after a space/newline, occasionally types the next N characters (3-12 by default), deletes them all, then retypes correctly. Simulates "starting a word, changing my mind, retyping."

4. **Pauses** — random inter-word pauses (0.4–2.5s by default) at configurable frequency.

5. **WPM variance** — Gaussian-distributed WPM (default: 80 ± 15 WPM). Per-keystroke delay calculated from sampled WPM, with a hard floor of 10ms.

**Default config:**
- 80 WPM ± 15 variance
- 4% typo rate
- 2% retype rate (3-12 chars)
- 8% pause frequency per word
- 15% of planted typos are post-hoc corrections (noticed later)
- F9 trigger key

**Architecture is clean.** `Humanizer` class generates probabilistic events. `TypingSession` orchestrates them. `PosthocPlan` pre-computes which characters get the "correct later" treatment. `KeyboardBackend` protocol with `PyautoguiKeyboard` (real) and `DryRunKeyboard` (logging) implementations. The backend abstraction makes testing straightforward.

**Dry-run mode** shows every action that would be taken (TYPE 'h', PRESS backspace, SLEEP 0.23s, etc.) without touching the keyboard — good for debugging/tuning before live use.

**Windows only** in practice. pyautogui works cross-platform but the UAC note, the Windows-check in `_check_windows()`, and the .bat installer all signal Windows-first. The clipboard watch mode isn't in the open-source version (referenced in README but not in the code).

---

## The Code

It's genuinely well-written for a 3-day-old 22-star repo. Clean dataclasses for event types (`TypoEvent`, `RetypeEvent`, `PauseEvent`). Protocol-typed keyboard backend. Proper error handling in CLI. Config validation. The QWERTY adjacency map is the kind of detail that shows someone actually thought about what realistic human errors look like.

The post-hoc correction navigation is clever: calculates cursor offset from end-of-text, moves left N times to position before the wrong char, backspaces, types correct char. Works without knowing cursor position because it tracks offset from end.

One limitation: the `posthoc_correction_rate` applies to "fraction of all characters that get a planted typo" (line in `_plan`), but then it caps at `posthoc_max_corrections` total. The interaction between these two parameters isn't obvious from the config docs.

---

## Honest Assessment

This is a cheating tool with a disclaimer. The README says "not designed for plagiarism" in the same breath as describing how it bypasses LMS copy-paste detection. The "Omegle use case" energy from Deep-Live-Cam is present here too — the tool does exactly what it's described as not being for.

That said: the underlying technique is legitimately interesting. Human input simulation with QWERTY-aware typo generation, post-hoc correction planning, and WPM variance is a real subproblem that comes up in testing, accessibility tools, automation, and robotic process automation (RPA). The `DryRunKeyboard` backend pattern is reusable anywhere you want a dry-run/simulation mode for an action pipeline.

**What's worth keeping:**
- The full QWERTY adjacency map (hardcoded, accurate, reusable)
- The `KeyboardBackend` Protocol pattern for testable input simulation
- The post-hoc correction approach (plant errors early, navigate back later) as a pattern for any system that needs to simulate "catching mistakes mid-stream"
- The `DryRunKeyboard` logging backend pattern

MIT license, freely portable.
