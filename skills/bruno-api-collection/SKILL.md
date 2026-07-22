---
name: bruno-api-collection
description: >-
  Use when the user wants a Bruno API collection — a git-versioned folder of `.bru` request files
  (usually `/bruno` at a repo root) that stores, runs, documents, and replays a project's HTTP/REST
  requests next to its code. Trigger whenever they want to: create, scaffold, or set up Bruno in a
  repo; add, update, remove, rename, or reorganize requests; keep the collection in sync after routes
  change; turn a project's own endpoints into runnable, versioned docs; or reproduce/replay outbound
  calls to a third-party API for debugging. This is the skill for any wish to "version our API requests
  alongside the code so we can test/replay them from the repo," even phrased entirely without the word
  "Bruno." Also fires on any mention of `.bru`, `bruno.json`, or the `bru` CLI. Works in English and
  French. Do NOT use for OpenAPI/Swagger spec generation, typed API client codegen, Postman, Docker/env
  setup, or CI smoke-tests.
---

# Bruno API Collection

Bruno is an offline, git-friendly API client: a collection is a plain folder of `.bru` text files
that lives *in the repo*, so requests, environments and docs are versioned and reviewable like code.
This skill frames how to lay out and maintain a `/bruno` folder at a project's root so it stays a
faithful, low-friction mirror of the project's API surface.

Two things share this folder and must stay clearly separated:

- **Exposed API** — the endpoints *this project publishes* (e.g. its own REST routes). The collection
  is the living, runnable documentation of that contract.
- **Upstream API** — the third-party services *this project consumes* (payment, messaging, etc.).
  These requests reproduce the outbound calls the code makes, so a human can replay and debug them.

Keep them in two top-level folders (`exposed/` and `upstream/`) so a reader instantly knows whether a
request is "our contract" or "someone else's".

## Before doing anything: read the syntax reference

Read `references/bru-syntax.md` before writing or editing any `.bru` file. Bruno's markup is small but
exact — a wrong block name silently breaks the request in the app. The reference has the full block
list, an annotated request example, the environment format, and the secrets convention. Don't
reconstruct `.bru` syntax from memory.

## Step 1 — Bootstrap or maintain?

Check whether `/bruno` already exists at the project root.

- **Absent** → bootstrap: create the folder skeleton (Step 3), then discover and add requests (Step 4).
- **Present** → maintain: read `bruno.json` and the existing tree first, match the conventions already
  in use (naming, folder split, how secrets are referenced), and only add/adjust what changed. Never
  reorganize a working collection wholesale — a Bruno collection is edited by humans in the app too, so
  churn is costly and confusing.

## Step 2 — Discover the API surface

Don't invent endpoints. Read them out of the codebase so the collection reflects reality.

- **Exposed endpoints**: grep for the framework's route registration (e.g. `register_rest_route`,
  `add_action('rest_api_init'...)`, `@app.route`, `router.get`, `Route::`, OpenAPI/Swagger specs).
  Capture method, path, required params/headers, and auth for each.
- **Upstream calls**: grep for the HTTP client the code uses (`wp_remote_post`, `curl_`, `fetch(`,
  `axios`, `HttpClient`, `requests.`) and the base URLs / API hosts it targets. Capture the same details.

If an OpenAPI/Swagger/Postman file already exists, treat it as the source of truth for the exposed API
and mirror it, rather than re-deriving from code.

List what you found and confirm scope with the user before scaffolding dozens of requests — they may
only want a subset (e.g. the public webhook, not every admin route).

## Step 3 — Folder skeleton (use the scaffold script)

The skeleton is identical for every collection, so don't hand-write it — run the bundled script. It
creates `bruno.json`, `collection.bru`, the `exposed/` and `upstream/` folders, the environment files,
`.env`/`.env.example`, and the `.gitignore` entry, and it's **idempotent** (never overwrites an existing
file), so it's also safe to run just to add a new environment later.

Run it with the script's path resolved against this skill's own directory (not the project cwd):

```bash
python3 <skill-dir>/scripts/scaffold_bruno.py --root <project-root> --name <collection-name> \
  --envs local,staging,production \
  --secrets WA_ACCESS_TOKEN,WA_VERIFY_TOKEN \
  --base-urls local=http://localhost:8080,staging=https://staging.example.com
```

- `--envs` — adapt to what the user actually runs. The default `local,staging,production` fits most
  projects, but if they only mention `dev` and `prod`, pass `--envs dev,prod`. Don't impose environments
  they didn't ask for.
- `--secrets` — the secret env-var names you found in Step 2 (tokens, API keys). Each is wired into every
  environment as `name: {{process.env.NAME}}` and listed (empty) in `.env.example`.
- `--base-urls` — set the ones you know; any environment left out gets a `TODO` placeholder to fill in.

Resulting layout:

```
bruno/
├── bruno.json            # collection manifest
├── collection.bru        # collection-level shared headers/docs
├── .env.example          # documents required secrets — COMMITTED
├── .env                  # real secret values — GIT-IGNORED, never committed
├── environments/         # one .bru per environment
├── exposed/folder.bru    # endpoints this project publishes
└── upstream/folder.bru   # third-party APIs this project consumes
```

The `.gitignore` entry (`bruno/.env`) is the single most important maintenance rule: **secret values
never enter git**. The script adds it; verify it landed. See Step 5.

## Step 4 — Write the requests

One `.bru` file per (endpoint, method), and **one endpoint per file** — never bundle several routes into
one request. Name files in **kebab-case** after the resource and action (`orders-create.bru`,
`contact-delete.bru`, `webhook-verify.bru`), no spaces. Consistent, greppable names are what keep the
collection navigable once it has thirty requests and several people editing it — a folder of
`Create order.bru` / `Get order by id.bru` with spaces and ad-hoc casing is the failure mode to avoid.

Follow `references/bru-syntax.md` for the block structure. Per request, aim for:

- A clear `meta { name }` in plain language ("Public webhook — verify handshake"), and a `seq` that
  orders the folder sensibly (setup/auth first, then the flow).
- The URL built from an environment variable base, never hardcoded per-request:
  `url: {{baseUrl}}/wp-json/whatsapp/v1/webhook`. This is what makes one collection work across
  local/staging/prod by just switching the environment.
- Auth pulled from a variable (`Bearer {{accessToken}}`), never a literal token.
- A `docs { }` block: a sentence on what the endpoint does and any gotchas. This is the payoff of
  versioning the collection — it becomes readable API documentation in review.
- Light `assert { }` (e.g. `res.status: eq 200`) so the request is self-checking when replayed. Keep
  assertions honest — only assert what the endpoint actually guarantees.

## Step 5 — Environments and secrets

Non-secret, per-environment values (base URLs, IDs, non-sensitive toggles) live in the
`environments/*.bru` files and **are committed** — they're configuration, not secrets, and they let a
teammate clone and run immediately.

Secrets (tokens, API keys, passwords) never sit in a `.bru` file. Put them in `bruno/.env` (auto-loaded
by Bruno) and reference them with `{{process.env.NAME}}`. Commit a `.env.example` listing every required
key with empty or placeholder values so the required secrets are self-documenting.

```
# bruno/.env.example  (committed)
WA_ACCESS_TOKEN=
WA_VERIFY_TOKEN=

# bruno/.env  (git-ignored, real values)
WA_ACCESS_TOKEN=EAAG...real...
WA_VERIFY_TOKEN=s3cr3t
```

An environment file then wires the secret into a variable once, and requests use the variable:

```
# environments/local.bru
vars {
  baseUrl: http://localhost:8080
  accessToken: {{process.env.WA_ACCESS_TOKEN}}
}
```

When you add a request that needs a new secret, add the key to **both** `.env` (with the real value, if
known) and `.env.example` (empty) in the same change — an example that drifts out of sync is worse than
none.

## Maintenance checklist (the recurring job)

When API code changes, the collection must follow. On every relevant change:

- Route added → add its `.bru` file in the right folder with docs + assert.
- Route removed → delete its `.bru` file (don't leave dead requests that 404).
- Path / method / params changed → update the matching request; don't create a duplicate.
- New secret or base URL → update `environments/` and `.env.example` (and `.gitignore` if a new secret
  file appears).
- Verify nothing sensitive leaked into a committed file: grep the tree for real token-looking strings
  before finishing. `bruno/.env` staying untracked is the invariant to protect.

Keep the collection a faithful mirror, not a superset: a request that no longer maps to real code is a
trap for whoever replays it.

## Out of scope (for now)

Running the collection in CI via `@usebruno/cli` (`bru run`) is intentionally not covered here yet —
this skill is about the folder's structure and upkeep. If the user asks for CI smoke-tests, flag that
it's a natural next step but a separate concern.
