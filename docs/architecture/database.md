# Database layout

One PostgreSQL database, `butterfly`, with PostGIS (CONVENTIONS A.5 item 1, D-004).

## Schemas and roles

| Schema | Owner | Holds | Who reads it |
|---|---|---|---|
| `public` | `django_app` | every Django table, including `historical_*` tables and PostGIS | `django_app` |
| `geo` | `django_app` | **views only**, created by Django migrations | `pygeoapi_ro` (SELECT) |

| Role | Created by | Rights |
|---|---|---|
| `postgres` | the image | superuser, used only by `db-init` |
| `django_app` | `infrastructure/db-init/01-init.sh` | owns the database, `public` and `geo`; the app connects as this role |
| `pygeoapi_ro` | `infrastructure/db-init/01-init.sh` | login; `USAGE` on `geo` and `SELECT` on its views; nothing on `public` tables |

The schema `geo` is created by migration `core/0001_schemas`, together with
`ALTER DEFAULT PRIVILEGES FOR ROLE django_app IN SCHEMA geo GRANT SELECT ON TABLES TO pygeoapi_ro`.
Every view `django_app` creates in `geo` is therefore readable by pygeoapi without a further grant.
A fresh `migrate` on a new database reproduces the whole layout.

## Why pygeoapi can read views but not tables

A view runs with its **owner's** privileges. The `geo` views are owned by `django_app`, so
`pygeoapi_ro` can select from them even though it has no grant on the `public` tables underneath.
**Never set `security_invoker = true` on a `geo` view**: it would make the view run as `pygeoapi_ro`
and fail, and any fix would mean granting that role access to `public`.

PostgreSQL grants `USAGE` on the schema `public` to every role by default (the `PUBLIC` pseudo-role).
That is left as it is: it gives no access to any table, and pygeoapi needs it to resolve PostGIS
functions and the `geometry` type, which live in `public`. No explicit grant to `pygeoapi_ro` exists.

## Adding a view

Use `CreateView` from `apps.core.migration_ops` in a Django migration:

```python
from apps.core.migration_ops import CreateView

operations = [
    CreateView("geo.butterfly_observation", "SELECT id, taxon_id, geometry FROM butterfly_observation"),
]
```

The reverse migration drops the view. The migration autodetector does not see views, so renaming a
column that a view uses needs a hand-written migration that drops and recreates the dependent views.
There is no automated check that selects from every view (D-021); after a change to a model that a view
reads, select one row from each view as `pygeoapi_ro` by hand (D-078).

The current views and the migration that creates each:

| View | Migration |
|---|---|
| `geo.transects`, `geo.transect_sections` | `transects/0005_geo_views` |
| `geo.butterfly_observations` | `observations/0004_geo_views` |
| `geo.plant_resources` | `resources/0002_geo_views` |
| `geo.habitat_features` | `resources/0004_habitat_geo_view`, `0005_habitat_view_visit` (adds `survey_visit_id`) |

A view's migration lives in the
app that owns its main table. Views hide soft-deleted rows and the rows of soft-deleted parents (D-078).

PostGIS's own `geometry_columns`, `geography_columns` and `spatial_ref_sys` in `public` are readable by
`PUBLIC`, so `pygeoapi_ro` can read them. That is not a grant of ours, and they hold no project data.

## Schemas from the outline that are not used in Phase 1

The development plan mentions the schemas `app`, `audit`, `sensorthings` and `mobility`.

- `app`: Django keeps its tables in `public`; a second schema would only complicate migrations.
- `audit`: django-simple-history stores `historical_<table>` next to its model (D-009).
- `sensorthings`: FROST (Phase 2) gets its own database, `frost`, so it never touches `butterfly`.
- `mobility`: created in Phase 2 only if the T087 spike picks the pygeoapi-mf-api fork.
