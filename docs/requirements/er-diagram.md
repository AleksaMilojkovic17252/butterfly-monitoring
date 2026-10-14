# ER diagram (Phase 1)

Table names are the `db_table` values. Key columns only; the full list is in [fields.md](fields.md).
Synced tables also carry the sync columns (`server_version`, `created_at`, `updated_at`,
`deleted_at`, `created_by_id`, `updated_by_id`). History tables (`historical_<table>`) are omitted.

```mermaid
erDiagram
    app_user ||--o{ project : owns
    app_user ||--o{ project_membership : "member of"
    project ||--o{ project_membership : has
    project ||--|| project_protocol : configures
    project }o--|| taxon_list_version : uses
    project ||--o{ transect : has
    project ||--o{ survey_visit : has
    project ||--o{ butterfly_observation : has
    project ||--o{ plant_resource_observation : has
    project ||--o{ habitat_feature : has

    taxon_list_version ||--o{ taxon : introduces
    taxon ||--o| taxon : "accepted_name"
    plant_taxon ||--o{ plant_resource_observation : identifies
    habitat_type ||--o{ transect_section : describes
    management_type ||--o{ transect_section : describes
    habitat_type ||--o{ habitat_feature : describes
    management_type ||--o{ habitat_feature : describes

    transect ||--o{ transect_section : "divided into"
    transect ||--o{ survey_visit : walked
    app_user ||--o{ survey_visit : observes
    survey_visit ||--o{ survey_track_point : records
    survey_visit ||--o{ butterfly_observation : contains
    survey_visit ||--o{ plant_resource_observation : contains
    survey_visit ||--o{ habitat_feature : contains
    survey_visit ||--o{ environmental_snapshot : "weather of"
    transect_section ||--o{ butterfly_observation : "located in"

    taxon ||--o{ butterfly_observation : "seen as"
    taxon ||--o{ butterfly_observation : "validated as"
    app_user ||--o{ butterfly_observation : records
    plant_resource_observation ||--o{ butterfly_observation : "host or nectar plant"
    butterfly_observation ||--o{ photo : has
    plant_resource_observation ||--o{ photo : has
    butterfly_observation ||--o{ environmental_snapshot : "conditions at"
    butterfly_observation ||--o{ validation_event : "decided in"
    app_user ||--o{ validation_event : decides

    app_user ||--o{ sync_mutation : sends
    sync_mutation ||--o| sync_conflict : "may cause"
    app_user ||--o{ sync_conflict : owns
    project ||--o{ sync_conflict : "in"

    app_user {
        uuid id PK
        string email UK
        string name
        string organization
    }
    project {
        uuid id PK
        string name
        uuid owner_id FK
        date start_date
        date end_date
        multipolygon area
        uuid taxon_list_version_id FK
    }
    project_membership {
        int id PK
        uuid project_id FK
        uuid user_id FK
    }
    project_protocol {
        uuid id PK
        uuid project_id FK
        date season_start
        date season_end
        time day_start_time
        time day_end_time
    }
    taxon_list_version {
        uuid id PK
        string version_label UK
        bool is_current
    }
    taxon {
        uuid id PK
        string scientific_name
        string rank
        uuid accepted_name_id FK
        uuid introduced_in_id FK
        uuid retired_in_id FK
        bool photo_required
    }
    plant_taxon {
        uuid id PK
        string scientific_name UK
    }
    habitat_type {
        uuid id PK
        string code UK
    }
    management_type {
        uuid id PK
        string code UK
    }
    transect {
        uuid id PK
        uuid project_id FK
        string code
        linestring geometry
    }
    transect_section {
        uuid id PK
        uuid transect_id FK
        string section_code
        int sequence_number
        uuid habitat_type_id FK
        uuid management_type_id FK
        linestring geometry
    }
    survey_visit {
        uuid id PK
        uuid project_id FK
        uuid transect_id FK
        uuid observer_id FK
        string status
        string cancel_reason
        timestamptz started_at
        timestamptz ended_at
        decimal distance_walked_m
        bool zero_observation_confirmed
    }
    survey_track_point {
        uuid id PK
        uuid survey_visit_id FK
        timestamptz recorded_at
        point geometry
        int sequence_number
    }
    butterfly_observation {
        uuid id PK
        uuid project_id FK
        uuid survey_visit_id FK
        uuid transect_section_id FK
        uuid taxon_id FK
        uuid validated_taxon_id FK
        uuid recorded_by_id FK
        uuid host_plant_record_id FK
        uuid nectar_plant_record_id FK
        timestamptz observed_at
        int count
        point geometry
        string identification_confidence
        string source
        string validation_status
    }
    plant_resource_observation {
        uuid id PK
        uuid project_id FK
        uuid survey_visit_id FK
        uuid plant_taxon_id FK
        string resource_type
        geometry geometry
    }
    habitat_feature {
        uuid id PK
        uuid project_id FK
        uuid survey_visit_id FK
        uuid habitat_type_id FK
        uuid management_type_id FK
        geometry geometry
    }
    photo {
        uuid id PK
        uuid observation_id FK
        uuid plant_resource_id FK
        string sha256
        string upload_status
    }
    environmental_snapshot {
        uuid id PK
        uuid survey_visit_id FK
        uuid observation_id FK
        string source_type
        string moment
    }
    validation_event {
        uuid id PK
        uuid observation_id FK
        string decision
        uuid decided_by_id FK
    }
    sync_mutation {
        uuid mutation_id PK
        uuid user_id FK
        string entity_type
        uuid entity_id
        string status
    }
    sync_conflict {
        uuid id PK
        uuid mutation_id FK
        uuid owner_id FK
        uuid project_id FK
        string status
    }
```

Not shown: the `geo` views (T067), `report_transect_indicators` (T061), and the Phase 2 tables
`sensor_station_link`, `focal_follow_*` and `trajectory_event`.
