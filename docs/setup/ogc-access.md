# Reaching the OGC API (pygeoapi) as an admin

`/ogc` is closed to everyone but admins (T069, D-080). nginx asks Django about every request
(`auth_request` to `/api/v1/auth/verify`); Django answers 204 for an active user in the `admin` group
and nginx lets the request through. Researchers get 403, missing or bad credentials get 401 with
`WWW-Authenticate: Basic realm="ogc"`.

Three ways to send credentials, all in the `Authorization` header:

| Header | Use it for |
|---|---|
| `Token <key>` | Desktop tools and scripts. **Prefer this.** Long-lived, revocable, one per admin. |
| `Bearer <jwt>` | The 15-minute access token from `POST /api/v1/auth/login`. Fine for a quick `curl`, useless in QGIS. |
| `Basic <base64 of email:password>` | Fallback for tools without a custom header. The password travels with every request. |

A personal token opens **only** `/ogc`. It is not accepted by the sync or REST API.

## Create and revoke a token

In Django admin (`/admin/`), as an admin: **Authtoken → Tokens → Add token**, pick the user, save, copy the key.
One token per user. To revoke, delete the token there; to replace it, delete and add again.

From the shell, for the same thing:

```fish
set DC docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml
$DC exec django python manage.py drf_create_token <email>
```

(`drf_create_token` prints the existing key if the user already has one.) A token is a password: do not
paste it into a repository, a notebook you share or a screenshot.

**Limit:** nginx caches a successful answer for up to 60 seconds. A revoked token, a deactivated user, a
user removed from the `admin` group or a changed password still works for up to 60 s afterwards. The
same goes for a JWT that has just expired.

## curl

```fish
curl -H "Authorization: Token $KEY" "http://localhost:8080/ogc/collections?f=json"
curl -u admin@example.org "http://localhost:8080/ogc?f=json"        # Basic, asks for the password
```

A browser asks for a login (Basic) when you open `http://localhost:8080/ogc/` and remembers it until you
close it.

## QGIS

QGIS 4.2.3 here. Settings → Options → Authentication → **+**, type **API Header**, one header
`Authorization` = `Token <key>`. Then Layer → Add Layer → Add WFS / OGC API – Features Layer → New, URL
`http://localhost:8080/ogc`, and choose that authentication configuration. If your QGIS has no API Header type,
use **Basic** with the admin's email and password.

Checked in QGIS 4.2.3 (T069): the API Header configuration connects and lists the collections. With a wrong or revoked token, QGIS answers nginx's Basic challenge by asking for a username and password; an admin's email and password then work.

## Python

```python
import requests

headers = {"Authorization": "Token <key>"}
r = requests.get(
    "http://localhost:8080/ogc/collections/transects/items",
    params={"f": "json", "limit": 100},
    headers=headers,
    timeout=30,
)
r.raise_for_status()
features = r.json()["features"]
```

Run against the stack: 200 and the features come back.

## R and GDAL

GDAL 3.13.3 reads the header from a **file**, not from `GDAL_HTTP_HEADERS` (that variable is ignored by the
OAPIF driver here: the request went out with no `Authorization` header and got a 401). Keep the file out of
the repository and readable by you only:

```fish
printf 'Authorization: Token %s\n' $KEY > ~/.ogc-header; chmod 600 ~/.ogc-header
env GDAL_HTTP_HEADER_FILE=$HOME/.ogc-header ogrinfo OAPIF:http://localhost:8080/ogc
```

This lists `transects`, `transect-sections`, `butterfly-observations`, `plant-resources` and `habitat-features`. The driver's own `USERPWD` open
option also works for Basic: `ogrinfo -oo USERPWD=email:password OAPIF:http://localhost:8080/ogc`.

R with `sf` uses the same GDAL, so set the variable before reading. **Not run:** R is not installed on this machine.

```r
Sys.setenv(GDAL_HTTP_HEADER_FILE = path.expand("~/.ogc-header"))
transects <- sf::st_read("OAPIF:http://localhost:8080/ogc", layer = "transects")
```

With `httr2` (also not run):

```r
library(httr2)
resp <- request("http://localhost:8080/ogc/collections/transects/items") |>
  req_url_query(f = "json", limit = 100) |>
  req_headers(Authorization = paste("Token", Sys.getenv("OGC_KEY"))) |>
  req_perform()
features <- resp_body_json(resp)$features
```

## Known limits

- `datetime=` means something different per collection. On `butterfly-observations`, `plant-resources` and `habitat-features` it filters on `observed_at`. On `transects` and `transect-sections` it filters on the row's creation time (`created_at`), and on `observation-hexgrid` on the newest observation in the cell (`last_observed_at`). Those three have no static temporal extent (D-113).
- Up to 60 s of delay after a revocation, a deactivation, a group change or a password change (above).
- Basic auth sends the password with every request. Failed Basic logins are limited to 5 in 15 minutes per
  email, with a counter separate from the app login (the answer is 401 while locked; a token or JWT still works). The counter is per
  process, and production runs two workers, so there the limit can be up to 10.
- Browser-origin JavaScript clients (CORS) are not supported; use a desktop tool, a script or a server-side client.
- nginx keeps the `Authorization` header as the cache key in a tmpfs (`/var/cache/nginx/auth`), so it never reaches the disk.
- `/api/v1/auth/verify` answers 404 from outside: only nginx may call it.
