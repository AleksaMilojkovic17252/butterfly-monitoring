// Section form (T021): draw the chosen transect's line on the section map, so the section can
// be drawn along it (points snap to it). The URL comes from the transect field's data-line-url,
// with a zero UUID standing in for the transect id.
"use strict";
document.addEventListener("DOMContentLoaded", () => {
    const select = document.getElementById("id_transect");
    const wrapper = document.querySelector(".editable_map");
    const widget = wrapper && wrapper.editableMap;
    if (!select || !widget || !select.dataset.lineUrl) {
        return;
    }
    const zeroId = "00000000-0000-0000-0000-000000000000";

    async function showTransect() {
        if (!select.value) {
            widget.setReference(null);
            return;
        }
        const response = await fetch(select.dataset.lineUrl.replace(zeroId, select.value));
        widget.setReference(response.ok ? (await response.json()).geometry : null);
    }

    // The autocomplete (select2) reports changes through jQuery, not a native event.
    django.jQuery(select).on("change", showTransect);
    showTransect();
});
