# UM_DEV.md — Local Development (no Docker)

How DeepBlue development works **today**: every service runs natively on the
macOS host, started by `bin/dev-stack`. This is the baseline the app is
currently configured for — `config/settings/development.yml` points at
`127.0.0.1` for Fedora, Solr, and Redis, so no environment overrides are
needed.

For the Docker + RubyMine setup, see [UM_IDE_DEV.md](UM_IDE_DEV.md).

---

## 1. What This Stack Actually Is

Knowing the versions matters, because they are older than upstream Hyrax and
constrain what you can substitute.

| Component | Version | Notes |
|---|---|---|
| Ruby | 3.3.10 | pinned in `.ruby-version` |
| Rails | 6.1.7.10 | not Rails 7 |
| Hyrax | 5.0.1 | customized fork of behavior |
| Persistence | **ActiveFedora 14.0.1** | classic AF, *not* Valkyrie |
| Fedora | **4.7.x** | via `fcrepo_wrapper`, needs **Java 8** |
| Solr | **7.7.1** | via `solr_wrapper`, core `deepbluedata-dev` |
| Database | **sqlite3** | `db/development.sqlite3` |
| Background jobs | **Resque** | not Sidekiq |
| Bundler | 2.5.3 | gems vendored into `.bundle/` |

Two of these are load-bearing and easy to get wrong:

- **ActiveFedora, not Valkyrie.** `config/initializers/hyrax.rb` leaves
  `query_index_from_valkyrie` commented out. Valkyrie-era Hyrax instructions
  do not apply.
- **Resque, not Sidekiq.** `Gemfile` has `resque`, `resque-pool`,
  `resque-scheduler`; the `sidekiq` line at `Gemfile:166` is commented out.

### Service ports

| Service | Port | Health endpoint |
|---|---|---|
| Rails | 3000 | `http://localhost:3000/data` |
| Solr | 8983 | `http://127.0.0.1:8983/solr/` |
| Fedora | **8984** | `http://127.0.0.1:8984/rest` |
| Redis | 6379 | `redis-cli ping` |
| Solr (test) | 8985 | used only by `rake ci` |
| Fedora (test) | 8986 | used only by `rake ci` |

Note Fedora is on **8984**, not the conventional 8080. The app is at
`/data`, not `/` — `Settings.relative_url_root` is `/data`, applied in
`config/application.rb:324`.

---

## 2. One-Time Setup

### System dependencies

```zsh
brew install mysql libxml2 libxslt libiconv redis
brew install --cask temurin@8   # Java 8: required by Fedora 4.7.x
```

Java 8 is not optional. Fedora 4.7.x did not become healthy under Java 26;
`bin/dev-stack` pins `JAVA_HOME` to Java 8 when launching Fedora and when
running `rake ci`. Verify:

```zsh
/usr/libexec/java_home -v 1.8
```

### Gems

Native extensions need build flags on Apple Silicon. `.bundle/config` already
carries them:

```yaml
BUNDLE_BUILD__LIBXML___RUBY: "--with-xml2-config=/opt/homebrew/opt/libxml2/bin/xml2-config"
BUNDLE_BUILD__MYSQL2: "--with-ldflags=-L/opt/homebrew/opt/zstd/lib"
BUNDLE_BUILD__POSIX___SPAWN: "--with-cflags=-Wno-incompatible-function-pointer-types"
BUNDLE_BUILD__UNICODE: "--with-cflags=-Wno-incompatible-function-pointer-types"
BUNDLE_PATH: ".bundle"
BUNDLE_WITHOUT: "production"
```

If two gems fight the toolchain, install them explicitly first:

```zsh
gem install mysql2 -v '0.5.6' -- \
  --with-opt-dir="$(brew --prefix openssl@3)" \
  --with-ldflags=-L/opt/homebrew/opt/zstd/lib

gem install posix-spawn -- --with-cflags="-Wno-incompatible-function-pointer-types"

bundle install
```

> **Gemfile caveat.** `Gemfile` contains a block that shells out to
> `bundle config` based on the checkout path (the `gemfile_bundle_config`
> logic, ~lines 26–70). It is currently commented out at the call site. If
> Bundler starts rewriting `.bundle/config` unexpectedly, that block is why.

### Database and Hyrax bootstrap

```zsh
bundle exec rails db:migrate
bundle exec rake hyrax:default_collection_types:create
```

Create your user, then the default admin set:

```zsh
bundle exec rails runner "email='you@umich.edu'; u=User.find_or_initialize_by(email: email); if u.new_record?; pw=SecureRandom.urlsafe_base64(16); u.password=pw; u.password_confirmation=pw; u.save!; end"

bundle exec rails runner "owner=User.find_by(email: 'you@umich.edu'); raise 'owner_missing' unless owner; admin_set=Hyrax::AdministrativeSet.new(title: ['DataSet Admin Set']); Hyrax::AdminSetCreateService.new(admin_set: admin_set, creating_user: owner, default_admin_set: true).create!"
```

### Manual UI steps

These cannot be scripted and the app misbehaves without them. At
`http://localhost:3000/data`, in Dashboard → Collections:

1. Edit the default admin set → **Allow Everyone to Deposit** → workflow **mediated**.
2. Create an admin collection `Draft works Admin Set` → workflow **draft**.

---

## 3. Daily Workflow

```zsh
./bin/dev-stack start    # Redis, Fedora, Solr, Rails — idempotent
./bin/dev-stack status
```

`start` is safe to re-run; each step checks whether the port is already
serving before launching. What it does:

- **Redis** — `/opt/homebrew/opt/redis/bin/redis-server`
- **Fedora** — `fcrepo_wrapper` on 8984 with `JAVA_HOME` forced to Java 8
- **Solr** — `solr_wrapper` on 8983 with a `GC_TUNE` override, because Solr
  7.7.1's default startup scripts pass CMS GC flags that newer JVMs reject
- **Rails** — `rails server` on 3000

Expected healthy output:

```
Redis :6379 => up
Fedora :8984 /rest => HTTP 200
Solr   :8983 /solr/ => HTTP 200
Rails  :3000 /data => HTTP 200
```

A non-`000` code for Rails means it is up; `302` is normal (auth redirect).

### Manual health checks

```zsh
curl -sS -o /dev/null -w "Fedora: %{http_code}\n" http://127.0.0.1:8984/rest
curl -sS -o /dev/null -w "Solr:   %{http_code}\n" http://127.0.0.1:8983/solr/
curl -sS -o /dev/null -w "Rails:  %{http_code}\n" http://127.0.0.1:3000/data
/opt/homebrew/opt/redis/bin/redis-cli ping
```

### Logs

`bin/dev-stack` runs everything under `nohup`, so output goes to files, not
your terminal:

```zsh
tail -f log/rails-server.out
tail -f log/fcrepo_wrapper.out
tail -f log/solr_wrapper.out
tail -f log/redis-server.out
```

### Stopping

`bin/dev-stack` has no `stop` command — it only exposes `start`, `status`,
and `ci`. Stop things by port:

```zsh
lsof -iTCP:3000 -sTCP:LISTEN -t | xargs kill   # Rails
lsof -iTCP:8984 -sTCP:LISTEN -t | xargs kill   # Fedora
tmp/solr-development/bin/solr stop -p 8983     # Solr — use its own script
```

Stop Solr with its own script rather than `kill`, so cores are unregistered
cleanly. An abrupt kill is the usual cause of a corrupt dev index.

---

## 4. Background Jobs

In development, **no separate worker process is required.** Verified at
runtime:

```
ActiveJob adapter = ActiveJob::QueueAdapters::AsyncAdapter
Resque.inline     = false
```

`config/environments/development.rb:92` leaves
`config.active_job.queue_adapter = :resque` commented out, with a note that
it "does not work in dev due to a bug." So jobs run **in-process** on Async's
thread pool inside the Rails process.

Consequences worth internalizing:

- Jobs execute in your Rails process — you can breakpoint them directly.
- Queues are **not durable**. Restarting Rails drops anything in flight.
- Resque queue names in `config/resque-pool.yml` are inert in development.
- `Resque.inline` is `true` only in test (`config/initializers/resque_config.rb:11`).

Redis still must be running: `redis_config.rb` and `resque_config.rb`
initialize clients at boot, and Hyrax uses Redis for locking under namespace
`deepbluedata-dev`.

### Exercising Resque for real

Only if you are specifically working on queueing or `resque-scheduler`:

1. Uncomment `config.active_job.queue_adapter = :resque` in
   `config/environments/development.rb`.
2. Run a worker:

```zsh
QUEUE=* bundle exec rake resque:work
# or the full pool from config/resque-pool.yml:
bundle exec resque-pool --daemon --environment development
```

Resque web UI is mounted at `/data/resque` (`config/routes.rb:272`).

---

## 5. Tests

```zsh
./bin/dev-stack ci
```

This wraps `bundle exec rake ci` with Java 8 and cleans up first, which
matters: `rake ci` (`lib/tasks/ci.rake`) starts its **own** Solr on 8985 and
Fedora on 8986 from `config/solr_wrapper_test.yml` and
`config/fcrepo_wrapper_test.yml`. It does not reuse your dev services.

`bin/dev-stack ci` additionally kills orphaned test services and removes
`tmp/solr-test/server/solr/deepbluedata-test`. The test core is configured
`persist: false`, but an aborted run leaves it behind, and the next run then
fails.

Single specs against the dev stack:

```zsh
bundle exec rspec spec/path/to/thing_spec.rb
```

Feature specs use local Chrome via `Capybara::Selenium::Driver` with
`browser: :chrome` (`spec/spec_helper.rb:477`), so you need Chrome installed.

---

## 6. Known Gaps in the Local Setup

These are real limitations of the host-native approach, not misconfiguration.
They are the strongest argument for the Docker setup.

### File characterization is broken

`config/initializers/hyrax.rb:126-134` probes for `fits.sh` and, finding
none, logs `error, no fits.sh` at boot — reproduced on this machine. FITS is
not installed, and `Hydra::Works::CharacterizationService.run(proxy,
file_name)` in `app/helpers/deepblue/ingest_helper.rb:89` passes no
`ch12n_tool`, so it defaults to `:fits` and shells out to the missing binary.
Characterization fails; ingest continues, because
`IngestHelper.characterize` rescues and logs.

### Derivative tooling is absent

None of these are on the host:

```
convert  identify  ffmpeg  ffprobe  soffice  libreoffice
exiftool pdftotext gs      mediainfo tesseract clamscan
```

Thumbnails, video/audio transcoding, Office and PDF derivatives, and OCR
will not work. The Docker image installs all of them.

### Virus scanning is off

`config/initializers/clamav.rb` falls through to `NullVirusScanner` when
ClamAV is absent, printing `No virus checker in use.`

### Wrapper fragility

`solr_wrapper` (4.1.0) and `fcrepo_wrapper` (0.9.0) download and manage old
Java services. Both need per-JVM workarounds — the Java 8 pin and the
`GC_TUNE` override exist for exactly this reason.

If dev state gets wedged: stop services, remove `tmp/solr-development`,
`tmp/fcrepo4-development-data`, and re-run `./bin/dev-stack start`. This
discards your local repository contents.

---

## 7. Configuration Model

Worth understanding before you change anything, and *essential* before
you introduce environment variables (see UM_IDE_DEV.md).

Config flows through the [`config`](https://github.com/rubyconfig/config)
gem, exposed as `Settings` (`config/initializers/config.rb`):

```
config/settings.yml                     # defaults, deliberately invalid hosts
  └── config/settings/development.yml   # real dev values
        └── config/settings/development.local.yml   # yours, gitignored
```

Rails' own YAML files are thin shims over `Settings` — `database.yml`,
`fedora.yml`, `solr.yml`, `cable.yml`, and `blacklight.yml` contain no
literals, only interpolations. Change values in the settings files, not
in these.

Precedence, and the asymmetry that bites people:

| Setting | Env var override? |
|---|---|
| Solr URL | **yes** — `SOLR_URL` (`config/solr.yml:6`) |
| Database | **yes** — `DATABASE_URL` |
| Secret key | **yes** — `SECRET_KEY_BASE` |
| Fedora URL | **no** — only `FCREPO_DEVELOPMENT_PORT`, and host is hardcoded `127.0.0.1` |
| Redis | **no** — `Settings.redis.to_h` is passed directly to `Redis.new` |

Fedora and Redis have **no** full-URL environment override. Point them
somewhere else and you must edit
`config/settings/development.local.yml`. Both files
(`config/settings.local.yml` and `config/settings/*.local.yml`) are
gitignored, so local overrides are safe to keep.

### Files that are *not* for this setup

`.env`, `docker.env`, `compose.yml`, and `Dockerfile` came from upstream
Hyrax 5.3's `dassie` test app and describe a different application. **Do not
source `.env` for local development.** It sets `DATABASE_URL` to PostgreSQL,
and the `pg` gem is not in the bundle — verified failure:

```
Error loading the 'postgresql' Active Record adapter.
pg is not part of the bundle.
```

See UM_IDE_DEV.md §2 for the full list of mismatches.
