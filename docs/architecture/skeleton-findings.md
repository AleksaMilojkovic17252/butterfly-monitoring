# Walking skeleton findings (T007)

Slice: app ping → `POST /api/v1/skeleton/pings` → table `skeleton_ping` → view
`geo.skeleton_pings` → pygeoapi collection `skeleton-pings` → QGIS. Throwaway: the table,
endpoint and collection are removed in T044/T068.

## VERIFY results (backend and OGC half, checked 2026-10-15, pygeoapi 0.24.0)

| Question | Result |
|---|---|
| pygeoapi reads a view in `geo` as `pygeoapi_ro` | **Yes.** The PostgreSQL provider reflects views. `table: skeleton_pings` plus `search_path: [geo]` is enough. No grant on `public` was needed (D-004: the view runs with its owner's rights). |
| `id_field` with a `uuid` column | **Yes.** `id_field: id` works; items and `/items/{uuid}` both return the id as a string. |
| `time_field` on a view | **Yes.** `time_field: observed_at` works; `datetime=a/b` filters correctly (1 match inside the range, 0 outside). |

## Things that bit

- nginx: `/ogc` **without** a trailing slash did not match `location /ogc/`, fell through to
  Django, and its slash redirect dropped the port (`Location: http://localhost/ogc/`), giving
  "connection refused". pygeoapi's own links are `/ogc?f=json`, so QGIS would hit it too. Fixed
  with a `location = /ogc` block in `infrastructure/nginx/default.conf`. That file is a
  single-file bind mount: after editing it, `restart nginx` (a reload keeps the old inode).
- pygeoapi fails to **start** (container unhealthy, so nginx never starts) if a configured table or
  view does not exist yet. Run `migrate` before `up`, or restart pygeoapi after migrating. Remember
  this whenever a collection is added together with its view (T067/T068).
- The pygeoapi container had no database credentials. The config uses `${VAR}` substitution and
  `infrastructure/compose.yaml` now passes `POSTGRES_DB`, `PYGEOAPI_DB_USER` and
  `PYGEOAPI_DB_PASSWORD` to it. Host is fixed to `db`.
- Idempotency: `get_or_create` on the client `id`. First post gives 201 `created: true`, a repeat
  gives 200 `created: false`, one row either way. Validation errors use the standard
  `{code, detail, fields}` body.

## Steps to see it

```bash
curl -X POST localhost:8080/api/v1/skeleton/pings -H 'Content-Type: application/json' \
  -d '{"id":"3f1c0b6e-7a52-4c8e-9d5b-0a1b2c3d4e5f","observed_at":"2026-10-15T12:00:00Z","lat":44.8125,"lon":20.4612,"note":"hi"}'
curl 'localhost:8080/ogc/collections/skeleton-pings/items?f=json'
```

QGIS: Layer → Add Layer → Add WFS / OGC API – Features Layer → New connection, URL
`http://localhost:8080/ogc` → Connect → `skeleton-pings` → Add.

## Manual run (2026-10-15)

Phone → server over USB and over Tailscale, the airplane-mode check and QGIS were run by hand.
Notes below.

### Manual run notes

- Offline: with airplane mode on, "Drop ping" still stores rows in Drift (GPS works); "Send" fails
  and the rows stay pending. They survive an app restart.
- USB: `adb reverse tcp:8080 tcp:8080` keeps working in airplane mode while the cable is plugged
  in, so `localhost:8080` still reaches the server. That is not a real offline test. The mapping
  is lost when the cable is unplugged and must be set again.
- Tailscale: needs the phone's Wi-Fi or mobile data. In airplane mode "Send" fails even if the
  Tailscale app still shows connected. With airplane mode off, pending rows were sent over the
  Tailscale HTTPS host from the real phone (offline-then-sync works).
- Server answers 201 for a new id and 200 for a repeated one; the app treats both as sent.
- Idempotency by curl: the same `id` posted twice gave 201 `created: true`, then 200
  `created: false`, and one feature in the collection.
- QGIS: the collection loads as an OGC API – Features layer from `http://localhost:8080/ogc`.
