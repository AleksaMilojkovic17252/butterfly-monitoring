"""CSV resources for the catalogue admins (T023, D-048).

Rows match on natural keys, so the CSV carries no UUIDs and no sync columns. Rows are saved one
by one so the sync trigger and history fire for each of them.
"""

from import_export import fields, resources, widgets

from apps.catalogues.models import (
    HabitatType,
    ManagementType,
    PlantTaxon,
    Taxon,
    TaxonListVersion,
)


class StrictBooleanWidget(widgets.BooleanWidget):
    """Boolean column that rejects unknown values instead of reading them as False."""

    def clean(self, value, row=None, **kwargs):
        if value not in self.TRUE_VALUES + self.FALSE_VALUES + self.NULL_VALUES:
            raise ValueError(f"{value!r} is not a boolean; use 1 or 0.")
        return super().clean(value, row, **kwargs)


class CatalogueResource(resources.ModelResource):
    """Base for the catalogue CSVs: row-by-row saves with the importing user and a reason."""

    @classmethod
    def widget_from_django_field(cls, f, default=widgets.Widget):
        widget = super().widget_from_django_field(f, default)
        return StrictBooleanWidget if widget is widgets.BooleanWidget else widget

    def before_save_instance(self, instance, row, **kwargs):
        user = kwargs.get("user")
        if instance._state.adding:
            instance.created_by = user
        instance.updated_by = user
        instance._history_user = user
        instance._change_reason = "CSV import"


class TaxonResource(CatalogueResource):
    introduced_in = fields.Field(
        attribute="introduced_in",
        column_name="introduced_in",
        widget=widgets.ForeignKeyWidget(TaxonListVersion, field="version_label"),
    )
    # Export only: retiring and renaming go through the admin actions, never through the CSV.
    retired_in = fields.Field(
        attribute="retired_in",
        column_name="retired_in",
        widget=widgets.ForeignKeyWidget(TaxonListVersion, field="version_label"),
        readonly=True,
    )
    accepted_name = fields.Field(
        attribute="accepted_name",
        column_name="accepted_name",
        widget=widgets.ForeignKeyWidget(Taxon, field="scientific_name"),
        readonly=True,
    )

    class Meta:
        model = Taxon
        fields = [
            "scientific_name",
            "author",
            "rank",
            "genus",
            "family",
            "vernacular_name_sr",
            "vernacular_name_en",
            "taxon_source",
            "taxon_source_id",
            "introduced_in",
            "active",
            "photo_required",
            "identification_notes",
            "retired_in",
            "accepted_name",
        ]
        export_order = fields
        import_id_fields = ["scientific_name", "rank", "introduced_in"]
        skip_unchanged = True
        report_skipped = True
        clean_model_instances = True
        use_bulk = False


class PlantTaxonResource(CatalogueResource):
    class Meta:
        model = PlantTaxon
        fields = [
            "scientific_name",
            "family",
            "vernacular_name",
            "vernacular_name_en",
            "taxon_source",
            "taxon_source_id",
            "active",
        ]
        export_order = fields
        import_id_fields = ["scientific_name"]
        skip_unchanged = True
        report_skipped = True
        clean_model_instances = True
        use_bulk = False


class HabitatTypeResource(CatalogueResource):
    class Meta:
        model = HabitatType
        fields = [
            "code",
            "name_en",
            "name_sr",
            "eunis_code",
            "description",
            "sort_order",
            "active",
        ]
        export_order = fields
        import_id_fields = ["code"]
        skip_unchanged = True
        report_skipped = True
        clean_model_instances = True
        use_bulk = False


class ManagementTypeResource(CatalogueResource):
    class Meta:
        model = ManagementType
        fields = ["code", "name_en", "name_sr", "description", "sort_order", "active"]
        export_order = fields
        import_id_fields = ["code"]
        skip_unchanged = True
        report_skipped = True
        clean_model_instances = True
        use_bulk = False
