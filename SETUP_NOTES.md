# Deepblue Local Setup Notes (macOS)

This file captures the exact setup sequence and caveats verified on this machine.

## Verified Baseline

- Ruby: `3.3.10` (from `.ruby-version`)
- Bundler: lockfile expects `2.5.3` (auto-installed by `bundle install`)
- Current app DB config: `sqlite3` in `config/settings/development.yml`

## One-Time Dependency Install

```zsh
cd "/Users/gkostin/GitHub/mlibrary/deepblue"

# native deps used by gems/wrappers
brew install mysql libxml2 libxslt libiconv redis

# Java 8 needed for Fedora 4.7.x wrapper in this setup
brew install --cask temurin@8
```

## Gem Setup

1. In `Gemfile`, comment out the block that executes `gemfile_bundle_config` (`if !gemfile_bundle_config.nil?` ... `end`) before running Bundler.
2. Ensure local bundler config exists.

Example `.bundle/config` used successfully:

```yaml
---
BUNDLE_BUILD__LIBXML___RUBY: "--with-xml2-config=/opt/homebrew/opt/libxml2/bin/xml2-config"
BUNDLE_BUILD__MYSQL2: "--with-ldflags=-L/opt/homebrew/opt/zstd/lib"
BUNDLE_BUILD__POSIX___SPAWN: "--with-cflags=-Wno-incompatible-function-pointer-types"
BUNDLE_BUILD__UNICODE: "--with-cflags=-Wno-incompatible-function-pointer-types"
BUNDLE_PATH: ".bundle"
BUNDLE_WITHOUT: "production"
```

Install gems:

```zsh
cd "/Users/gkostin/GitHub/mlibrary/deepblue"

gem install mysql2 -v '0.5.6' -- --with-opt-dir="$(brew --prefix openssl@3)" --with-ldflags=-L/opt/homebrew/opt/zstd/lib

gem install posix-spawn -- --with-cflags="-Wno-incompatible-function-pointer-types"

bundle config --local build.libxml-ruby --with-xml2-config="$(brew --prefix libxml2)/bin/xml2-config"

bundle install
```

## DB and Hyrax Bootstrap

```zsh
cd "/Users/gkostin/GitHub/mlibrary/deepblue"

bundle exec rails db:migrate
bundle exec rake hyrax:default_collection_types:create
```

Default admin set creation (example owner):

```zsh
cd "/Users/gkostin/GitHub/mlibrary/deepblue"

bundle exec rails runner "owner=User.find_by(email: 'gkostin@umich.edu'); raise 'owner_missing' unless owner; admin_set=Hyrax::AdministrativeSet.new(title: ['DataSet Admin Set']); Hyrax::AdminSetCreateService.new(admin_set: admin_set, creating_user: owner, default_admin_set: true).create!"
```

If owner user is missing, create one quickly:

```zsh
cd "/Users/gkostin/GitHub/mlibrary/deepblue"

bundle exec rails runner "email='gkostin@umich.edu'; u=User.find_or_initialize_by(email: email); if u.new_record?; pw=SecureRandom.urlsafe_base64(16); u.password=pw; u.password_confirmation=pw; u.save!; end"
```

## Service Startup (Repeatable)

Use helper script:

```zsh
cd "/Users/gkostin/GitHub/mlibrary/deepblue"

./bin/dev-stack start
./bin/dev-stack status
```

### What `bin/dev-stack` does

- Starts Redis via `/opt/homebrew/opt/redis/bin/redis-server`
- Starts Fedora (`fcrepo_wrapper`) with `JAVA_HOME` forced to Java 8
- Starts Solr (`solr_wrapper`) with a `GC_TUNE` override compatible with newer JVMs
- Starts Rails on port `3000`
- Prints health summary for ports/endpoints

## Manual UI Steps Remaining

After Rails is up:

- Open `http://localhost:3000/data`
- In dashboard collections:
  - edit default admin set
  - click **Allow Everyone to Deposit**
  - set workflow to **mediated**
- Create a new admin collection named `Draft works Admin Set`
  - set workflow to **draft**

## Known Caveats

- `fcrepo_wrapper` and `solr_wrapper` are older and may require local compatibility adjustments after dependency refresh.
- Fedora 4.7.x did not become healthy under Java 26 in this session; Java 8 was required.
- Solr 7.7.1 required avoiding deprecated CMS GC options; helper script sets a compatible `GC_TUNE` during launch.
- If Solr/Fedora state gets stale, stop services, remove local wrapper data under `tmp/`, and rerun setup/start steps.

