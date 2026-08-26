# AGENTS.md

## Project

AI Readiness Lab is a local C-level research and planning workbench. It researches
public company and competitor AI signals, classifies peers, identifies practical
enterprise AI pilots, scores readiness, and generates executive-ready reports.

Use these as the durable sources of truth:

- `docs/PRODUCT_SPEC.md` for product intent and research methodology.
- `docs/IMPLEMENTATION_PLAN.md` for delivery phases and acceptance criteria.
- `docs/ARCHITECTURE.md` for current system boundaries.
- `docs/AI_SESSION_HISTORY.md` only for historical context, never as active rules.

## Commands

Backend:

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
pytest
ruff check .
ruff format --check .
```

Frontend:

```bash
cd frontend
npm ci
npm run dev
npm run typecheck
npm run lint
npm test
npm run build
```

After changing Pydantic models:

```bash
cd backend
python -m app.models.export
cd ../frontend
npm run generate:types
```

`frontend/src/api/types.ts` is generated; do not hand-edit it. Desktop packaging
and release commands are documented in `README.md` and the release workflow; do
not build or publish installers unless explicitly requested.

## Research and Product Invariants

- Never fabricate facts, figures, quotes, URLs, tickers, citations, or AI outcomes.
  Every factual and competitive claim must trace to retrieved evidence and carry
  an appropriate confidence signal.
- Prefer "not found in public sources" to a plausible but unsupported answer.
- Distinguish direct competitors, operator peers, service companies, technology
  vendors, suppliers, customers, and adjacent benchmarks. Peer type is part of
  correctness.
- Validate all model-produced structured data through the Pydantic boundary and
  repair/reject invalid output; never trust raw model JSON downstream.
- Keep research provenance, source references, and confidence attached as data
  moves through backend, API, UI, and reports.
- Keep the executive default surface focused on decisions. Put model/provider and
  infrastructure detail behind drill-downs or appendices.
- Read model/provider choices from configuration. Do not hardcode a model as
  "latest" or assume a temporally unstable service capability.

## Architecture Boundaries

- `backend/app/` owns research, domain models, orchestration, persistence, API,
  report generation, and LLM integration.
- `frontend/src/` owns the typed executive UI and consumes generated contracts.
- `desktop/` and `scripts/` own packaging and local launch behavior.
- Keep API handlers thin and share domain logic with background/research flows.
- Keep sample/demo behavior visibly separate from live research.
- Never commit API keys, `.env`, local databases, research cache, generated
  reports containing private data, frontend build output, or packaging artifacts.

## Change Style

- Inspect the relevant product rule, schema, and existing test before editing.
- Make the smallest coherent change and reuse existing patterns.
- Fix a shared schema, prompt, or pipeline cause rather than patching one company
  or one response example.
- Preserve unrelated changes and keep product and implementation docs aligned
  when a real decision changes.

## Verification

- Documentation or guidance only: verify referenced paths and run
  `git diff --check`; application tests are not required.
- Backend behavior: run the focused test, then `pytest`; run Ruff for Python
  changes.
- Frontend behavior: run the focused Vitest test, typecheck, lint, and build as
  appropriate.
- Schema changes: regenerate both schema artifacts and review the diff.
- Research changes: use deterministic fixtures first; report live network/model
  validation separately with the actual provider and fallback state.

Never claim a check ran unless its output was observed.

## Git and Handoff

- Use the configured repository-owner identity and focused commit messages.
- Do not add assistant names, co-author trailers, session links, or tool
  attribution to Git artifacts.
- Do not create or rewrite session diaries in active instruction files.
- Finish with what changed, what was verified, what was skipped, and remaining
  evidence, product, or release risks.


## Install and run contract

- Keep `run.bat`, `run.ps1`, `run.command`, and `run.sh` as the stable
  user entry points. They must keep the same `run`, `doctor`, `repair`,
  `docker`, `logs`, and `stop` actions where the application supports them.
- Use the `native-app-delivery` Codex skill when changing first-run setup,
  repair, Docker, or launcher behavior. That is an internal workflow name and
  must not appear in product copy or the public README.
- Keep shared install mechanics in `scripts/install-utils.ps1` and
  `scripts/install-utils.sh`. Preserve idempotent reruns, bounded transient
  retries, install locking, disk checks, user state, and `.setup/install.log`.
- Verify launcher changes with PowerShell parsing, `bash -n`, the focused
  delivery audit, and `docker compose config`. Do not run the full application
  test suite unless the change affects application behavior.
