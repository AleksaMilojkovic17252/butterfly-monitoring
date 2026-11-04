from django import forms
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


class LineMapWidget(EditableMapWidget):
    """EditableMapWidget for a single LineString (transects and sections, T021).

    The help explains that a line is finished with a double-click and that there is only one
    line per field: drawing stops until it is deleted.
    """

    template_name = "core/widgets/line_map.html"


class SearchableSelect(forms.Select):
    """A drop-down with a search box, for long lists such as time zones (T104).

    Uses the select2 build Django's admin already ships, so nothing is added to the project.
    """

    class Media:
        css = {"all": ("admin/css/vendor/select2/select2.min.css",)}
        js = (
            "admin/js/vendor/jquery/jquery.min.js",
            "admin/js/vendor/select2/select2.full.min.js",
            # As in Django's own autocomplete widget: select2 loads before jquery.init.js hands
            # jQuery over to django.jQuery, so django.jQuery has the select2 plugin.
            "admin/js/jquery.init.js",
            "core/searchable_select.js",
        )
