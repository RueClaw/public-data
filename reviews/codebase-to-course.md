# Codebase to Course (zarazhangrui/codebase-to-course)

**Repo:** https://github.com/zarazhangrui/codebase-to-course
**License:** No license specified. Treat as educational/reference material only; do not reuse code, templates, or assets without permission.
**Reviewed:** 2026-07-05
**Stack:** Markdown Agent Skill, static HTML/CSS/JavaScript template assets, Bash assembler
**What it is:** A Claude Code skill that turns a source repository into a self-contained interactive HTML course for non-technical learners.

---

## Verdict

📚 **Study as a course-design pattern, not a deployable dependency.** The teaching model is strong: product-first tracing, exact-code translation blocks, visual density rules, scenario quizzes, glossary tooltips, module briefs, and prebuilt static assets. The blockers are straightforward: no license, no tests or CI, no packaged validator, and generated HTML must be treated carefully when source code or repo content is untrusted.

---

## What It Is

Codebase to Course is an Agent Skill for generating a browser-openable course from a codebase. It is aimed at "vibe coders": people who use AI coding tools to build software but want enough technical fluency to steer agents, debug failures, and understand architecture.

The skill tells the agent to inspect the target repository, identify the main actors and user journeys, design 4-6 modules, copy fixed CSS/JavaScript/build assets, write per-module HTML, and assemble the final `index.html` with a tiny shell script. The result is a static course with scroll navigation, progress tracking, quizzes, data-flow animations, group-chat component conversations, glossary tooltips, and side-by-side code-to-English explanations.

This is not a general app or library. It is a prompt-and-template workflow for a host coding agent.

## Stack

| Layer | Tech |
|-------|------|
| Skill runtime | Claude Code Agent Skill Markdown |
| Course output | Static HTML directory assembled into `index.html` |
| Styling | Prebuilt `styles.css`, warm notebook-style design tokens |
| Interactivity | Prebuilt browser JavaScript in `main.js` |
| Assembly | `build.sh` concatenates base, module files, and footer |
| References | Content philosophy, gotchas, design system, interactive elements, module brief template |
| Tests/CI | None visible in reviewed checkout |

## Key Features

### Product-First Curriculum

The skill explicitly tells the agent to start from what the learner already knows: the app's behavior. The first module should trace a concrete user action into the code, then later modules introduce actors, data flow, external dependencies, clever tricks, failure modes, and the full architecture.

That is a good inversion of traditional programming education. It teaches code as machinery behind a known product, not as abstract syntax.

### Code-to-English Translation Blocks

Every module must include exact code snippets from the source project and a plain-English line-by-line explanation. The instruction to use original code exactly is important: learners can open the real file and see the same code they studied.

### Visual and Interactive Defaults

The reference files push hard against textbook output:

- max 2-3 sentences per text block
- every screen should be at least 50% visual
- convert lists into cards and flows into diagrams
- include quizzes per module
- include glossary tooltips for technical terms
- include at least one group-chat animation and one data-flow animation per course

This is opinionated in a useful way. Most generated tutorials fail by becoming prose dumps; this skill gives the agent concrete anti-prose constraints.

### Complex-Codebase Parallelization

For complex repositories, the skill adds a planning checkpoint: write one module brief per course module with teaching arc, code snippets, interactive elements, references to read, and transitions. Subagents can then write modules without re-reading the full codebase.

That module-brief pattern is probably the most reusable design decision in the repo.

### Fixed Asset Boundary

The skill tells the agent never to regenerate `styles.css` or `main.js`. It should copy the static assets and write only module HTML. That reduces drift and keeps later modules from bloating with duplicated CSS/JS.

## Architecture

The generated course has a simple directory contract:

- `styles.css`
- `main.js`
- `_base.html`
- `_footer.html`
- `build.sh`
- optional `briefs/`
- `modules/*.html`
- generated `index.html`

`_base.html` holds the page shell and Google Fonts link. `build.sh` concatenates the shell, module fragments, and footer. `main.js` scans the page for class names and `data-*` attributes to initialize quizzes, drag-and-drop, chat animations, data-flow animations, architecture diagrams, bug challenges, and layer toggles.

This is easy to inspect and easy to run locally. It is also fragile in the usual generated-HTML ways: malformed module HTML, bad `data-steps` JSON, unescaped code content, or accidental inline script can break or change behavior.

## Comparison

| Aspect | Codebase to Course | visual-explainer | walkthrough | drawio-skill |
|--------|--------------------|------------------|-------------|--------------|
| Primary job | Teach a codebase as an interactive course | Turn complex output into visual HTML artifacts | Convert agent traces into evidence-backed walkthroughs | Generate editable diagrams |
| Output | Static single-page course | Static HTML artifact | Static HTML walkthrough | `.drawio` source and exports |
| Best idea | Learner-centered module briefs and code-to-English blocks | Representation routing and artifact renderer boundary | Provider-normalized event narrative | Editable source before image export |
| License posture | No license | MIT | No license | MIT |
| Main caveat | Promptware, no license/tests/validator | Prompt-dependent, no tests in reviewed checkout | No license, young pipeline | Host tool dependencies |

Codebase to Course is more educational than `visual-explainer` and more codebase-facing than `walkthrough`. It is less operationally mature than `drawio-skill` because it has no validators or tests.

## Self-Hosting Notes

There is no service to host. Use is local: copy the skill into a compatible agent skill directory, point it at a codebase, and open the generated HTML file.

Security notes:

- Treat generated HTML as active content, not inert documentation.
- Escape code snippets and repo-derived strings before inserting them into HTML attributes or `innerHTML`-driven feedback fields.
- Be careful with untrusted repositories. A course generator that copies arbitrary code/comments into HTML can accidentally create script injection.
- The README says the course works offline, but `_base.html` loads Google Fonts from a CDN. It still functions without those fonts, but it is not fully offline by default.
- Because no license is specified, do not redistribute the template assets or generated derivative templates without permission.

## Verification

- Shallow cloned `https://github.com/zarazhangrui/codebase-to-course.git` on 2026-07-05.
- Current commit: `ff8837ecf8e9f6ce9874ffa42e42633394a52a00`.
- GitHub metadata: 5,137 stars, 524 forks, 6 open issues, latest push 2026-03-30.
- GitHub reports no license.
- Reviewed README, SKILL, content philosophy, gotchas, design system, interactive-elements reference, base/footer/build assets, and main JavaScript engine.
- Ran `bash -n references/build.sh` and `node --check references/main.js`; both passed.
- No package manifest, test suite, CI workflow, release, or tag was present in the reviewed checkout.

---

**Attribution:** zarazhangrui/codebase-to-course, no license specified.
