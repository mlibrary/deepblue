# Stack Health Checks

Use this guide to verify that the local Deepblue development stack is up and running.

## Quick Check (All Services)

From repo root:

```zsh
cd "/Users/gkostin/GitHub/mlibrary/deepblue"
./bin/dev-stack status
```

Expected healthy pattern:

- `Redis :6379 => up`
- `Fedora :8984 /rest => HTTP 200`
- `Solr   :8983 /solr/ => HTTP 200`
- `Rails  :3000 /data => HTTP 200` (a non-`000` code like `302` can still mean Rails is up)

## Manual Endpoint Checks

```zsh
curl -sS -o /dev/null -w "Fedora: %{http_code}\n" http://127.0.0.1:8984/rest
curl -sS -o /dev/null -w "Solr:   %{http_code}\n" http://127.0.0.1:8983/solr/
curl -sS -o /dev/null -w "Rails:  %{http_code}\n" http://127.0.0.1:3000/data
/opt/homebrew/opt/redis/bin/redis-cli ping
```

Expected:

- Fedora: `200`
- Solr: `200`
- Rails: non-`000` (usually `200`)
- Redis: `PONG`

## Start the Stack If Needed

```zsh
cd "/Users/gkostin/GitHub/mlibrary/deepblue"
./bin/dev-stack start
```

Then re-run:

```zsh
./bin/dev-stack status
```

## Troubleshooting Logs

If a service is down or not healthy, inspect logs:

```zsh
tail -n 100 log/fcrepo_wrapper.out
tail -n 100 log/solr_wrapper.out
tail -n 100 log/rails-server.out
tail -n 100 log/redis-server.out
```

## Session-Verified Baseline

During this setup session, the stack was verified with these health results:

- Fedora `/rest` on port `8984`: `HTTP 200`
- Solr `/solr/` on port `8983`: `HTTP 200`
- Redis on port `6379`: `PONG`
- Rails `/data` on port `3000`: `HTTP 200`

