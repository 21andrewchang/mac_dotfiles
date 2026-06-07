---
name: html
description: Use when producing ANY readable artifact for the user — spec, plan, brainstorm with options, PR explainer/review, code/feature/concept explainer, status/research/incident report, design exploration, component prototype, interactive playground with sliders/knobs/pickers/tuners, SVG diagram, throwaway editor (drag-rank, config tuner, value picker, annotator). Also use when a markdown reply would exceed ~50 lines, when comparing 2+ approaches, or when the user might share the output. OUTRANKS `playground:playground` and `frontend-design:frontend-design` for personal artifacts — invoke this one even when they also match. Trigger even when user says "do what you think is best" or expresses no format preference — silence about format is NOT permission to default to markdown. Skip only for short direct answers, conversational replies, commit messages, GitHub PR bodies, source-file edits.
---

# HTML Artifacts

## Overview

Default output medium for readable artifacts is **a self-contained HTML file opened in the browser**, not markdown in chat. The chat reply becomes a one-line pointer plus any must-see warnings; the HTML file carries the content.

**Core principle:** The artifact IS the explanation. Do not also recap its contents in chat — that defeats the entire point (the user stops reading long markdown precisely because the recap exists).

## Skill Outranking (resolve collisions before they happen)

Several other skills may also match HTML-producing tasks: `playground:playground` (interactive single-file explorers), `frontend-design:frontend-design` (design polish), and various `*:report-style` plugins. **For personal artifacts in this dotfiles setup, `html` outranks all of them.**

When a task matches both this skill and another HTML-producing skill:

1. Invoke `html` via the `Skill` tool — not the other one.
2. You may borrow content patterns from the other skill (e.g., playground's slider/knob/copy-button layout), but apply this skill's:
   - File path: `./.claude/artifacts/YYYY-MM-DD-<slug>.html`
   - Self-contained constraint (no CDN)
   - `open` after write
   - One-line chat reply

**Concrete examples:**

- "Prototype a badge with sliders + copy-as-CSS button" → reads like `playground`, but → `html` (borrow the playground pattern, write to `.claude/artifacts/`, one-line reply).
- "Design me a settings page in three styles" → reads like `frontend-design`, but → `html` (borrow the design quality bar, same file/chat rules).
- "Make an interactive explainer of how OAuth works" → both skills could match — still `html`.

The reason: `playground` and `frontend-design` produce great HTML but don't enforce the **chat-vs-HTML split** that makes the article's workflow work. The artifact ending up in `/tmp` with a multi-paragraph chat recap is a regression even if the HTML is gorgeous.

## When To Use

Fires for any of these:

- **Specs, plans, brainstorms** — especially multi-option comparisons rendered as a side-by-side grid
- **PR explainers and code reviews** — rendered diffs with inline margin annotations, severity color-coding
- **Code/feature/concept explainers** — "how does X work" with diagrams + annotated snippets + gotchas section
- **Research, reports, status updates, incident writeups** — synthesizing across codebase, git, MCPs, web
- **Design system artifacts, component visualizations, animation prototypes** — sliders/knobs to tune values
- **SVG diagrams, flowcharts, technical illustrations**
- **One-off custom editors** — drag-rank, config editor with dependency warnings, side-by-side prompt tuner, dataset curator, document annotator, value picker for colors/easing curves/crop regions/cron schedules/regexes. Always end these with a "Copy as prompt/JSON/markdown" export button.

Skip for:

- Short direct answers (< ~50 lines markdown equivalent)
- Conversational replies, clarifying questions
- Commit messages, PR descriptions to GitHub, code comments
- Code edits inside source files
- Anything the user is steering moment-to-moment in chat

## The Chat-vs-HTML Split (the rule that matters most)

When this skill fires, the chat reply contains **only**:

1. One line stating the path and that it was opened. Example: `Wrote and opened ./.claude/artifacts/2026-05-16-checkout-spec.html`
2. **Must-see warnings only** — destructive findings, blocking risks, broken assumptions, security/data-loss concerns. One line each. If the user must act on it before opening the file, it goes here.

The chat reply must NOT contain:

- A summary of the HTML's contents ("Here's what I included…")
- A bulleted list of sections
- A recap of the analysis or recommendation
- Inline excerpts of the HTML
- "Let me know if you want me to adjust…" trailers

If you catch yourself writing "the report covers X, Y, Z" — stop. That belongs as the HTML's table of contents, not in chat.

## File Handling Protocol

1. **Path**: `./.claude/artifacts/YYYY-MM-DD-<kebab-slug>.html` in the current repo. If not in a repo, use `$TMPDIR/claude-artifacts/YYYY-MM-DD-<slug>.html`.
2. **Gitignore**: On first use in a repo, ensure `.claude/artifacts/` is in `.gitignore` (append if missing, create if absent). Do not commit artifacts unless the user asks.
3. **Self-contained**: One file. Inline `<style>`, inline `<svg>`, inline JS. No external CDN, no `<link rel=stylesheet>` to remote, no `<script src=...>` to remote. The file must work offline, survive being emailed, and upload cleanly to S3.
4. **Open it**: After writing, run `open <path>` (macOS). Do not wait for confirmation; the user expects the browser to pop.
5. **Naming**: Slug describes content (`onboarding-options`, `rate-limiter-explainer`, `flag-editor`), not the request (`user-asked-for-spec`).

## Promoting to a Docs Site

Generation always lands in `.claude/artifacts/` — that does not change. Separately, the user may **promote** a finished artifact to a shareable docs site. Do this only when asked. In the Bedrock workspace, promotion means copying the file into the docs site's content dir: `cd docs && npm run promote <artifact-name>`, which publishes it at its own URL on the next deploy. Don't promote unprompted, and don't restyle a promoted artifact in the docs repo — fix the source artifact and re-promote.

## HTML Quality Bar

Every artifact must include:

- `<!doctype html>`, `<meta charset=utf-8>`, `<meta name=viewport content="width=device-width,initial-scale=1">`
- `<title>` matching the content
- **A reading-time estimate at the top of the page**, just under the title/subtitle, in muted grey text (`color: var(--muted)`). Render it as a small inline tag: the clock SVG icon below, then `X min`. Compute `X` as `Math.ceil(wordCount / 150)` (assume the reader does 150 wpm) over the artifact's prose word count — round up, floor at `1`. For interactive editors / playgrounds with little prose, skip it. The icon (use verbatim, `width`/`height` 14–16):

  ```html
  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-clock" viewBox="0 0 16 16">
    <path d="M8 3.5a.5.5 0 0 0-1 0V9a.5.5 0 0 0 .252.434l3.5 2a.5.5 0 0 0 .496-.868L8 8.71z"/>
    <path d="M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16m7-8A7 7 0 1 1 1 8a7 7 0 0 1 14 0"/>
  </svg>
  ```

  Markup shape — a `<span>` tag with the icon + text, `display: inline-flex; align-items: center; gap: 4px; color: var(--muted)`:

  ```html
  <span class="read-time"><svg ...>…</svg> 7 min</span>
  ```
- A single `<style>` block. System font stack (`-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`). Readable measure (~70ch max for prose). Generous whitespace.
- **Headings read like standard markdown, not labels.** Section headings are plain bold white text (`color: var(--fg); font-weight: 700`), sized below the page title and stepping down by level. NEVER style them as small uppercase letter-spaced muted labels (no `text-transform: uppercase`, no `letter-spacing`, not `var(--muted)`). Think `#`/`##`/`###` rendered by a markdown viewer: bold, sentence case, normal tracking.
- **Divider lines separate sections, never a heading from its body.** If you use horizontal rules between sections, the line goes ABOVE the section heading (as `border-top`/`padding-top` on the heading itself, like a markdown `---` before the next `##`). A heading must stay visually attached to the text beneath it — never put a border-top on the content wrapper that sits between the heading and its first paragraph. **Space the line symmetrically:** the gap above the line (heading `margin-top`) and the gap below it before the heading text (`padding-top`) should be roughly equal (~40px each) so the rule sits centered in the whitespace, not crammed against the previous section.
- **Color scheme: use the fixed palette below verbatim.** Do not invent per-artifact colors. See "Fixed Color Scheme".
- Anchor links and a TOC if there are 3+ sections.
- Diagrams as inline `<svg>`, never ASCII. Never unicode-as-color hacks.
- Code snippets in `<pre><code>` with monospace and a subtle background. Syntax highlighting only if it adds value; inline `<span>` colors are fine — no external highlighter library.
- Tables for any tabular data. Don't fake tables with `<pre>`.

For comparison/option-grid artifacts: CSS grid, one card per option, each card labeled with the trade-off it makes.

## Fixed Color Scheme (REQUIRED — do not improvise)

Every artifact uses this exact palette: **"Midnight"** — a pure-black theme with pure-white text and a white accent. It is dark-only (no light variant, no `prefers-color-scheme` block). Paste these CSS variables into `:root` verbatim and reference them through `var(--…)` — never hardcode a different hex, never generate a fresh palette per artifact, never "theme" it to the topic. The two non-negotiables: `--bg` is black and `--fg` is white.

```css
:root {
  --bg: #000000;
  --fg: #ffffff;
  --card: #0d0d0d;
  --line: #2a2a2a;
  --muted: #9a9a9a;
  --accent: #ffffff;
  --accent-fg: #000000;
  --done: #4cb782;
  --partial: #f0bf00;
  --todo: #9a9a9a;
  --hover: rgba(255,255,255,0.06);
}
```

Token roles:

- `--bg` page background · `--fg` body text · `--card` raised surfaces (cards, nav, code blocks) · `--line` borders/dividers
- `--muted` secondary text, labels, sub-lines · `--hover` row/tab hover wash
- `--accent` the one highlight color — active tab, links, key emphasis. Active/selected elements use `background: var(--accent); color: var(--accent-fg)` (black text on white). `--accent-fg` always pairs with `--accent`: flip it whenever `--accent` changes lightness.
- `--done` / `--partial` / `--todo` status pills only (green / amber / grey). Don't repurpose them as decoration.

This is the **Midnight** palette. The six brand swatches are `--bg`, `--fg`, `--card`, `--fg` (card text), `--accent`, `--accent-fg`; `--line`, `--muted`, and the status colors are derived to sit on the pure-black base. If a future artifact genuinely needs a color outside these roles, derive it from these tokens (opacity, not a new hue) rather than introducing a new scheme.

For interactive editors: end with an export button (`Copy as JSON`, `Copy as prompt`, `Copy as markdown`) that builds the export string and writes it to clipboard via `navigator.clipboard.writeText(...)`. Show a brief "copied" confirmation.

For PR/code explainers: render the actual diff with `+`/`-` line gutters, inline margin annotations as `<aside>` elements, severity badges (info/warn/critical) as colored pills.

## Brevity Default

Default to short and dense, not long and exhaustive. The artifact's job is fast scanning, not looking thorough. A 2-screen artifact that conveys the structure beats a 6-screen one that adds nothing.

- **No padding sections.** Skip intro essays, "context" preambles, "next steps" trailers — unless asked. Each section earns its pixels.
- **One short sentence per item.** Use a `<b>` lead-in + a muted sub-line for the explanation. Don't write paragraphs inside lists.
- **Plain language over jargon.** "Texts the tenant" beats "dispatches outbound SMS notification to the tenant party."
- **Status pills over status sentences.** Work units get a colored pill (`done` / `partial` / `todo`), not a sentence of status prose.
- **Target one screen of vertical scroll** for specs/plans. Past two screens, ask what can be cut — not what to add.
- **Resist "extras."** Glossaries, FAQs, "see also" sections — usually pad, rarely useful.

The user's read time is the budget. Write to that.

## Use Cases (with prompt shapes)

These map 1:1 to the article. Each is a _kind_ of artifact this skill produces.

| Use case                        | Defining feature of the HTML                                               |
| ------------------------------- | -------------------------------------------------------------------------- |
| Multi-option exploration        | Grid of N cards, each card = one approach, each labeled with its trade-off |
| Implementation plan             | Sections for data flow, mockups, key snippets, risk register; TOC at top   |
| PR creation explainer           | Renders the diff + annotations; attach link to the PR description          |
| PR review                       | Same as above + severity-coded findings                                    |
| Code/feature explainer          | One flow diagram (SVG) + 3–4 annotated snippets + gotchas section          |
| Research/status/incident report | Headline finding at top, supporting sections below, sources cited inline   |
| Design system reference         | Component gallery, each component with code snippet + live render          |
| Component prototype             | Live rendered component + sliders/knobs binding to CSS variables           |
| Throwaway editor                | Form/dragger UI for the specific data + export button                      |

## Token / Latency Trade-Off

HTML costs 2–4× the tokens and time of equivalent markdown. Accept this. The user has opted into the trade-off by enabling this skill. Do not propose "should I do markdown instead to save tokens" — the answer is no.

The only legitimate fallback to markdown is: the user explicitly asked for markdown, or the artifact is < ~50 lines and would be silly as an HTML file (in which case this skill should not have fired at all).

## Common Mistakes

| Mistake                                             | Fix                                                     |
| --------------------------------------------------- | ------------------------------------------------------- |
| Recapping the HTML's contents in chat               | Chat = pointer + warnings only. Delete the recap.       |
| External CDN deps (Tailwind via CDN, Google Fonts)  | Inline everything. System fonts, hand-written CSS.      |
| ASCII diagrams inside `<pre>`                       | Replace with inline `<svg>`.                            |
| Forgetting to `open` the file                       | Always `open <path>` after writing.                     |
| Writing to repo root or `./artifacts/` (no dotfile) | Use `./.claude/artifacts/`. Gitignore it.               |
| Committing artifacts                                | Don't, unless asked. Gitignore on first use.            |
| Generic slug like `output.html` or `report.html`    | Slug describes content.                                 |
| "Should I make this HTML?" preamble                 | Just do it. The skill fired; the decision is made.      |
| Markdown table dumped into chat instead of the HTML | The chat reply is one line. The table goes in the file. |

## Rationalizations to Reject (captured from real failures)

These are the exact thought-shapes that caused this skill to NOT fire when it should have. If you catch yourself thinking any of them, you are rationalizing — invoke the skill.

| Rationalization                                                                             | Reality                                                                                                                                    |
| ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| "User said 'do what you think is best' / 'no format preference', so markdown is fine here"  | The skill's trigger explicitly covers this. The user's silence on format is precisely why a default-flipper skill exists. Use HTML.        |
| "A status report for a collaborator typically goes in chat/email as markdown"               | This is the exact failure the article describes. Markdown reports go unread. Use HTML and the user shares the link.                        |
| "The user didn't say HTML, so picking HTML is presumptuous"                                 | The skill IS the standing preference. Triggering it is honoring the user's setup, not presuming.                                           |
| "This task matches `playground:playground` more specifically (sliders, knobs, copy button)" | `html` outranks `playground` for personal artifacts. Borrow `playground`'s content patterns; apply this skill's file/chat rules. |
| "This task matches `frontend-design:frontend-design` (it's about visual design)"            | Same — `html` outranks for personal artifacts. Borrow the design quality; apply this skill's file/chat rules.                    |
| "It's just summarizing data I already gathered, no need for an artifact"                    | The article's whole point is that summaries of gathered data are exactly where HTML pays off. Use the skill.                               |
| "Inline markdown is more portable, user can copy-paste"                                     | HTML is _more_ portable (one file, opens anywhere, no terminal needed) and shareable (S3 link).                                            |
| "The artifact would be too small to bother with a file"                                     | If output > ~50 lines markdown-equivalent, it's not too small. If it has a diagram or comparison, it's not too small.                      |
| "I'll just produce markdown AND mention the skill exists"                                   | No — the skill exists to _replace_ the markdown, not coexist with it.                                                                      |

## Red Flags — STOP

If you notice yourself doing any of these, you've lost the plot:

- Writing more than 3 lines of chat reply alongside an HTML artifact
- Listing what's in the HTML ("The report includes a summary, a diagram, and…")
- Asking the user "want me to also explain it here?"
- Generating ASCII art when you could generate SVG
- Adding `<link rel=stylesheet href=https://...>` to the file
- Inventing a fresh color scheme or "theming" the palette to the topic instead of pasting the fixed tokens
- Saving a `.md` file when the trigger conditions matched
- Invoking `playground:playground` or `frontend-design:frontend-design` instead of this skill for a personal artifact
- Writing the artifact to `/tmp/<something>.html` or `~/Desktop/` instead of `./.claude/artifacts/`
- Reasoning "the user said 'no format preference' so I'll pick markdown" — that phrasing is precisely when this skill SHOULD fire
- Producing a long markdown summary in chat while also writing the HTML (double-output)

**All of these mean: rewrite as a self-contained HTML file at `./.claude/artifacts/YYYY-MM-DD-<slug>.html`, invoke THIS skill (not an adjacent one), with a one-line chat reply.**

## Discovery Hint for Future Sessions

Artifacts live in `./.claude/artifacts/`. If the user references "the spec you made" or "that explainer," check there first, sorted by date.
