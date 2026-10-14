# Butterfly monitoring

Offline-first Android app and Django/PostGIS server for standardised butterfly transect surveys,
with data published through OGC APIs. Master's thesis project.

- Project summary and scope: [docs/PROJECT_OUTLINE.md](docs/PROJECT_OUTLINE.md)
- Ticket status and build order: [docs/TICKETS.md](docs/TICKETS.md); full ticket text: [docs/TICKET_DETAILS.md](docs/TICKET_DETAILS.md) (same as the GitHub issues; roadmap in #2, conventions in #1)
- Architectural decisions: [docs/DECISIONS.md](docs/DECISIONS.md)
- Working with Claude Code: [CLAUDE.md](CLAUDE.md), `/next-ticket`, `/finish-ticket`, `/review`

## Run locally

Tested target: CachyOS / Arch Linux with Docker from the Arch repositories.

### One-time setup

```bash
sudo pacman -S docker docker-compose docker-buildx
sudo systemctl enable --now docker.socket
sudo usermod -aG docker $USER        # then log out and back in
```

Create your local settings (the file is git-ignored) and replace every `change-me`:

```bash
cp .env.example .env
$EDITOR .env
```

Generate a secret key for `DJANGO_SECRET_KEY` with `python3 -c "import secrets; print(secrets.token_urlsafe(50))"`.

### Start and stop

Run from the repository root:

```bash
DC="docker compose --project-directory . -f infrastructure/compose.yaml -f infrastructure/compose.dev.yaml"
$DC up -d --build      # first start builds the django image and pulls the others
$DC ps                 # all five services should become "healthy"
$DC logs -f django
$DC down               # stops the stack; data volumes are kept
```

Never run `$DC down -v`: it deletes the database and the stored photos.

### What is published on the host

| Address | Service |
|---|---|
| `http://localhost:8080` | nginx: `/api/`, `/admin/`, `/static/` (Django) and `/ogc/` (pygeoapi) |
| `http://localhost:9001` | MinIO console (this machine only) |
| `localhost:5432` | PostgreSQL, for `psql` and QGIS (this machine only) |

Check the stack with `curl localhost:8080/api/v1/health/` (`{"status":"ok","db":true,"storage":true}`). API docs: `http://localhost:8080/api/v1/docs/`.

### Data

Named volumes `pgdata` (PostgreSQL), `miniodata` (photos) and `staticfiles` survive `down` and restarts.
The database roles and the PostGIS extension are created only when `pgdata` is first created; to rerun
`infrastructure/db-init/01-init.sh`, the volume has to be removed (this deletes the data).
