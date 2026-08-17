# UM_IDE_DEV.md — Docker Compose Services + Rails in RubyMine

Target setup: **backing services in Docker Compose, the Rails app in the
RubyMine debugger on the host.** You get real breakpoints, no container
rebuild on code change, and the derivative/characterization tooling that the
host is missing.

For the current all-native setup, see [UM_DEV.md](UM_DEV.md).

Everything in §3–§5 was verified end-to-end on this machine: Rails booted
against the containerized stack, wrote a `DataSet` to Fedora, read it back,
confirmed it indexed in Solr, and eradicated it. §2 documents what had to
change to get there, and why.

---

## 1. Architecture

```
  ┌──────────────── host (macOS) ─────────────────┐
  │  RubyMine ── Rails (debugger) ── :3000        │
  │      └── Resque worker (optional, §6)         │
  └───────────────────┬───────────────────────────┘
                      │ 127.0.0.1 published ports
  ┌───────────────────┴───────── docker compose ──┐
  │  solr :8983   fcrepo :8984   redis :6379      │
  │  fits :<dyn>  (chrome, memcached optional)    │
  └───────────────────────────────────────────────┘
```

The app keeps using **sqlite3** at `db/development.sqlite3`. The `postgres`
service stays down — see §2.

Because Rails runs on the host, every service you need must publish a port to
`127.0.0.1`. Container-to-container DNS names (`solr`, `fcrepo`, `redis`) are
unreachable from the host, which is the root cause of most items in §2.

---

## 2. Why `compose.yml` Needs an Override

`compose.yml`, `Dockerfile`, `.env`, and `docker.env` were imported verbatim
from upstream **Hyrax 5.3's `dassie` test app** (commits `9ab6ecf3`,
`d56eb509`). That app is not this app. Used as-is, the stack does not work.

Each item below is confirmed, not theoretical.

### 2.1 Solr 9.9 cannot load this app's schema — hard failure

`compose.yml` pins `solr:9.9`. The app's `solr/config/schema.xml` uses
`solr.LatLonType`, removed in Solr 9:

```
Could not load conf for core testcore: Can't load schema schema.xml:
Plugin init failure for [schema.xml] fieldType "location":
Error loading class 'solr.LatLonType'
```

The schema also uses `solr.Trie*` field types (deprecated in 7, removed in 9)
and declares `<luceneMatchVersion>5.0.0</luceneMatchVersion>`.

Tested: **Solr 8.11 loads this config cleanly** — `"initFailures":{}`, core
queryable, HTTP 200. Solr 8.11 is the override's choice, because it needs no
code or config change at all.

That said, the Solr 9 fix turned out to be much smaller than expected — a
45-line patch to `schema.xml` and nothing else. See §10 for the verified
migration, including the one way it can fail silently.

### 2.2 Solr cores are the wrong names, from an empty directory

`compose.yml` precreates `hyrax`, `hyrax_test`, `hyrax-valkyrie-dev`,
`hyrax-valkyrie-test` from `.dassie/solr`. But:

- The app wants **`deepbluedata-dev`** (`config/settings/development.yml`).
- `.dassie/solr/` **is empty** — the real config is in `solr/config/`.
- `.dassie/` is untracked; only `docker.env`, `compose.yml`, `Dockerfile` are committed.

Running `compose.yml` unmodified, every core fails:

```
"initFailures":{
  "hyrax":"... Error loading solr config from /var/solr/data/hyrax/conf/solrconfig.xml",
  "hyrax_test":"...", "hyrax-valkyrie-dev":"...", "hyrax-valkyrie-test":"..."
}
```

The `hyrax-valkyrie-*` cores are meaningless here anyway — this app is
ActiveFedora, not Valkyrie.

### 2.3 Redis publishes no host port, and requires a password

The `redis` service declares no `ports:`, so the host cannot reach it at all
(`Errno::ECONNREFUSED`). It also inherits `REDIS_PASSWORD=sidekickin` from
`.env`, so it demands auth:

```
$ redis-cli ping
NOAUTH Authentication required.
$ redis-cli -a sidekickin ping
PONG
```

The app passes `Settings.redis.to_h` straight into `Redis.new`
(`config/initializers/redis_config.rb`), and `config/settings.yml` sets no
password. Two things must change: publish 6379, and give the app the
password.

> Beware: `env_file: [.env]` on the redis service is load-bearing. Removing it
> to drop the password makes the Bitnami image **refuse to start** —
> `The REDIS_PASSWORD environment variable is empty or not set` — unless you
> also set `ALLOW_EMPTY_PASSWORD=yes`. Keep the password; configure the app.

### 2.4 Fedora is on the wrong port with the wrong REST path

`compose.yml` maps `8080:8080`; the app expects **8984**
(`config/settings/development.yml`). Probing `ghcr.io/samvera/fcrepo4:4.7.5`:

```
/rest         => 200
/fedora/rest  => 404
```

So `/rest` is correct — matching `Settings.fedora.url`. But `.env` sets
`VALKYRIE_FCREPO_URL=...@fedora6:8080/fcrepo/rest`, a Fedora 6 path for a
service that isn't in this compose file. Ignore it.

Note the image needs **~40 s** to boot. Don't conclude it's broken at 10 s.

### 2.5 `.env` actively breaks the app — do not load it

`.env` and `docker.env` are byte-identical (verified) and describe dassie:
`BUNDLE_GEMFILE=Gemfile.dassie` (no such file), `RAILS_ROOT=.dassie`,
`APP_NAME=dassie`, Sidekiq settings for an app that uses Resque.

The sharpest edge is `DATABASE_URL=postgresql://...`, which always overrides
`database.yml`. With the `pg` gem absent from the bundle (`Gemfile:159` has it
commented out), Rails won't boot:

```
Error loading the 'postgresql' Active Record adapter.
pg is not part of the bundle. Add it to your Gemfile.
```

**Never source `.env` into your Rails run configuration.** Compose may use it
for the service containers; the app must not.

### 2.6 Services you don't need

| Service | Verdict |
|---|---|
| `postgres` | **Skip.** App is sqlite3; `pg` gem not bundled. |
| `web` / `worker` | Already commented out — intentional; Rails runs in the IDE. |
| `memcached` | Optional. `dalli` is bundled, but dev caching is `:null_store` unless `tmp/caching-dev.txt` exists. |
| `chrome` | Optional. Specs use local Chrome (`spec/spec_helper.rb:477`); nothing reads `HUB_URL`. |
| `fits` | **Useful** — see §5. Needs a code change to be reached. |

---

## 3. Setup

### 3.1 Add the override file

Compose merges `compose.override.yml` automatically. Create it at the repo
root — this is the exact configuration verified working:

```yaml
# compose.override.yml — adapts upstream dassie compose.yml to DeepBlue
services:
  solr:
    # 8.11, not 9.x: schema.xml uses solr.LatLonType, removed in Solr 9
    image: solr:8.11
    env_file: !reset []          # .env's dassie vars are wrong for this app
    environment:
      - SOLR_MODULES=analysis-extras,extraction
    ports:
      - "8983:8983"
    command:
      - sh
      - "-c"
      - "solr-precreate deepbluedata-dev /opt/solr/server/configsets/dbdconf"
    volumes:
      - solr_home:/var/solr:cached
      - ./solr/config:/opt/solr/server/configsets/dbdconf:ro

  fcrepo:
    ports: !override
      - "8984:8080"              # app expects 8984

  redis:
    ports:
      - "6379:6379"              # upstream publishes nothing
    # keep env_file: .env — Bitnami image needs REDIS_PASSWORD set

  postgres:
    profiles: ["unused"]         # app is sqlite3; pg gem not bundled
```

`!reset` and `!override` need Compose v2.24+. You have v5.4.0.

The `profiles: ["unused"]` line keeps `postgres` from starting with a bare
`docker compose up`, without deleting the definition.

### 3.2 Point the app at the containers

Fedora and Redis have **no full-URL environment override** (see UM_DEV.md §7),
so this must go in a settings file. Create
`config/settings/development.local.yml` — gitignored, per
`.gitignore:86`:

```yaml
# Docker Compose services published on localhost.
fedora:
  url: http://127.0.0.1:8984/rest
  base_path: /deepbluedata-dev

solr:
  url: http://127.0.0.1:8983/solr/deepbluedata-dev

redis:
  host: 127.0.0.1
  port: 6379
  password: sidekickin      # matches REDIS_PASSWORD in .env
  thread_safe: true
```

This is the whole integration. Note it deliberately leaves the database
alone — sqlite3 at `db/development.sqlite3` continues to work, and your
existing local data is preserved.

Switching back to native services is then just `mv` on this one file.

### 3.3 Start the services

```zsh
docker compose up -d solr fcrepo redis fits
docker compose ps
```

Solr needs ~30 s, Fedora ~40 s. Wait on readiness rather than guessing:

```zsh
until curl -sf "http://127.0.0.1:8983/solr/deepbluedata-dev/select?q=*:*" >/dev/null; do sleep 3; done
until curl -sf "http://127.0.0.1:8984/rest" >/dev/null; do sleep 3; done
echo "services ready"
```

### 3.4 Verify before involving the IDE

```zsh
# Solr: no init failures, core queryable
curl -s "http://127.0.0.1:8983/solr/admin/cores?action=STATUS" | grep -o '"initFailures":{[^}]*}'
curl -s -o /dev/null -w "solr:   %{http_code}\n" "http://127.0.0.1:8983/solr/deepbluedata-dev/select?q=*:*"
curl -s -o /dev/null -w "fcrepo: %{http_code}\n" http://127.0.0.1:8984/rest
docker compose exec redis redis-cli -a sidekickin ping
```

Expect `"initFailures":{}`, `200`, `200`, `PONG`.

Then confirm the app agrees:

```zsh
bundle exec rails runner 'puts "SOLR=#{ActiveFedora::SolrService.instance.conn.uri}"; puts "FEDORA=#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}"; puts "REDIS=#{Resque.redis.redis.ping}"'
```

Verified output:

```
SOLR=http://127.0.0.1:8983/solr/deepbluedata-dev/
FEDORA=http://127.0.0.1:8984/rest/deepbluedata-dev
REDIS=PONG
```

### 3.5 Bootstrap a fresh repository

Compose volumes start empty, so a new Fedora/Solr has no content even though
sqlite3 still holds your users. If Fedora is empty, redo UM_DEV.md §2:

```zsh
bundle exec rails db:migrate
bundle exec rake hyrax:default_collection_types:create
```

then recreate the admin sets and repeat the **manual UI steps** (default admin
set → Allow Everyone to Deposit → mediated; `Draft works Admin Set` → draft).
Skipping these produces confusing deposit failures later.

---

## 4. RubyMine Configuration

The project already has a `deepblue` Rails run configuration
(`RailsRunConfigurationType`), so you likely only need to check its
environment.

**Run/Debug Configurations → `deepblue` (Rails):**

| Field | Value |
|---|---|
| Ruby SDK | 3.3.10 (host interpreter — *not* a Docker interpreter) |
| Environment | `RAILS_ENV=development` |
| Port | 3000 |
| **EnvFile plugin** | **leave disabled — do not load `.env`** (§2.5) |

Keep this a **local** interpreter. Do not switch RubyMine to a Docker Compose
remote interpreter: that would put the app back in a container, requiring path
mappings and rebuilds, and defeat the purpose of this setup.

Then: **Debug `deepblue`**, set breakpoints, open
**`http://localhost:3000/data`**.

Remember the app is mounted at `/data` (`config/application.rb:324`);
`http://localhost:3000/` alone will not do what you want.

### Debugging notes

- Because dev jobs run **in-process** on the Async adapter (§6), breakpoints
  inside `ActiveJob` classes hit in the same debugger session. This is a real
  advantage over running a separate worker.
- Turn off `spring` for predictable debugging — `DISABLE_SPRING=1`. Spring's
  preloader forks, which produced confusing stack traces during testing.
- Verbose logging is available without editing code: many services expose
  `*_debug_verbose` flags (e.g. `CharacterizeJob.characterize_job_debug_verbose`).

---

## 5. File Characterization (FITS)

The host has no `fits.sh`, so characterization currently fails in both setups
— the app logs `error, no fits.sh` at boot (UM_DEV.md §6).

The `fits` container works. Verified:

```
FITS version: 1.6.0
$ curl -F "datafile=@README.md" http://127.0.0.1:<port>/fits/examine
<fits ... version="1.6.0"> <identification status="CONFLICT"> ...
```

**But the app will not use it without a code change.** The chain:

- `app/helpers/deepblue/ingest_helper.rb:89` calls
  `Hydra::Works::CharacterizationService.run(proxy, file_name)` with **no
  options**.
- `hydra-works-2.2.0` defaults `@tools = options.fetch(:ch12n_tool, :fits)`,
  i.e. the local binary.
- `hydra-file_characterization-1.2.0` *does* ship a `FitsServlet`
  characterizer that posts to `ENV['FITS_SERVLET_URL']/examine`.
- Nothing in this app sets `ch12n_tool` — `grep -rn "ch12n_tool" app/ lib/ config/`
  returns nothing. Hyrax's own `CH12N_TOOL` env var is only read by
  `Hyrax::Characterization::ValkyrieCharacterizationService`, which this
  ActiveFedora app doesn't use.

So there are two honest options:

**A. Publish a stable FITS port and pass the tool through (needs a change).**
In the override:

```yaml
  fits:
    ports: !override
      - "8081:8080"
```

Set `FITS_SERVLET_URL=http://127.0.0.1:8081/fits` in the run configuration,
then change `ingest_helper.rb:89` to:

```ruby
Hydra::Works::CharacterizationService.run( proxy, file_name, ch12n_tool: :fits_servlet )
```

This is a one-line app change and should be discussed with the team before
committing — it alters production behavior too.

**B. Accept no characterization in dev.** Ingest still completes;
`IngestHelper.characterize` rescues and logs the failure. Fine unless you are
working on characterization or FITS metadata.

Without publishing a fixed port, `fits` gets an ephemeral one — find it with
`docker compose port fits 8080`.

### Derivatives are still host-limited

Docker fixes characterization but **not** derivatives. Thumbnails,
transcoding, Office/PDF conversion, and OCR run in-process on the host, where
`convert`, `ffmpeg`, `soffice`, `exiftool`, `pdftotext`, `gs`, `mediainfo`,
and `tesseract` are all missing. Either `brew install` them, or accept that
derivative generation fails in dev. Running the *worker* in a container is the
other way out — see §6, option C.

---

## 6. Where to Run Background Workers

You flagged this as undecided. Here is what the code actually dictates.

**In development today, no worker process is needed.** Verified:

```
ActiveJob adapter = ActiveJob::QueueAdapters::AsyncAdapter
Resque.inline     = false
```

`config/environments/development.rb:92` leaves the Resque adapter commented
out, noting it "does not work in dev due to a bug." Jobs run on Async's
in-process thread pool. `config/resque-pool.yml` and its 13 queues are inert
in dev; Resque is the **production** adapter
(`config/environments/production.rb:78`).

The commented-out `worker` service in `compose.yml` would run
`bundle exec sidekiq` — **wrong for this app entirely.** Do not uncomment it.

### Option A — Async in-process (recommended default)

Change nothing. Jobs run inside the Rails process you're debugging.

- Breakpoints in jobs work in the same session; simplest possible setup.
- Queues aren't durable — a restart drops in-flight jobs.
- Doesn't exercise the Resque path that production uses.

Right for almost all feature work.

### Option B — Resque worker on the host

When you need real queueing, `resque-scheduler`, or the Resque web UI:

1. Uncomment `config.active_job.queue_adapter = :resque` in
   `config/environments/development.rb`.
2. Add a RubyMine run configuration, or run in a terminal:

```zsh
QUEUE=* bundle exec rake resque:work
# or the full pool:
bundle exec resque-pool --daemon --environment development
```

Both read the same `development.local.yml`, so they reach the containerized
Redis automatically. The worker can be debugged in RubyMine as a second
configuration. Resque web UI: `/data/resque`.

Note the upstream `-dev.rb` comment about the adapter being buggy in dev — if
you hit odd behavior with option B, that warning is why, and option A is the
fallback.

### Option C — Worker in a container

Possible but **not recommended now**. It would need a Dockerfile change
(current stages install Sidekiq-oriented entrypoints and expect
`Gemfile.dassie`, `.dassie`, and `.koppie` — and `.koppie` does not exist, so
the `hyrax-engine-dev` stage cannot build as written). It would also need the
sqlite file shared into the container, which is fragile, plus a Resque
entrypoint that upstream doesn't provide.

The one real draw: the image installs ffmpeg, LibreOffice, ImageMagick,
Tesseract, ClamAV, and FITS — so a containerized worker would fix derivatives
(§5). If derivative work becomes a priority, this is the direction, and it is
a project in itself: switch the DB to PostgreSQL (add `pg`), write a Resque
entrypoint, and repoint paths off `.dassie`.

**Recommendation:** start with A, keep B for queue-specific work, and treat C
as a separate initiative.

---

## 7. Tests

`rake ci` is **independent of Docker**. `lib/tasks/ci.rake` starts its own
`solr_wrapper` on 8985 and `fcrepo_wrapper` on 8986 and still needs **Java 8**
on the host:

```zsh
./bin/dev-stack ci
```

You could point tests at containers by adding a `config/settings/test.local.yml`
plus test cores in the override, and invoking `rspec` directly instead of
`rake ci` — but `rake ci`'s wrapper lifecycle is what CI uses, so diverging
here risks passing locally and failing in CI. Keeping tests on the wrappers is
the lower-risk choice.

Single specs run fine either way:

```zsh
bundle exec rspec spec/path/to/thing_spec.rb
```

---

## 8. Operations

```zsh
docker compose ps                       # status + published ports
docker compose logs -f solr             # follow one service
docker compose restart fcrepo
docker compose stop                     # keep data
docker compose down                     # remove containers, keep volumes
docker compose down -v                  # DESTROY repository data (see below)
```

`docker compose down -v` deletes the `solr_home`, `fcrepo`, and `redis`
volumes — your entire local repository content. Your sqlite users/settings
survive (that's a host file), so you'll get a database referencing objects
Fedora no longer has. After a `-v`, redo §3.5.

### Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `initFailures` mentions `LatLonType` | Solr 9.x | override to `solr:8.11` (§2.1), or patch the schema (§10) |
| Numeric/date filters return 0 hits, docs otherwise look fine | Point-field schema over a Trie-written index | reindex (§10.4) |
| `initFailures` for `hyrax*` cores | precreating from empty `.dassie/solr` | override `command` + volume (§2.2) |
| `NOAUTH Authentication required` | Redis password | add `password: sidekickin` (§3.2) |
| `ECONNREFUSED` on 6379 | Redis publishes no port | add `ports:` (§2.3) |
| `pg is not part of the bundle` | `.env` loaded into Rails | don't load `.env` (§2.5) |
| Fedora 404 on `/fedora/rest` | wrong path | use `/rest` (§2.4) |
| Fedora connection refused early | still booting (~40 s) | wait, don't debug |
| `error, no fits.sh` at boot | no local FITS | §5 |
| Objects vanished | ran `down -v` | §3.5 |

---

## 9. Recommended Follow-Ups

Not required for this setup, but each removes a documented sharp edge:

1. **Commit `compose.override.yml`** so the team shares one working config.
2. **Delete or rename `.env` / `docker.env`.** They are dassie's, identical to
   each other, and actively break Rails if loaded. Committed `docker.env` is a
   trap for the next developer.
3. **Prune `compose.yml`** — drop the `hyrax-valkyrie-*` cores and the
   Sidekiq `worker` block, neither of which applies to this app.
4. **Decide on `ch12n_tool: :fits_servlet`** (§5) so characterization works
   in dev.
5. **Do the Solr 9 schema migration** — Solr 8.11 is already EOL, and the
   change is a 45-line `schema.xml` patch that also still works on 8.11, so it
   can land before the image bump. Fully specified and verified in §10.
6. **Reconsider `Dockerfile`.** Its `hyrax-engine-dev` stage cannot build as
   written (`.koppie` is absent, `Gemfile.dassie` doesn't exist). It is
   currently dead weight; fix it or remove it.

---

## 10. Solr 9 Migration (Verified)

§2.1 explains why the stack pins 8.11. This section is the follow-through: the
actual Solr 9 incompatibilities, found by running `solr:9.9` against this app's
config and fixing errors one at a time rather than auditing the schema by eye.

**Result: the only file that needs changing is `solr/config/schema.xml`, in a
45-line patch confined to field-type declarations.**

Note `solr/conf/` is a Blacklight leftover and is not used — only
`solr/config/` is mounted as the configset.

### 10.1 What actually had to change

| Original | Solr 9 replacement |
|---|---|
| `solr.TrieIntField` | `solr.IntPointField` |
| `solr.TrieFloatField` | `solr.FloatPointField` |
| `solr.TrieLongField` | `solr.LongPointField` |
| `solr.TrieDoubleField` | `solr.DoublePointField` |
| `solr.TrieDateField` | `solr.DatePointField` |
| `solr.LatLonType` | `solr.LatLonPointSpatialField` |

Add `docValues="true"`; drop `precisionStep` (meaningless for Point fields) and
`subFieldSuffix` (`LatLonPointSpatialField` needs no subfields). The `t*`
variants (`tint`, `tlong`, `tdate`, …) collapse onto the same Point classes —
Point fields make the separate "trie for faster ranges" types redundant, so the
two groups become identical.

The `*_coordinate` dynamic field is now unused by the `location` type, but it
is harmless and nothing references it.

### 10.2 What did NOT need changing

These were the expected problems that turned out to be non-issues:

- **`solrconfig.xml`: no changes at all.**
- **`<luceneMatchVersion>5.0.0</luceneMatchVersion>` is accepted by Solr 9.9.**
  It logs `using deprecated 5.0.0 emulation`, but the core loads and queries
  work. Bumping it is a *separate*, riskier change — it alters analysis
  behavior and needs its own reindex — so leave it alone in this patch.
- **`qt=search` still works.** `catalog_controller.rb:72` sets `qt: "search"`,
  and the handler is declared as `search` (no leading slash), so it is only
  reachable via the deprecated `handleSelect="true"`. Solr 9.9 logs
  `handleSelect is deprecated` but still honors it — verified HTTP 200 both
  directly and through the app's Solr connection.
- **`<lib/>` directives are disabled in Solr 9**, which logs a scary warning:

  ```
  Configset references one or more <lib/> directives, but <lib/> usage is
  disabled on this Solr node.
  ```

  Harmless here, because `SOLR_MODULES=analysis-extras,extraction` (already in
  the override) provides both. Confirmed not by the absence of errors but by
  checking ICU actually works — the `string` and `text_en` types both use
  `ICUTokenizerFactory`/`ICUFoldingFilterFactory`, and folding is live:

  ```zsh
  curl -s --get "$SOLR/analysis/field" \
    --data-urlencode "analysis.fieldtype=text_en" \
    --data-urlencode "analysis.fieldvalue=Straße café"
  # => tokens: strasse, cafe
  ```

- **`/update/extract` returns 400** on a plain `curl` upload — but it returns
  **the identical 400 on 8.11**, so it is a pre-existing schema gap, not a Solr
  9 regression. Nothing in the app posts to it.

### 10.3 The patched schema also works on 8.11

Verified: the patched `schema.xml` loads with `"initFailures":{}` and serves
queries on **both** `solr:8.11` and `solr:9.9`.

This decouples the two changes. The schema patch can be committed, reindexed,
and validated while still running 8.11, and the image bump becomes a separate
one-line change that can be reverted independently.

### 10.4 Reindexing is mandatory — and failure is silent

This is the part that will bite anyone who treats the patch as config-only.

Point fields use a different on-disk encoding than Trie fields. Verified by
writing documents under the Trie schema, swapping in the Point schema, and
reloading the core:

| Query against Trie-written data, Point schema | Result |
|---|---|
| exact match `file_size_ltsi:555` | **0 hits** |
| range `file_size_ltsi:[1 TO 9999]` | **0 hits** |
| stored-field retrieval (`fl=file_size_ltsi`) | works, returns `555` |

**No exception, no error, no `initFailures` — just zero results.** Because
stored fields still read back correctly, documents look intact in the UI while
numeric and date filtering, sorting, and range facets quietly return nothing.

Rewriting the same documents under the Point schema restored all matches
immediately. So after applying the patch:

```zsh
bundle exec rake deepblue:reindex_solr_now
```

Two testing traps that produce false confidence here:

- **`*_lts` and `*_lls` are `indexed="false"`** — stored-only by design, so
  they never match a query regardless of Solr version. Test with the indexed
  suffixes (`*_ltsi`, `*_llsim`) or you will "confirm" behavior that was never
  queryable.
- **`solr-precreate` copies the configset** to
  `/var/solr/data/<core>/schema.xml`. Editing the mounted configset and
  reloading the core changes nothing — check the live class before trusting a
  result:

  ```zsh
  curl -s "$SOLR/schema/fieldtypes/tlong" | grep -o '"class":"[^"]*"'
  ```

### 10.5 How this was verified

Against `solr:9.9`, with the app pointed at it via `SOLR_DEV_PORT` (which
`config/settings/development.yml` already interpolates — no file edits, no
`development.local.yml` needed):

```zsh
SOLR_DEV_PORT=8993 DISABLE_SPRING=1 bundle exec rails runner '...'
```

Confirmed through the app's own `ActiveFedora::SolrService`, not just raw curl:
`add` → `commit` → `query` round-trip on a Hyrax-shaped `DataSet` document;
sort on `system_create_dtsi`; facet on `visibility_ssi`; numeric range;
`qt=search`; `delete`. Plus, at the Solr level, `geofilt` against a
`*_llsim` field and ICU folding as shown above.

To reproduce, mount `solr/config` with the patch applied and precreate the core:

```zsh
docker run --rm -p 8993:8983 \
  -e SOLR_MODULES=analysis-extras,extraction \
  -v "$PWD/solr/config:/opt/solr/server/configsets/dbdconf:ro" \
  solr:9.9 sh -c "solr-precreate deepbluedata-dev /opt/solr/server/configsets/dbdconf"

curl -s "http://127.0.0.1:8993/solr/admin/cores?action=STATUS" | grep -o '"initFailures":{[^}]*}'
```

### 10.6 Suggested rollout

1. Apply the field-type patch to `solr/config/schema.xml`; leave
   `solrconfig.xml` and `luceneMatchVersion` untouched.
2. Commit and reindex **while still on 8.11** (§10.3) — this proves the patch
   and the reindex independently of the version bump.
3. Bump the override to `solr:9.9`, recreate the core, reindex again (the
   volume is new).
4. Spot-check what silent failure would hit first: a numeric/date range facet,
   a date sort, and a geospatial search if used.
5. Only then consider `luceneMatchVersion`, as its own change with its own
   reindex.
