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

**Setup is `docker compose up -d` and nothing else.** `compose.yml` is committed
and self-contained — no override file, no `.env`, and no
`config/settings/development.local.yml`, because the committed defaults already
match the ports it publishes (§3.2).

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
  │  fits :8081   (chrome, memcached optional)    │
  └───────────────────────────────────────────────┘
```

The app keeps using **sqlite3** at `db/development.sqlite3`. There is no
`postgres` service — it was removed, not just left stopped (§2.6).

Because Rails runs on the host, every service you need must publish a port to
`127.0.0.1`. Container-to-container DNS names (`solr`, `fcrepo`, `redis`) are
unreachable from the host, which is the root cause of most items in §2.

---

## 2. What Was Changed in `compose.yml`, and Why

`compose.yml`, `Dockerfile`, `.env`, and `docker.env` were imported verbatim
from upstream **Hyrax 5.3's `dassie` test app** (commits `9ab6ecf3`,
`d56eb509`) as a *starting point*. That app is not this app, and used as-is the
stack does not work.

`compose.yml` has since been **edited in place** to describe this app.
`.env`, `docker.env`, and `Dockerfile` were **deleted** — see §2.5 and §2.6 for
why none of them was salvageable. There is no `compose.override.yml`; the one
committed file is the whole configuration.

This section is the rationale for each edit, kept because the reasoning is not
recoverable from the file and every item was confirmed by running it.

### 2.1 Solr 9.9 cannot load this app's schema — hard failure

Upstream pinned `solr:9.9`; it is now `solr:8.11`. The app's
`solr/config/schema.xml` uses `solr.LatLonType`, removed in Solr 9:

```
Could not load conf for core testcore: Can't load schema schema.xml:
Plugin init failure for [schema.xml] fieldType "location":
Error loading class 'solr.LatLonType'
```

The schema also uses `solr.Trie*` field types (deprecated in 7, removed in 9)
and declares `<luceneMatchVersion>5.0.0</luceneMatchVersion>`.

Tested: **Solr 8.11 loads this config cleanly** — `"initFailures":{}`, core
queryable, HTTP 200. `compose.yml` therefore pins 8.11, because it needs no
code or config change at all.

That said, the Solr 9 fix turned out to be much smaller than expected — a
45-line patch to `schema.xml` and nothing else. See §10 for the verified
migration, including the one way it can fail silently.

### 2.2 Solr cores were the wrong names, from an empty directory

Upstream precreated `hyrax`, `hyrax_test`, `hyrax-valkyrie-dev`,
`hyrax-valkyrie-test` from `.dassie/solr`. But:

- The app wants **`deepbluedata-dev`** (`config/settings/development.yml`).
- `.dassie/solr/` **is empty** — the real config is in `solr/config/`.
  (`solr/conf/` is an unused Blacklight leftover; don't mount it.)
- `.dassie/` is untracked, so it never existed here in the first place.

Run unmodified, every core failed:

```
"initFailures":{
  "hyrax":"... Error loading solr config from /var/solr/data/hyrax/conf/solrconfig.xml",
  "hyrax_test":"...", "hyrax-valkyrie-dev":"...", "hyrax-valkyrie-test":"..."
}
```

The `hyrax-valkyrie-*` cores are meaningless here anyway — this app is
ActiveFedora, not Valkyrie. Now: one core, `deepbluedata-dev`, from
`./solr/config`.

Also note `SOLR_MODULES=analysis-extras,extraction` is **required**, not
optional: `schema.xml` uses `solr.ICUTokenizerFactory` and
`solr.ICUFoldingFilterFactory` in its `string` and `text_en` types.

### 2.3 Redis published no host port, and demanded a password

The upstream `redis` service declared no `ports:`, so the host could not reach
it at all (`Errno::ECONNREFUSED`). It also inherited `REDIS_PASSWORD=sidekickin`
from `.env`, so it demanded auth:

```
$ redis-cli ping
NOAUTH Authentication required.
```

The app passes `Settings.redis.to_h` straight into `Redis.new`
(`config/initializers/redis_config.rb`), and `config/settings.yml` sets **no**
password — so the password was pure friction, existing only because `.env` set
it.

With `.env` deleted, the fix is `ALLOW_EMPTY_PASSWORD=yes` rather than
re-introducing the password. The Bitnami image refuses to start with an unset
password otherwise (`The REDIS_PASSWORD environment variable is empty or not
set`). Verified: `redis-cli ping` → `PONG`, no credentials, and the app connects
on `config/settings.yml` defaults alone.

**This is what removes the need for a settings override entirely** — see §3.2.

While confirming this, one more upstream bug surfaced: the volume was mounted at
`/bitnamilegacy/redis/data`, **a path that does not exist in the image**, so it
persisted nothing. It is now `/bitnami/redis/data`, verified by writing a key,
restarting the service, and reading it back.

### 2.4 Fedora was on the wrong port (the REST path was already right)

Upstream mapped `8080:8080`; the app expects **8984**
(`config/settings/development.yml`), so it is now `8984:8080`. Probing
`ghcr.io/samvera/fcrepo4:4.7.5`:

```
/rest         => 200
/fedora/rest  => 404
```

So `/rest` is correct — matching `Settings.fedora.url`. (Upstream `.env` set
`VALKYRIE_FCREPO_URL=...@fedora6:8080/fcrepo/rest`, a Fedora 6 path for a
service that was never in this compose file — one of several reasons the file
was deleted rather than adapted.)

Note the image needs **~40 s** to boot. Don't conclude it's broken at 10 s.

### 2.5 Why `.env` and `docker.env` were deleted, not adapted

Both files were byte-identical (verified) and described dassie:
`BUNDLE_GEMFILE=Gemfile.dassie` (no such file), `RAILS_ROOT=.dassie`,
`APP_NAME=dassie`, Sidekiq settings for an app that uses Resque.

The sharpest edge was `DATABASE_URL=postgresql://...`, which always overrides
`database.yml`. With the `pg` gem absent from the bundle (`Gemfile:159` has it
commented out), Rails won't boot:

```
Error loading the 'postgresql' Active Record adapter.
pg is not part of the bundle. Add it to your Gemfile.
```

Nothing in these files was correct for this app, so there was nothing to keep.
The two values compose actually needed are now inline in `compose.yml`
(`SOLR_MODULES`, `ALLOW_EMPTY_PASSWORD`).

If you ever reintroduce a `.env`, note it is loaded by compose *and* — via
RubyMine's EnvFile plugin — potentially by Rails, which is how `DATABASE_URL`
becomes a boot failure. `.env` is gitignored (`.gitignore:13`), so it would also
be invisible to the next developer.

### 2.5.1 `Dockerfile` was deleted

Its `hyrax-engine-dev` stage could not build as written: it expects
`Gemfile.dassie`, `.dassie`, and `.koppie`, none of which exist here. The only
consumers were the commented-out `web`/`worker` services, so deleting it broke
nothing — verified, `docker compose config` parses and the stack comes up.

It is recoverable from git history (`9ab6ecf3`) if a containerized worker is
ever pursued (§6, option C).

### 2.6 Services that were removed or made optional

| Service | Verdict |
|---|---|
| `postgres` | **Removed.** App is sqlite3; `pg` gem not bundled. |
| `web` / `worker` | **Removed.** Rails runs in the IDE; `worker` ran Sidekiq, and this app uses Resque (§6). |
| `memcached` | **Optional** (`profiles: ["optional"]`). `dalli` is bundled, but dev caching is `:null_store` unless `tmp/caching-dev.txt` exists. |
| `chrome` | **Optional** (`profiles: ["optional"]`). Specs use local Chrome (`spec/spec_helper.rb:477`); nothing reads `HUB_URL`. |
| `fits` | **Kept and published on 8081** — see §5. Still needs a code change to be reached. |

Deleting the definitions outright — rather than keeping them behind an "unused"
profile — is deliberate: they encoded dassie's architecture, and a stale
Sidekiq worker in the file is a trap for the next developer. Git history has
them if needed.

The `optional` profile means a bare `docker compose up -d` starts exactly the
four services this setup needs, and nothing else.

---

## 3. Setup

### 3.1 No setup files required

`compose.yml` is committed and self-contained. There is **no**
`compose.override.yml` and **no** `.env` — clone, then `docker compose up -d`.

This is a deliberate departure from the usual compose idiom of
"upstream file + local override." An override only earns its keep when the base
file must stay pristine for upstream merges; here the base file *was* the
problem, so it was edited directly and the upstream version left in git history.
One file, no merge semantics, nothing hidden in a gitignored `.env`.

If you do need machine-local changes (a different port, an extra service),
compose still merges `compose.override.yml` automatically — but nothing in the
standard setup requires it. Note it is **not** currently gitignored, so add it
to `.gitignore` before creating one you don't intend to share.

### 3.2 Point the app at the containers

**Nothing to do — the committed defaults already match.** Verified with no
`config/settings/development.local.yml` present at all:

```
SOLR   = http://127.0.0.1:8983/solr/deepbluedata-dev/
FEDORA = http://127.0.0.1:8984/rest/deepbluedata-dev
REDIS  = PONG
```

`config/settings/development.yml` already points at `127.0.0.1:8984/rest` and
`127.0.0.1:8983/solr/deepbluedata-dev`, and `config/settings.yml` gives redis
`localhost:6379` with no password. `compose.yml` was written to match those
ports, rather than adding a settings file to paper over a mismatch.

This is why §2.3 dropped the Redis password instead of configuring the app
around it: the password was the *only* thing that still required an override
file. Removing it made the override unnecessary, so a developer's port-mapping
config and their app config can no longer drift apart.

The database is untouched: sqlite3 at `db/development.sqlite3` keeps working and
your existing local data is preserved.

Two consequences worth knowing:

- **Switching back to native services** is now `docker compose stop` plus
  starting your local Solr/Fedora on the same ports — no file to move.
- **Running both at once** (containers *and* native services) will collide on
  8983/8984. Use the env hooks rather than editing settings:
  `SOLR_DEV_PORT` and `FCREPO_DEVELOPMENT_PORT` are already interpolated into
  `development.yml`, so `SOLR_DEV_PORT=8993 bundle exec rails s` repoints the app
  with no file changes. (That hook is exactly how the Solr 9 testing in §10 was
  done.)

### 3.3 Start the services

```zsh
docker compose up -d        # solr, fcrepo, redis, fits
docker compose ps
```

The `optional` profile keeps `chrome` and `memcached` out of a bare `up`; add
them explicitly if you need them:

```zsh
docker compose up -d chrome memcached
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
docker compose exec redis redis-cli ping
curl -s http://127.0.0.1:8081/fits/version; echo
```

Expect `"initFailures":{}`, `200`, `200`, `PONG`, `1.6.0`. Note `redis-cli`
needs **no** `-a` flag now (§2.3).

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

A full write/read round-trip was also verified against this stack — Solr
`add`/`query`/`delete`, and an `ActiveFedora::Base` `save!` / `exists?` /
`delete`.

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
| **EnvFile plugin** | **leave disabled.** `.env` is gone (§2.5); don't recreate one for Rails. |

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

**A. Pass the tool through (needs a one-line app change).**
`compose.yml` already publishes FITS on a stable **8081** (upstream left it
ephemeral), so the container side is done — verified
`curl http://127.0.0.1:8081/fits/version` → `1.6.0`.

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

Both read the same `config/settings.yml` redis defaults, so they reach the
containerized Redis automatically — no extra configuration, and no password
(§2.3). The worker can be debugged in RubyMine as a second configuration.
Resque web UI: `/data/resque`.

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
plus a test core in `compose.yml`, and invoking `rspec` directly instead of
`rake ci` — but `rake ci`'s wrapper lifecycle is what CI uses, so diverging
here risks passing locally and failing in CI. Keeping tests on the wrappers is
the lower-risk choice.

Note the ports don't collide: the wrappers use 8985/8986, the containers
8983/8984, so `rake ci` works with the stack running.

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
| `env file .env not found` | a service still has `env_file: .env` | remove it; `.env` was deleted (§2.5) |
| `initFailures` mentions `LatLonType` | using `solr:9.x` | stay on `solr:8.11` (§2.1), or patch the schema (§10) |
| Numeric/date filters return 0 hits, docs otherwise look fine | Point-field schema over a Trie-written index | reindex (§10.4) |
| `initFailures` for `hyrax*` cores | precreating from empty `.dassie/solr` | should not recur — `compose.yml` now precreates one core from `./solr/config` (§2.2) |
| `NOAUTH Authentication required` | a password crept back into the redis service | drop it; use `ALLOW_EMPTY_PASSWORD=yes` (§2.3) |
| `ECONNREFUSED` on 6379 | redis `ports:` missing | should not recur (§2.3) |
| Redis forgets everything on restart | volume at the nonexistent `/bitnamilegacy/...` | use `/bitnami/redis/data` (§2.3) |
| `pg is not part of the bundle` | a `.env` with `DATABASE_URL` is being loaded into Rails | don't recreate `.env`; keep EnvFile disabled (§2.5) |
| Fedora 404 on `/fedora/rest` | wrong path | use `/rest` (§2.4) |
| Fedora connection refused early | still booting (~40 s) | wait, don't debug |
| `error, no fits.sh` at boot | no local FITS | §5 |
| Port 8983/8984 already in use | native Solr/Fedora also running | stop one, or repoint via `SOLR_DEV_PORT` / `FCREPO_DEVELOPMENT_PORT` (§3.2) |
| Objects vanished | ran `down -v` | §3.5 |

---

## 9. Follow-Ups

### Done

1. ~~Commit `compose.override.yml`~~ — instead, `compose.yml` was **edited
   directly** and committed. The upstream dassie version is in git history
   (`9ab6ecf3`); §2 records what changed and why. No override file exists.
2. ~~Delete `.env` / `docker.env`~~ — **deleted.** Both were byte-identical
   dassie config, and `DATABASE_URL` alone stopped Rails booting (§2.5). The two
   variables compose genuinely needed are now inline.
3. ~~Prune `compose.yml`~~ — **done.** `postgres`, `web`, and the Sidekiq
   `worker` are gone; the dassie/valkyrie cores are replaced by a single
   `deepbluedata-dev` from `./solr/config`; `chrome` and `memcached` moved
   behind an `optional` profile.
4. ~~Reconsider `Dockerfile`~~ — **deleted** (§2.5.1). Its only consumers were
   the removed `web`/`worker` services, and it could not build as written.

Two upstream bugs were fixed along the way that were not in the original list:
the redis volume pointed at a path absent from the image (persisting nothing),
and FITS had no stable published port.

### Still open

1. **Decide on `ch12n_tool: :fits_servlet`** (§5) so characterization works in
   dev. The container side is ready on 8081; this is a one-line app change that
   affects production too, so it needs a team decision.
2. **Do the Solr 9 schema migration** — Solr 8.11 is already EOL, and the change
   is a 45-line `schema.xml` patch that also still works on 8.11, so it can land
   before the image bump. Fully specified and verified in §10. Requires a full
   reindex (§10.4).
3. **Consider gitignoring `compose.override.yml`** if developers start keeping
   machine-local variations; it is currently not ignored (§3.1).

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
  `compose.yml`) provides both. Confirmed not by the absence of errors but by
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
3. Bump `compose.yml` to `solr:9.9`, recreate the core, reindex again (the
   volume is new).
4. Spot-check what silent failure would hit first: a numeric/date range facet,
   a date sort, and a geospatial search if used.
5. Only then consider `luceneMatchVersion`, as its own change with its own
   reindex.
