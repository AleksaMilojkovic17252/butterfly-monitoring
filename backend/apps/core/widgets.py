from django.contrib.gis.forms.widgets import OSMWidget


class EditableMapWidget(OSMWidget):
    """OSM map widget that edits a multi-geometry one part at a time (T098).

    Each polygon (or line, or point) of a Multi* value is its own feature on the map, so a
    single part can be selected, reshaped or deleted; on save the parts are joined again.
    A "?" in the map corner explains the gestures. Pass `help_note` in `attrs` to add a line
    about the field, e.g. an import action. Uses the OpenLayers build Django already loads.
    """

    template_name = "core/widgets/editable_map.html"

    class Media:
        css = {"all": ("core/editable_map.css",)}
        # Listing Django's script first makes the media merge load it before ours.
        js = ("gis/js/OLMapWidget.js", "core/editable_map.js")
