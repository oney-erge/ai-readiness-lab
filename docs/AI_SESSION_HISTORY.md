# AI Assistant Session History

> Archived from the former root `CLAUDE.md` on 2026-07-29. This file preserves
> implementation history but is not an active instruction source. Current shared
> instructions live in `AGENTS.md`, and Claude Code imports them through the root
> `CLAUDE.md`.

> **IMPORTANT — Session log rule:** At the end of every AI turn, update the
> "Session Log" section below with: what was done, gaps or bugs found, what
> remains in the current phase, and what the next step is. Most-recent entry
> goes at the top. Be specific — a future agent or developer should be able to
> pick up cold from this log.

---

## Session Log (most recent first)

### 2026-06-12 · Session 16 — Report polish, boot splash, architecture diagram

**Done (completed the final polish pass — everything in the "next step" from Session 15):**
- **PDF cover page:** dark navy background, blue accent bars top/bottom, large company name, date,
  readiness score badge (only when a `PilotPlan` is present), sample-data notice in amber. Looks
  like a board document rather than a plain text dump.
- **§-numbered sections throughout both PDF and Markdown:** §1 Executive Summary, §2 AI Opportunity
  Map (§2.1…§2.N per card), §3 Selected Pilot, §4 Readiness Scorecard, §5 Technical Leader
  Questions, §6 Strategy Q&A, §7 Sources & Confidence. Section numbers auto-increment so the PDF
  and Markdown stay in sync regardless of which sections are present.
- **Liberation Sans TTF bundled at `backend/app/fonts/`** (Apache/SIL OFL, free): fpdf2 loads it
  for every PDF, so em-dashes (`—`), curly quotes (`""`), bullets (`•`), arrows (`→`), and
  ellipses (`…`) render natively without the previous latin-1 replacement hack. PyInstaller's
  `collect_data_files("app")` already bundles `app/fonts/` — no spec change needed.
- **Dimension bar chart in the scorecard section** of the PDF: colour-coded bars (green/amber/red
  by band) for all 8 pilot-readiness dimensions. Mirrors the web UI's `ReadinessScorecardView`.
- **Generation date header** added to both Markdown and PDF ("Generated June 2026").
- **Boot splash screen** in `desktop/launcher.py`: pywebview is opened with a dark branded HTML
  page (animated loading dots) before the server is healthy; `_navigate()` callback switches to
  the real URL the moment `wait_until_healthy()` returns. Eliminates the blank-window flash.
- **`docs/ARCHITECTURE.md` rewritten** with four Mermaid diagrams covering the complete shipped
  system: (1) full technical pipeline from intake through all 8 backend packages to export,
  (2) user journey all 7 screens, (3) streaming SSE sequence with the full event contract,
  (4) desktop packaging flow (build → PyInstaller bundle → runtime splash → navigate).
- **Tests:** 132 backend (5 report tests updated for new section numbering), 22 frontend — all
  passing. Ruff, ESLint, tsc, Vite build clean. Merged to `main` at `8bcf052`.

**Gaps / bugs found:** None — this was a pure polish/completeness pass.

**What remains:** The product is functionally complete. Remaining nice-to-haves (all lower
impact than the work completed):
- App icon (`.icns` / `.ico`) — requires image tooling not available in this sandbox; add via
  `desktop/icon.png` + PyInstaller `icon=` option on a local machine.
- Code signing / notarization — macOS Gatekeeper / Windows SmartScreen will warn on unsigned
  binaries; address when a developer certificate is available.
- Expand the peer classifier's curated dict for companies outside oil&gas/CRM/fintech/cloud.

**Next step:** product is shippable. Ship a `v1.0.0` tag to trigger the GitHub Actions release
workflow (`.github/workflows/release.yml`) which builds Windows/macOS/Linux distributables.

---

### 2026-06-11 · Session 15 — Visual brief polish + readiness gauge

**Done (closed the UI seam — the brief body was still plain CSS while everything below it was Tailwind):**
- **`ReadinessGauge`** (new): a circular SVG gauge (ring fills to the score, coloured by band
  green/amber/red, centre label `NN/100`). Used in `ReadinessScorecardView` (replaces the plain
  number) and on the brief.
- **`Brief` restyled to Tailwind** — header + sample chip, a narrative card (the four §4.4
  sections), a 2-col opportunity grid, evidence/Q&A/report below. On mount it fetches the saved
  pilot (`GET /projects/{id}/pilot`) and, when present, shows a **readiness banner** at the top
  (gauge + opportunity name + recommendation). `PilotDrillDown` gained an `onPlanned` callback so
  the banner updates the moment a plan is built.
- **`OpportunityCardView` restyled to Tailwind** — card surface, coloured value/feasibility/risk
  chips, time-to-pilot pill, "Plan this pilot" CTA. (Kept the "Value: high" text the tests assert.)
- **Client:** added `getPilot(projectId)`.
- **Tests:** frontend 22 (ReadinessGauge ring/label/clamp; Brief mounts + fetches pilot; existing
  ProjectScreen/Brief still green). backend 131 unchanged. Ruff, ESLint, tsc, Vite build clean.

**Next:** report polish (cover page, §12.2 section numbering, a Unicode TTF so the PDF keeps
em-dashes/curly quotes) and first-run desktop polish (icon, splash, signing).

---

### 2026-06-11 · Session 14 — Phase 7: Guided Pilot Drill-Down (spec §11)

**Done (fully deterministic — no LLM, works in sample mode):**
- **Backend `app/pilot/` package.**
  - `questions.py`: the 7 plain-English executive questions (§11.1) + `technical_checklist()` (the
    §11.2 data/architecture/risk groups, with any named data platform — SharePoint/S3/AWS/… —
    surfaced first).
  - `scorer.py`: `score_pilot(card, answers)` → a reproducible `ReadinessScorecard`. Eight
    dimensions derived by **explicit rubric** from the opportunity card's value/feasibility/risk/
    depth levels plus answer substance (rubrics are code, not vibes — identical inputs always yield
    identical scores). Maps overall → recommendation (proceed / limited_pilot / needs_discovery /
    defer / not_recommended); generates strengths/blockers/next_actions.
  - `models.py`: `PilotQuestion(s)Response`, `PilotProfile`, `TechnicalChecklistGroup`, `PilotPlan`.
  - `router.py`: `GET /projects/{id}/pilot/questions?opportunity=`, `POST /projects/{id}/pilot`
    (→ `PilotPlan`, persisted to `payload["pilot"]`), `GET /projects/{id}/pilot`.
- **Report integration.** `render_markdown`/`render_pdf` now take an optional `PilotPlan` and emit
  the §12.2 sections — Selected Pilot Recommendation, Readiness Scorecard, Technical Leader
  Questions — when present.
- **Frontend.** `OpportunityCardView` gains a "Plan this pilot" action; `Brief` tracks the selected
  card and renders `PilotDrillDown` (7 questions → submit → `ReadinessScorecardView` with dimension
  bars + recommendation badge + strengths/blockers/next actions, plus the technical checklist).
- **Tests:** backend 131 (scorer determinism + rubric direction, checklist groups + platform
  surfacing, all four endpoints incl. 404 + persistence + report-includes-pilot); frontend 20
  (PilotDrillDown flow, ReadinessScorecardView bars/badge). Verified end-to-end: 7 questions →
  92/proceed → report includes the scorecard + technical questions. Ruff/format, ESLint, tsc, Vite
  build clean.

**Next:** richer brief visuals (readiness gauge on the brief), then Phase 10 report polish (the
report TOC already mirrors §12.2). Optional: LLM-assisted answer inference for unanswered fields.

---

### 2026-06-11 · Session 13 — UX gaps: report export, project history, onboarding

**Done (closed the flagged UX gaps):**
- **PDF + Markdown report export (the spec's core promise, §4.4/§13).** New `app/report/generator.py`:
  `render_markdown()` (full Unicode) and `render_pdf()` (fpdf2 — pure-Python, no native deps, bundles
  cleanly; Unicode punctuation sanitized to the core-font charset). Endpoints
  `GET /projects/{id}/report.md` and `/report.pdf` stream the brief + opportunity cards + Q&A as a
  download (Content-Disposition attachment). Frontend `ReportPreview` is no longer a placeholder —
  it offers real **Download PDF / Download Markdown** buttons.
- **Project history / home.** `GET /projects` lists past reviews (newest first, `ProjectSummary`).
  Frontend `RecentReviews` renders them on the landing screen as links back into each brief, so a
  closed window no longer loses prior work.
- **Onboarding strip.** A compact 3-step "how it works" (company → research/brief → ask & export)
  on the landing screen so a first-time exec isn't dropped cold into a form.
- **Tests:** backend 120 (report generator MD/PDF incl. Unicode + sample flag; list + report
  endpoint contracts incl. 404). frontend 18 (ReportPreview download links; RecentReviews list +
  empty). Verified end-to-end through the app: report.md/report.pdf/list/SPA all 200. Ruff/format,
  ESLint, tsc, Vite build clean.

**Remaining polish (lower impact):** first-run window icon + boot splash; signing/notarization so
OS gatekeepers don't warn; a unicode TTF in the PDF (currently sanitized to latin-1).

**Next:** Phase 7 — Guided Pilot Drill-Down (spec §11).

---

### 2026-06-11 · Session 12 — CI triage + desktop-bundle hardening (real bugs found via a local build)

**CI status:** the "entire CI is broken" report was the wall of red from earlier Phase 6 runs —
`ruff format --check .` failed because `app/qa/classifier.py`, `app/qa/composer.py`, and
`tests/test_qa.py` weren't formatted (I'd run `ruff check` but not `ruff format`). A later commit
reformatted them, so **`ci.yml` on `main` is green again** (verified locally:
`ruff format --check` = "58 files already formatted", `ruff check` clean, 112 backend + 15 frontend
tests pass). The release workflow had never run.

**Built the desktop app locally (PyInstaller) and found real bundling bugs the dev path hid:**
- **Entry-script name collision (would crash every packaged app):** the launcher was
  `desktop/app.py`, so PyInstaller named the entry module `app`, which *shadowed the backend `app`
  package* — `import app.main` failed with "app is not a package". Renamed to `desktop/launcher.py`.
- **Missing package data:** `app/opportunity/data/library.json` wasn't bundled (collect_submodules
  only grabs `.py`). Added `collect_data_files("app")` to the spec; verified the JSON lands at
  `_internal/app/opportunity/data/library.json`.
- **Non-writable DB in a packaged app:** the default `sqlite:///./…` is relative to cwd, which can
  be read-only (macOS `.app`). `launcher.ensure_writable_db()` points `DATABASE_URL` at the
  per-user config dir when `sys.frozen`.
- **No field diagnostics + console=False gotcha:** a windowed build has no console and
  `sys.stdout/stderr` are `None`. Added `_setup_logging()` → `config_dir/launch.log` and a
  stdout/stderr redirect so nothing can crash/hang on a None stream.
- **uvicorn-under-PyInstaller robustness:** forced `loop="asyncio"`, `http="h11"` (uvicorn's "auto"
  imports native uvloop/httptools that don't bundle cleanly). Added a **browser fallback** in
  `main()` when `webview` isn't importable, so the app always works.
- `config_dir()` made public in `settings_store`; `test_desktop_launcher.py` repointed to
  `launcher.py`.

**Verified:** the build succeeds and bundles `app.main`, `library.json`, and `frontend_dist`; the
**non-frozen** launcher boots and serves SPA + API + brief end-to-end. **Could not** exercise the
*frozen* binary's runtime in this sandbox — it hangs in `uvicorn.Server.run()` after "starting
server", consistent with this container's demonstrated hostility to frozen binaries (cryptography
rust `PanicException`, `proxy-tools` wheel build failure). The forced asyncio/h11 + stdio fixes are
the standard remedies for this on real machines / GitHub runners; flagged as the one piece not
locally validated end-to-end.

**Next:** address the UX gaps — PDF/Markdown report export (core promise), onboarding, project
history.

---

### 2026-06-11 · Session 11 — Desktop packaging + seamless in-app key setup

**Goal (user):** make this consumable by a non-technical executive — a double-clickable install,
no "you must have Python," and the most seamless possible way to supply an API key.

**Research finding that shaped the design:** Anthropic's Feb 2026 policy explicitly prohibits OAuth
("sign in with Claude") for any product other than Claude Code / claude.ai; products that
authenticate end users must use **API-key auth via the Console**. So the compliant, self-contained,
most-seamless path is **Bring-Your-Own-Key made frictionless** (paste once → stored in the OS
keychain), with a one-click link to the Console and a zero-setup "explore with sample data" path.

**Done:**
- **One server serves everything.** FastAPI now mounts the built SPA (`frontend/dist`) at `/`
  (`app/main._static_dir()` resolves the bundle dir, incl. PyInstaller `sys._MEIPASS`). Frontend
  switched to `HashRouter` so all routing is client-side (`#/projects/:id`) — no deep-link route
  config, no collision with the `/projects` API. Verified one server returns the SPA at `/` plus
  `/health` and `/settings`.
- **Native desktop app (pywebview).** `desktop/app.py` boots uvicorn on a free localhost port in a
  daemon thread, waits for `/health`, then opens a native window (no browser, no terminal). Verified
  end-to-end headlessly: server boots in-thread, serves SPA + API, reports healthy.
- **Installer build.** `desktop/AIReadinessLab.spec` (PyInstaller, `console=False`, bundles the
  runtime + backend + `frontend/dist`, macOS `.app` BUNDLE). `scripts/build_desktop.sh` for local
  builds. `.github/workflows/release.yml` matrix builds Windows `.zip`, macOS `.dmg`, Linux
  `.tar.gz` on a `v*` tag (or manual dispatch) and attaches them to a GitHub Release. Linux runner
  installs GTK/WebKit for pywebview.
- **Seamless key UX.** `app/settings_store.py` stores the key in the OS keychain via `keyring`
  (Keychain / Credential Locker / Secret Service), with a 0600 file fallback for headless boxes;
  the full secret is never returned to the UI (only a `…last4` hint). `app/api/settings.py`:
  `GET /settings` (live/sample mode + masked hint + source), `PUT /settings/api-key` (validates the
  `sk-ant-` prefix), `DELETE /settings/api-key`. `create_llm()`/`resolve_api_key()` prefer the
  in-app key over env. Frontend `SettingsPanel`: a live/sample status banner on the landing screen +
  a two-click modal to paste a key (links to the Console; "continue with sample data"; "remove saved
  key"). So a packaged app is useful out of the box (sample) and one paste away from live research.
- **Tests:** backend 112 (settings store roundtrip, settings API incl. masked-key + precedence,
  static-dir resolver, desktop launcher helpers); frontend 15 (SettingsPanel banner/modal/save/error;
  intake mounts it). Ruff/format, ESLint, tsc, Vite build all clean.

**UX gaps still open (flagged for next rounds, by impact):**
- **PDF/Markdown report export** — the spec's core promise (`docs/PRODUCT_SPEC.md` §13/§4.4);
  `ReportPreview` is still a placeholder. Highest-value next UX piece.
- **Onboarding/welcome step** — the landing screen now has the key banner; a short "how it works"
  intro would further reduce cold-start for first-time execs.
- **Project history / home** — projects aren't listed anywhere; a hard window close loses the path
  to a prior brief. Add a `GET /projects` list + a home screen.
- **First-run window polish** — app icon, splash while the server boots (currently a brief blank
  window during the ~1s health wait), and signing/notarization so OS gatekeepers don't warn.

**Next step:** build **PDF/Markdown report export** (the core deliverable), then onboarding +
project history. After that, Phase 7 (Guided Pilot Drill-Down, spec §11).

---

### 2026-06-11 · Session 10 — Phase 6 hardening: bug fixes + technical-debt cleanup

**Done (make the implementation solid before Phase 7; prep a merge save-point):**
- **BUG (real, would crash in production): wrong profile field in the Q&A retriever.**
  `retriever.gather_context` read `profile.competitive_signals`, but the model field is
  `competitive_ai_signals` (every other call site uses the correct name). Any project with a
  stored profile would raise `AttributeError` on the first question. The Phase 6 tests missed it
  because they only exercised the no-profile path. Fixed the field and added
  `test_gather_context_reads_stored_profile_signals` — a regression test that stores a real
  profile with a `CompetitiveSignal` and asserts it reaches the QA context.
- **Documented gap closed: prior Q&A now feeds the composer prompt.** Added `_history_block()`
  (last 3 turns, question + direct answer) and a `PRIOR Q&A IN THIS SESSION` section to the LLM
  prompt, so multi-turn questions have continuity. Tests `test_history_block_*` cover the empty
  and populated cases.
- **Dead code removed:** `QAContext.peers` was gathered but never consumed (the competitive
  signals already carry the peer relationship the answer surfaces). Dropped the field, its
  gathering, and the now-unused `PeerClassification` import — keeps the context minimal.
- **Duplication + config-bypass fixed:** the orchestrator read the key via `get_settings()` while
  the Q&A router read `os.getenv("ANTHROPIC_API_KEY")` directly (two ways to do one thing; the
  router bypassed the config layer). Added one `create_llm()` factory in `app/llm/client.py`;
  both call sites use it. The Q&A test fixture force-patches it to `None` so contract tests are
  deterministic and never touch the network regardless of environment.
- **Single-source-of-truth restored for the TS type:** `StructuredAnswer` was hand-written in
  `client.ts`. Added it to `app/models/export.py`, regenerated `schema.json` + `types.ts`, and
  re-exported the generated interface from `client.ts` — matching how `BriefResponse` flows.
- **Frontend nit:** a section heading used the `&amp;` HTML entity inside a JSX prop; replaced
  with a literal `&` and locked it with an assertion.
- **Tests:** backend 100 (was 97), frontend 12. Ruff, ESLint, tsc, and Vite build all clean.

**What's left:** Nothing blocking — this was a hardening/save-point pass. Phase 7 (Guided Pilot
Drill-Down, spec §11) is the next feature.

---

### 2026-06-11 · Session 9 — Phase 6: Open-Ended Executive Strategy Q&A

**Done:**
- **Backend `app/qa/` package (spec §10):**
  - `classifier.py`: `QuestionType` enum (5 classes: `opportunity_seeking`, `comparison`, `risk`,
    `sequencing`, `technical`) + rule-based `classify(question)` — fast, predictable, no LLM.
  - `retriever.py`: `QAContext` dataclass + `gather_context(project_id, session)` — pulls
    profile, peer classifications, competitive signals, scored opportunity cards, and prior Q&A
    history from the project's stored payload.
  - `composer.py`: `StructuredAnswer` (9-field Pydantic model matching spec §10 fields:
    `direct_answer`, `why_it_matters`, `peer_signals`, `pilot_options`, `recommended_first_pilot`,
    `data_needed`, `risks_to_control`, `technical_questions`). LLM path uses a structured prompt
    with the resolved context; heuristic fallback when no LLM. No-hallucination guard: peer names
    only appear when a real `CompetitiveSignal` backs them; pilot options only come from the
    scored opportunity library.
  - `router.py`: `POST /projects/{id}/qa` → `StructuredAnswer`. History persisted to
    `ProjectRow.payload["qa_history"]` so future questions have prior-answer context.
- **Frontend `QAPanel` component:** question input + nine-field structured answer card (type
  label, direct answer, why it matters, peer signals, pilot options, recommended first pilot
  highlight, data needed, risks to control, technical questions). Wired into `Brief.tsx` below
  the opportunity grid. `askQuestion()` added to the typed API client with `StructuredAnswer`
  interface.
- **Tests:** 18 new backend tests in `test_qa.py` (classifier parametrized across 11 cases,
  heuristic fallback shape + no-invented-peers guard, compose_answer null-LLM path, API
  contract: 200 shape, 404, 422, history persistence). 3 new frontend tests for `QAPanel`
  (submit → answer card, disabled empty input, error state). 97 backend + 12 frontend total,
  all passing. Ruff, ESLint, tsc, Vite build all clean.

**Gaps / bugs found:**
- `qa_history` is stored and available to the retriever context dict, but the composer prompt
  currently doesn't inject prior Q&A turns. Add `PRIOR ANSWERS:` block to the prompt when
  multi-turn conversation quality becomes important (Phase 7+).
- The heuristic fallback always uses the same generic `why_it_matters` sentence regardless of
  question type. Fine for now — LLM path customizes it properly.

**What's left in Phase 6:** Nothing blocking — core acceptance met: exec can type a question on
the brief screen and receive a structured, nine-field grounded answer (§10 format) with no
invented peer names.

**Next step (Phase 7 — Guided Pilot Drill-Down, spec §11):** After the executive picks an
opportunity, the app asks 7 plain-English questions, then produces a readiness assessment and
technical-leader checklist. See `docs/IMPLEMENTATION_PLAN.md` Phase 7.

---

### 2026-06-11 · Session 8 — Gap fixes + Phase 4 (Peer Taxonomy) + Phase 5 (Opportunity Map)

**Done:**
- **Git identity fix (user-reported):** all prior commits were authored/committed as
  `Claude <noreply@anthropic.com>`. Set `git config` to `oney-erge <oneyerge@gmail.com>`,
  rewrote the whole branch history to the owner identity, and added the MANDATORY git-identity
  rule to Repository etiquette above. The GitHub contributor is now the owner, never Claude.
- **Gap 1 (official-site classification):** `source_ranker.resolve_company_domain()` matches the
  company's name tokens to a result's domain label (conservative — exact/prefix match, avoids
  unrelated same-word sites). The orchestrator resolves the domain and re-classifies the evidence
  set so the company's own site is `official`, not `blog`. Names that don't echo their domain
  (ticker-style) stay unresolved until the profiler supplies `company_identity.website`.
- **Gap 2 (evidence persistence):** added `BriefResponse.sources` (`BriefSource[]`); the
  orchestrator attaches the ranked evidence to the brief and `_store_results` persists it, so
  `GET /brief` returns the Evidence panel after a reload. Frontend `Brief` prefers `brief.sources`
  and falls back to the live session sources.
- **Phase 4 — Peer taxonomy & competitive intelligence:**
  - `research/peer_classifier.py`: rule-based `classify_peer()` over a curated company→role set
    (oil&gas operators vs oilfield-services; CRM vendors; cloud/fintech tech vendors; banks). Each
    verdict is a `PeerClassification {company, peer_type, reason, confidence}`. Unknown companies
    → low-confidence `adjacent_benchmark` (defer, never guess direct competitor). `to_taxonomy()`
    buckets them into the profile's `PeerTaxonomy`.
  - `research/competitive_signals.py`: `reconcile_peer_types()` overrides each signal's peer_type
    with the classifier's verdict (a service company can never be shown as a direct competitor);
    `filter_relevant()` drops unsourced/low-confidence signals.
  - New `PeerClassification` model (exported to TS); `GET /projects/{id}/peers` exposes the
    explained taxonomy; `GET /projects/{id}/profile` exposes the stored profile.
- **Phase 5 — AI opportunity map:**
  - `app/opportunity/data/library.json` (14 curated use cases across the spec §6 categories) +
    `library.py` loader (`UseCase`).
  - `opportunity/scorer.py` `score_opportunities(profile, signals)`: keyword fit vs the profile,
    competitive-pressure bonus from matching peer signals, value/feasibility/risk ranking →
    5–10 `OpportunityCard`s. **No-hallucination guard:** a card names a peer in
    `competitive_pressure` ONLY when a real signal backs it; otherwise the text makes no peer claim.
  - Orchestrator LLM path now builds the corrected taxonomy + vetted signals + ranked cards and
    feeds the deterministic cards into the brief; profile + peers persisted.
- **Tests:** backend 79 (peer classifier eval incl. the Oxy/SLB spec example, competitive-signal
  hygiene, opportunity scorer + guard, domain-resolver, peers/profile endpoints, evidence
  persistence); frontend 9. Ruff/ESLint/tsc/Vite build all clean.

**Gaps / bugs found:**
- The peer classifier is a curated set; companies outside it defer to `adjacent_benchmark`. When
  the LLM path runs, unknown peers keep the model's label — acceptable, but expanding the curated
  set (or an LLM-assisted classify with a reason) would raise coverage.
- Phase 4/5 enrichment only populates live when `ANTHROPIC_API_KEY` is set (needs a profile). The
  deterministic engines are fully unit-tested regardless; the no-key demo still streams real
  DuckDuckGo evidence + a sample brief.
- Local server smoke test couldn't run this turn (sandbox SIGTERMs long-running uvicorn, exit
  144); relied on the in-process API tests instead. Live DDG streaming was verified in Session 7.

**What's left:** Phase 6 — Open-Ended Strategy Q&A (the follow-up chat on the brief), then Phase 7+
(guided intake, readiness scoring, technical bridge, report generator).

**Next step (Phase 6 — Strategy Q&A):** question classifier → context retriever (profile + peer
signals + opportunity library) → structured answer composer → wire into a chat surface on the
project. See `docs/IMPLEMENTATION_PLAN.md` Phase 6.

---

### 2026-06-11 · Session 7 — Phase 3.5: Streaming Research Console (AI Elements)

**Done:**
- **Backend — live streaming events:** orchestrator now emits `interim` (`{label, detail}`) and
  `source` (`{url, title, source_type, confidence}`) SSE events. New `_stream_sources()` runs the
  planned searches with `asyncio.as_completed`, classifies + dedupes each batch, and yields a
  `source` event per kept result as it arrives — bounded by the research budget (max sources +
  wall-clock timeout). Sources are re-ranked before the top 20 go to the LLM. Verified live
  end-to-end against real DuckDuckGo (steps + interim + real source URLs stream correctly).
- **Frontend — AI Elements adoption:** added **Tailwind v4** via `@tailwindcss/vite` (+ `clsx`,
  `tailwind-merge`, `cn()` helper in `src/lib/utils.ts`). Authored AI Elements-style components
  owned in-repo under `src/components/ai/`: `Task`/`TaskItem` (status icons incl. animated active
  spinner) and `Sources` (count badge + credibility-tagged list). New `ResearchConsole` composes
  them: live step task list, last-3 interim findings under the active step, and a growing source
  list. `ProjectScreen` now tracks `interims`/`sources` and renders the console; the `Brief` shows
  an Evidence panel of the real sources reviewed.
- **Client:** `subscribeResearch` dispatches by event type with optional `onInterim`/`onSource`
  handlers; added `InterimEvent`/`SourceEvent` types. Removed the old `ResearchProgress` component.
- **Tests:** backend 53 (added real-path streaming + budget tests, SSE source/interim contract
  test); frontend 9 (new `ResearchConsole` tests; existing ProjectScreen/Brief still green).
  Typecheck, ESLint, Vite build (Tailwind compiles) all clean.
- **Docs:** ARCHITECTURE event contract marks `interim`/`source` implemented; IMPLEMENTATION_PLAN
  Phase 3.5 marked mostly complete.

**Gaps / bugs found:**
- **Official-site misclassification:** the company's own domain (e.g. `oxy.com`) classifies as
  `blog` until the profiler resolves the domain, because `company_domain` isn't passed to the
  ranker during the live search phase. Fix when the profiler resolves identity first, or do a
  cheap pre-resolve. Wikipedia also lands as `blog` — add a small known-domain rule if desired.
- **Brief sources are session-only:** the Evidence panel uses the `sources` accumulated in the
  client during the SSE run; on a hard reload `/brief` doesn't return them. Persist sources with
  the brief (or expose `GET /projects/{id}/sources`) in a later phase.
- **Tailwind + plain CSS coexist:** new AI components use Tailwind; older screens still use
  `index.css`. Fine, but migrate the rest to Tailwind when touching them to avoid two systems.

**What's left in Phase 3.5:** Follow-up **chat** on the brief (deferred to Phase 6) and the
readiness gauge (after Phase 8 scoring). Core acceptance met: the console never sits silent and
shows real, credibility-ranked sources live.

**Next step (Phase 4 — Peer Taxonomy & Competitive Intelligence):** peer classifier with stated
reasons + `CompetitiveSignal` extraction per peer; pass the resolved company domain to the ranker
to fix official-site classification. See `docs/IMPLEMENTATION_PLAN.md` Phase 4.

---

### 2026-06-11 · Session 6 — Flow diagrams, UI-kit decision, DuckDuckGo + research budget

**Done:**
- **UI kit decision (user-confirmed):** adopt **AI Elements (shadcn/ui)** — copy-paste React
  components owned in-repo (Conversation, Message, Reasoning, Tool/Task, Sources). Researched
  online vs. assistant-ui; chose AI Elements for maximum extensibility + native streaming/step/
  citation primitives. Adoption itself is scoped as new **Phase 3.5** (not built this turn).
- **DuckDuckGo locked as the default** search provider (free, no key). `get_provider` docstring
  clarified; Tavily/Serper remain opt-in via env key. `.env.example` updated.
- **Deep-research budget:** added `RESEARCH_MAX_SOURCES` (100) + `RESEARCH_TIMEOUT_SECONDS` (600)
  to `config.py`; orchestrator now wraps the parallel search in `asyncio.wait_for(timeout)` and
  caps ranked sources at the budget — a run is always bounded; on a budget hit it synthesizes
  from evidence gathered so far.
- **`docs/ARCHITECTURE.md` (new):** three Mermaid diagrams — (1) technical flow intake→SSE→
  orchestrator→DuckDuckGo→ranker→evidence JSON→Claude profiler/brief→SQLite, (2) user journey
  (landing→live console→visual brief→drill-down/follow-up/export), (3) streaming "show your work"
  sequence + the SSE event contract (`step` and `done` implemented; `interim`/`source` planned
  for the Phase 3.5 console). All three validated by rendering with `mmdc` (puppeteer
  `--no-sandbox`).
- **`docs/IMPLEMENTATION_PLAN.md`:** status → Phases 0–3 complete; decisions table gains web-search,
  research-budget, and UI-kit rows; open questions for provider + UI kit marked DECIDED; added
  Phase 3.5 (Streaming Research Console); linked ARCHITECTURE.md.

**Gaps / bugs found:**
- `mmdc` (mermaid CLI) needs a puppeteer config with `--no-sandbox` to run as root in this
  container. Not a syntax problem — note it for any future diagram validation.
- The bounded-budget timeout is only wired around the current single-round parallel search. The
  full iterative deep-research loop (fetch page bodies, expand to ~100 sources, emit live
  `interim`/`source` events) is Phase 3.5/4 work — the config knobs and guard are in place for it.

**What's left before Phase 4:** Build Phase 3.5 (AI Elements console + interim/source SSE events).

**Next step:** Phase 3.5 — install Tailwind + shadcn, pull AI Elements into `src/components/ai/`,
build the streaming console (step/interim/source feed + source counter) and a visual cited brief;
emit `interim`/`source` events from the orchestrator. See `docs/ARCHITECTURE.md` event contract.

---

### 2026-06-11 · Session 5 — Gap fixes + Phase 3: Research Orchestrator

**Done:**
- **Gap fixes (from Session 4 log):**
  - Added `compare_competitors` to `Mode` enum; added 4th radio option to `IntakeScreen.tsx`;
    regenerated `src/api/types.ts` (Mode now includes all 4 values).
  - Fixed React Router v6 future-flag warnings: added `future={{ v7_startTransition: true,
    v7_relativeSplatPath: true }}` to `MemoryRouter` in `IntakeScreen.test.tsx` and the new
    `ProjectScreen.test.tsx`.
  - Added `ProjectScreen.test.tsx` (3 tests: step progress, brief ready, error state) using
    mocked `subscribeResearch` and `getBrief`.
- **Phase 3 — Research Orchestrator:**
  - `backend/app/llm/client.py` — `AnthropicClient` wrapping the Anthropic SDK (model
    `claude-opus-4-8`) with `complete()` and `as_repair_fn()`.
  - `backend/app/research/providers.py` — `SearchProvider` protocol + three implementations:
    `TavilyProvider` (TAVILY_API_KEY), `SerperProvider` (SERPER_API_KEY), `DuckDuckGoProvider`
    (free, open-source, no API key — uses `duckduckgo-search` package). Factory `get_provider`
    picks highest-priority available provider.
  - `backend/app/research/query_planner.py` — `QuerySet` dataclass + `plan_queries()` generating
    7 search buckets (identity, financial, strategic, competitors, competitor_ai, industry_ai,
    company_ai) with mode-specific extras.
  - `backend/app/research/source_ranker.py` — domain-pattern classification of `SourceType`,
    confidence hierarchy (filing=0.95 > official=0.90 > analyst=0.80 > news=0.70 … > blog=0.40),
    URL deduplication, ranked `classify_and_rank()`.
  - `backend/app/research/company_profiler.py` — prompts Claude to extract
    `CompanyIntelligenceProfile` from up to 20 ranked sources; uses repair loop; returns minimal
    profile on failure.
  - `backend/app/research/brief_generator.py` — prompts Claude to generate `BriefResponse` from
    the profile; falls back to `sample_brief()` on failure.
  - `backend/app/research/orchestrator.py` — main async generator `run()`: parallel search
    gather → source classification → LLM profiling → brief generation → brief persisted in
    `ProjectRow.payload["brief"]`. **Mock path** (no API keys → `_create_provider` and
    `_create_llm` both return None) fires 8 steps with configurable `STEP_DELAY_SECONDS`; no
    network calls needed.
  - `backend/app/api/projects.py` simplified — SSE endpoint calls `orchestrator.run()`;
    `GET /projects/{id}/brief` reads stored brief from `payload["brief"]`, falls back to
    `sample_brief()` if not yet populated.
  - `requirements.txt` updated: `anthropic==0.109.1`, `tavily-python==0.7.26`,
    `duckduckgo-search==8.1.1`.
  - 28 new tests across `test_query_planner.py`, `test_source_ranker.py`,
    `test_company_profiler.py`, `test_orchestrator.py`. Total: 50 backend + 8 frontend, all pass.
    Ruff clean, ESLint clean, tsc clean, build passes.

**Gaps / bugs found:**
- `brief_generator.py` prompt uses Python f-string with `{{` / `}}` for literal braces inside
  a triple-quoted template; slightly awkward but works. Could be refactored to a Jinja2 template
  when more prompts exist.
- `duckduckgo-search` 8.x: `DDGS` is no longer a context manager in all environments — using
  `DDGS().text(...)` directly (no `with` block). If the package breaks, swap to Tavily/Serper.
- The LLM brief is stored in `ProjectRow.payload["brief"]` (mixed into the Project JSON blob).
  Consider a separate `BriefRow` table in Phase 4 when the brief grows.
- No ANTHROPIC_API_KEY → LLM profiling is skipped silently; brief returned is still
  `is_sample=True`. This is correct behaviour for the demo, but a UI indicator ("sample data —
  set ANTHROPIC_API_KEY for real research") would be more transparent.

**What's left in Phase 3:** Nothing blocking — acceptance met (real search + LLM profiling
pipeline wired end-to-end; graceful degradation to sample data when no keys; all tests pass).

**Next step (Phase 4 — Peer & Competitive Intelligence):** Build the competitive-signal
extractor that populates `CompetitiveSignal` list per peer; expand source queries to target
competitor announcements, job boards, and press releases; add peer-taxonomy resolution; surface
competitive signals in the Brief and opportunity cards. See `docs/IMPLEMENTATION_PLAN.md`
Phase 4.

---

### 2026-06-11 · Session 4 — Phase 2: Executive Shell

**Done:**
- Backend API (`app/api/`): `POST /projects` (create + persist), `GET /projects/{id}`,
  `GET /projects/{id}/research/stream` (SSE mock job emitting the 8 spec §4.3 steps,
  then flips status → ready), `GET /projects/{id}/brief` (illustrative sample brief).
  Request/response schemas in `app/api/schemas.py`; sample content in `app/api/sample.py`
  (clearly flagged `is_sample`, asserts no company facts — respects no-hallucination rule).
- Router wired into `main.py`; API schemas added to the TS type export.
- Frontend (proper React): `react-router-dom` routing — `IntakeScreen` (company/role/mode,
  no technical knobs) → `ProjectScreen` (subscribes to SSE, shows `ResearchProgress`, then
  `Brief` with `OpportunityCardView` grid + `ReportPreview` placeholder). Typed client
  extended with `createProject`, `getBrief`, `subscribeResearch` (EventSource). `index.css`
  for a clean executive surface.
- Tests: backend 22 pass (5 new API/SSE contract tests); frontend 5 pass (intake, brief,
  progress). Typecheck + lint + build green. Verified the whole flow against a live uvicorn
  server (create → stream → ready → brief with 4 opportunities).

**Gaps / bugs found:**
- In-memory SQLite gives each connection its own DB; TestClient runs sync endpoints in a
  threadpool, so tables were missing. Fixed with `StaticPool` (shared connection) in the
  API test fixture. Use that pattern for any future TestClient+SQLite tests.
- SSE completion and merge-conflict-style transitions aren't delivered as events; the client
  detects done via a `{"type":"done"}` sentinel then closes the EventSource to avoid the
  browser's auto-reconnect. Keep that sentinel when the real research job replaces the mock.
- React Router v6 prints v7 future-flag warnings in tests (harmless). Opt into the flags or
  upgrade to v7 when convenient.
- UI mode selector exposes 3 modes (matches the `Mode` enum); the spec §4.2 mock shows a 4th
  ("Compare against competitors"). Left at 3 to avoid inventing an enum value — reconcile in spec.
- `EventSource` isn't exercised in jsdom tests (SSE is covered by the backend contract test +
  the live smoke test). An integration test for `ProjectScreen` could mock `subscribeResearch`.

**What's left in Phase 2:** Nothing blocking — acceptance met (a non-developer can click the
whole journey on mock data; no technical settings are visible by default).

**Next step (Phase 3 — Research Orchestrator):** Replace the mock SSE job with real research —
query planner (spec §7.3), source collector + ranker (§7.4), company profiler and AI-signal
extractor producing a populated `CompanyIntelligenceProfile` with per-claim `source_refs` +
confidence. Decide the web-search provider first (open question in the plan). See
`docs/IMPLEMENTATION_PLAN.md` Phase 3.

---

### 2026-06-11 · Session 3 — Phase 1: Domain Contracts (Schemas First)

**Done:**
- Pydantic v2 domain models for spec §8 + §15 under `backend/app/models/`:
  `Project`, `CompanyResearchPlan`, `SourceRecord`, `CompanyIntelligenceProfile`
  (+ sub-models), `CompetitiveSignal`, `OpportunityCard`, `ReadinessScorecard`.
  Shared enums + `Confidence`/`Score` value types in `models/base.py`.
- Structured-output **repair loop** (`app/llm/repair.py`) with injected `repair_fn`
  so it is unit-testable offline; strips ``` fences, bounded retries, raises
  `StructuredOutputError` when unrepairable.
- SQLAlchemy layer (`app/db/`): `Base`, engine/session, `ProjectRow`/`SourceRow`
  (queryable columns + JSON payload). `init_db()` wired into FastAPI lifespan.
- Env-driven `app/config.py` (pydantic-settings).
- **TypeScript types generated from the Pydantic schemas**: `app/models/export.py`
  emits `backend/schema.json`; `npm run generate:types` → `frontend/src/api/types.ts`.
- Proper React wiring: typed API client (`src/api/client.ts`), `App.tsx` calls
  `/health` with loading/online/offline states, **Vitest + Testing Library** set up
  with 3 passing component tests.
- CI updated to run `npm test`. Backend: 17 tests pass, ruff clean. Frontend:
  typecheck + lint + 3 tests + build all pass.

**Gaps / bugs found:**
- `model_copy(update=...)` bypasses Pydantic validation — a test relied on it and
  gave a false pass; fixed to construct fresh. Worth remembering for future tests.
- Vitest 2.x pinned Vite 5 while the app uses Vite 6 (duplicate Vite, type clash);
  fixed by upgrading to Vitest 3. Keep Vitest and Vite majors aligned.
- `PeerType` and `Recommendation` are intentional supersets of the narrower enums
  in spec §8.2/§15.4 (added `supplier`/`customer` and `not_recommended`) to match
  the broader §3.3/§9.4 text. Reconcile the spec enums when convenient.
- No CI check yet that `types.ts` is in sync with the schemas (would need Python in
  the frontend job). Regeneration is a documented manual step for now.
- `json2ts` emits noisy per-field aliases (`ProjectId`, `CompanyName1`, …); harmless
  but ugly. Acceptable for a generated file.

**What's left in Phase 1:** Nothing blocking — acceptance met (every model has a typed
schema + round-trip test; invalid LLM JSON is repaired or rejected; TS types generated).

**Next step (Phase 2 — Executive Shell):** Build the intake screen (company/role/mode),
`POST /projects`, the SSE research-progress screen on mock data, the static sample
brief, opportunity cards list, and report-preview placeholder — all wired through the
typed API client. See `docs/IMPLEMENTATION_PLAN.md` Phase 2.

---

### 2026-06-11 · Session 2 — Phase 0: Repository Scaffold

**Done:**
- Phase 0 fully built: FastAPI `/health` skeleton, Vite + React + TypeScript
  frontend, `ruff`/`pytest` on the backend, `eslint`/`tsc` on the frontend.
- `.gitignore`, `.env.example`, `backend/pyproject.toml`, all test/config files.
- `CLAUDE.md` updated with live commands and this session-log rule.
- All backend tests passing (`pytest`); frontend build + typecheck + lint passing.
- Committed and pushed to `claude/claude-md-best-practices-b31l7x`.

**Gaps / bugs found:**
- No CI workflow yet (GitHub Actions file). Phase 0 acceptance requires CI;
  to be added in a follow-up commit once confirmed the environment supports it.
- `requirements.txt` pins versions that were current Jan 2026; verify they
  resolve cleanly in the target Python environment before cutting a release.
- Frontend uses plain CSS (no design system). That's fine for Phase 0 but will
  need a decision (Tailwind / shadcn / other) before Phase 2 UI work.

**What's left in Phase 0:**
- GitHub Actions CI workflow (lint + test on both sides from a clean clone).
- Confirm CI green before marking Phase 0 done per `docs/IMPLEMENTATION_PLAN.md`.

**Next step (Phase 1):**
- Translate `PRODUCT_SPEC.md` §8 and §15 data models into Pydantic v2 schemas
  (`Project`, `CompanyResearchPlan`, `SourceRecord`, `CompanyIntelligenceProfile`,
  `CompetitiveSignal`, `OpportunityCard`, `ReadinessScorecard`).
- Add the structured-output repair-loop utility.
- Add SQLAlchemy tables + DB session.
- Generate TypeScript types from the schemas via OpenAPI export.

---

### 2026-06-11 · Session 1 — Foundation docs

**Done:** Created `CLAUDE.md`, `docs/PRODUCT_SPEC.md` (original vision),
`docs/IMPLEMENTATION_PLAN.md` (12-phase build plan), `README.md`.

**Gaps:** No application code existed yet.

**Next step:** Phase 0 scaffold (this session).

---

## Project

AI Readiness Lab is a C-level AI readiness, competitive-intelligence, and pilot-planning
workbench. A user enters a company name and role; the app researches public company and
market signals, classifies competitors and peers, maps practical AI pilot opportunities,
scores readiness, and exports an executive-ready report (Markdown/PDF).

- **What/why (product spec):** `docs/PRODUCT_SPEC.md`
- **How/when (implementation plan):** `docs/IMPLEMENTATION_PLAN.md`
- **Audience:** CTOs, CIOs, COOs, CDOs, VPs, transformation leaders, executive AI sponsors.

## Tech stack (target)

- **Frontend:** React + Vite + TypeScript
- **Backend:** Python 3.11+, FastAPI, Pydantic v2
- **Persistence:** SQLite via SQLAlchemy (local project files)
- **Reports:** Jinja2 templates → Markdown → PDF (WeasyPrint or Playwright)
- **LLM:** Claude via the Anthropic SDK. Default to the latest capable model
  (`claude-opus-4-8`). Use structured JSON outputs validated by Pydantic schemas.
- **Research:** Web search API, source ranking, citation tracking.

## Commands

```bash
# Backend
cd backend
pip install -r requirements.txt   # install all backend deps (runtime + dev)
uvicorn app.main:app --reload      # dev server at http://localhost:8000
pytest                             # run all tests
pytest tests/test_health.py        # run a single test file
ruff check .                       # lint
ruff format .                      # format

# Generate frontend types from backend schemas (run after changing app/models)
cd backend && python -m app.models.export   # writes backend/schema.json
cd ../frontend && npm run generate:types     # writes src/api/types.ts (do not hand-edit)

# Frontend
cd frontend
npm install                        # install deps
npm run dev                        # dev server at http://localhost:5173
npm run build                      # production build
npm run typecheck                  # tsc --noEmit
npm run lint                       # eslint
npm test                           # vitest run
```

## Working rules

- **IMPORTANT — Do not hallucinate.** This is a research product; fabricated facts destroy
  its credibility. Every factual or competitive claim must trace to a retrieved source with
  a confidence note. If a source does not support a claim, say so. Never invent revenue
  figures, AI outcomes, quotes, URLs, tickers, or citations. Prefer "not found in public
  sources" over a plausible guess.
- **YOU MUST write minimal code.** Implement exactly what the task needs and nothing more.
  No speculative abstractions, options, or "might need later" scaffolding. The smallest
  change that correctly solves the problem wins.
- **Do not write extra/nonsensical code.** No dead code, no unused parameters, no commented-out
  blocks, no filler comments restating the obvious. Delete code that is not used.
- **Test your work.** Add or update a focused test for any non-trivial change and run it
  before claiming done. Report real output; if something fails or is skipped, say so plainly.
- **Reuse before adding.** Search for an existing helper/pattern before writing a new one.
  Match the surrounding code's style, naming, and structure.
- **Validate at the boundary.** All LLM/research outputs cross a Pydantic schema with a
  repair loop. Never trust raw model JSON downstream.
- **Classify peers carefully.** Distinguish direct competitors, operator peers, service
  companies, technology vendors, suppliers, customers, and adjacent benchmarks. Label every
  competitive signal with its peer type. A wrong comparison is a correctness bug, not a style
  nit. See `docs/PRODUCT_SPEC.md` §3.3.
- **Keep the executive surface clean.** No model pickers, vector-DB choices, or infra
  questions in the default user UI. Technical depth lives behind drill-downs and the appendix.
- **Secrets:** never commit API keys or `.env`. Read config from environment variables.

## Repository etiquette

- Working branch: `claude/claude-md-best-practices-b31l7x`.
- **Git identity (MANDATORY):** every commit MUST be authored AND committed as the repo
  owner — `git config user.name "oney-erge"` and `git config user.email "oneyerge@gmail.com"`.
  NEVER commit as `Claude <noreply@anthropic.com>` or any Anthropic identity. The contributor
  shown on GitHub must be the owner, not Claude. Verify with `git log --format='%an <%ae>'`
  before pushing; if any commit on the branch shows Claude as author/committer, rewrite it.
- Commit messages: imperative mood, no "Claude" branding in the title or body.
- Do not create a pull request unless explicitly asked.
- Keep `docs/PRODUCT_SPEC.md` (vision) and `docs/IMPLEMENTATION_PLAN.md` (execution) in sync
  with real decisions as they are made.
