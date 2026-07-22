# Bru markup reference

Bruno stores each request, folder, environment and the collection root as plain-text `.bru` files.
The markup is a set of named blocks. Block names are exact — an unknown block is silently ignored by
the Bruno app, which is the usual cause of "my request doesn't work but there's no error".

## Table of contents

1. Collection manifest (`bruno.json`)
2. Collection-level file (`collection.bru`)
3. Folder file (`folder.bru`)
4. Request file (annotated)
5. Block catalog
6. Environment file
7. Secrets / `.env` / `process.env`
8. Disabled keys and variable interpolation

---

## 1. Collection manifest — `bruno.json`

Sits at the collection root. Bruno needs it to recognize the folder as a collection.

```json
{
  "version": "1",
  "name": "my-project-api",
  "type": "collection",
  "ignore": [
    "node_modules",
    ".git",
    ".env"
  ]
}
```

- `version` is the Bruno format version, currently `"1"` (a string).
- `name` is the collection's display name in the app.
- `ignore` lists paths Bruno won't treat as requests. Keep `.env` here as well as in `.gitignore`.

## 2. Collection-level file — `collection.bru`

Optional. Holds headers/auth/vars/scripts shared by *every* request in the collection — the place to
define a default `Content-Type` or a collection-wide pre-request script. Same block syntax as a request
file, minus the HTTP method block.

```
headers {
  Content-Type: application/json
}

auth {
  mode: none
}
```

## 3. Folder file — `folder.bru`

Optional, one per folder. Gives the folder a name/sequence and can hold folder-scoped headers/auth/vars
that apply to requests inside it.

```
meta {
  name: Exposed API
  seq: 1
}
```

## 4. Request file (annotated)

One file per (endpoint, method), e.g. `exposed/webhook-verify.bru`:

```
meta {
  name: Public webhook — verify handshake
  type: http
  seq: 1
}

get {
  url: {{baseUrl}}/wp-json/whatsapp/v1/webhook
  body: none
  auth: none
}

query {
  hub.mode: subscribe
  hub.verify_token: {{verifyToken}}
  hub.challenge: 1234
}

headers {
  Accept: application/json
}

assert {
  res.status: eq 200
}

tests {
  test("echoes the challenge", function() {
    expect(res.getBody()).to.equal("1234");
  });
}

docs {
  Meta calls this GET during webhook subscription. It must echo `hub.challenge`
  verbatim when `hub.verify_token` matches the configured token.
}
```

A POST with a JSON body:

```
meta {
  name: Send template message
  type: http
  seq: 2
}

post {
  url: {{baseUrl}}/messages
  body: json
  auth: bearer
}

auth:bearer {
  token: {{accessToken}}
}

body:json {
  {
    "to": "{{testNumber}}",
    "type": "template",
    "template": { "name": "hello_world" }
  }
}

assert {
  res.status: eq 200
}
```

## 5. Block catalog

| Block | Purpose |
|-------|---------|
| `meta { }` | `name`, `type: http`, `seq`, optional `tags: [ ... ]`. Required. |
| `get`/`post`/`put`/`patch`/`delete`/`head`/`options { }` | The method block: `url`, `body`, `auth`. Exactly one per request. |
| `query { }` | URL query parameters (key: value). |
| `params:path { }` | Path parameters for `:id`-style URLs. |
| `headers { }` | Request headers. |
| `auth:bearer { token: ... }` | Bearer token auth. Referenced by `auth: bearer` in the method block. |
| `auth:basic { username / password }` | Basic auth. |
| `auth:apikey { key / value / placement }` | API-key auth (header or query). |
| `body:json { }` | Raw JSON body. Other forms: `body:text`, `body:xml`, `body:form-urlencoded { }`, `body:multipart-form { }`, `body:graphql { }`. Match the `body:` in the method block. |
| `script:pre-request { }` | JS run before the request (set vars, sign requests). |
| `script:post-response { }` | JS run after the response (extract tokens into vars). |
| `assert { }` | Declarative checks: `res.status: eq 200`, `res.body.id: isDefined`. |
| `tests { }` | JS assertions using `expect(...)` / `res.getStatus()` / `res.getBody()`. |
| `vars:pre-request { }` / `vars:post-response { }` | Capture/compute variables around the call. |
| `docs { }` | Markdown documentation, shown in the app. Use it generously. |

The value after `body:` and `auth:` in the method block selects which body/auth block applies
(`body: json` ↔ `body:json { }`, `auth: bearer` ↔ `auth:bearer { }`). Mismatched names = ignored.

## 6. Environment file — `environments/<name>.bru`

Non-secret, per-environment configuration. Committed to git.

```
vars {
  baseUrl: https://staging.example.com
  verifyToken: {{process.env.WA_VERIFY_TOKEN}}
  accessToken: {{process.env.WA_ACCESS_TOKEN}}
  testNumber: +15550000000
}
```

- Plain values (`baseUrl`, `testNumber`) are configuration — safe to commit.
- Secret-derived values pull from `process.env` so the secret itself never lands in the file.
- Bruno also supports a `vars:secret [ name ]` block, which keeps a value out of the file and in
  Bruno's local store. It works, but `process.env` + `.env` is preferred here because it is explicit,
  reviewable, and CI-friendly.

## 7. Secrets — `.env` and `process.env`

Bruno auto-loads a `.env` file at the collection root and exposes its keys as `process.env`.

```
# bruno/.env  (GIT-IGNORED)
WA_ACCESS_TOKEN=EAAG...
WA_VERIFY_TOKEN=s3cr3t
```

Reference anywhere a variable is allowed with `{{process.env.WA_ACCESS_TOKEN}}`. Always ship a committed
`bruno/.env.example` with the same keys and empty values so required secrets are discoverable. Add
`bruno/.env` to `.gitignore`.

## 8. Disabled keys and interpolation

- A key prefixed with `~` in a dictionary block is **disabled** (present but not sent) — handy for
  keeping an optional header documented without enabling it:
  ```
  headers {
    Content-Type: application/json
    ~X-Debug: 1
  }
  ```
- `{{variable}}` interpolates a variable from (in increasing precedence) collection vars → folder vars →
  environment vars → runtime vars. `{{process.env.NAME}}` reads a `.env` / process value.
