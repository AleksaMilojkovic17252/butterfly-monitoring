// Add station page (T078): changing the project clears the chosen transects and habitat
// feature, and offers those of the new project. The URL comes from the project field's
// data-choices-url, with a zero UUID standing in for the project id. A saved station's project
// is read-only, so there is no field and this does nothing.
"use strict";
document.addEventListener("DOMContentLoaded", () => {
    const project = document.getElementById("id_project");
    const habitat = document.getElementById("id_habitat_feature");
    if (!project || !habitat || !project.dataset.choicesUrl) {
        return;
    }
    const zeroId = "00000000-0000-0000-0000-000000000000";
    let shown = project.value;

    // Shown above the habitat and transect fields when the lists could not be loaded.
    const failure = document.createElement("p");
    failure.className = "errornote";
    failure.textContent =
        "The habitat polygons and transects of this project could not be loaded. " +
        "Check that you are still signed in. ";
    const retry = document.createElement("button");
    retry.type = "button";
    retry.className = "button";
    retry.textContent = "Try again";
    failure.append(retry);

    // The two boxes of Django's horizontal filter keep their rows in SelectBox's cache.
    function showTransects(rows) {
        SelectBox.cache.id_transects_from = rows.map((row) => ({
            value: row.id,
            text: row.label,
            displayed: 1,
        }));
        SelectBox.cache.id_transects_to = [];
        document.getElementById("id_transects_input").value = "";
        document.getElementById("id_transects_selected_input").value = "";
        SelectBox.redisplay("id_transects_from");
        SelectBox.redisplay("id_transects_to");
        SelectFilter.refresh_icons("id_transects");
        SelectFilter.refresh_filtered_warning("id_transects");
    }

    function showHabitats(rows) {
        habitat.replaceChildren(
            new Option("---------", ""),
            ...rows.map((row) => new Option(row.label, row.id)),
        );
        // Updates the view and change links next to the field.
        django.jQuery(habitat).trigger("change");
    }

    async function loadChoices() {
        const chosen = shown;
        failure.remove();
        if (!chosen) {
            return;
        }
        try {
            const response = await fetch(project.dataset.choicesUrl.replace(zeroId, chosen));
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }
            // An expired session answers with the login page, which is not JSON.
            const choices = await response.json();
            // The project may have been changed again while this answer was on its way.
            if (chosen === shown) {
                showTransects(choices.transects);
                showHabitats(choices.habitat_features);
            }
        } catch (error) {
            console.error(error);
            if (chosen === shown) {
                habitat.closest("fieldset").prepend(failure);
            }
        }
    }

    function showProject() {
        if (project.value === shown) {
            return;
        }
        shown = project.value;
        // Cleared at once, so nothing of the old project can be saved while the new lists load.
        showTransects([]);
        showHabitats([]);
        loadChoices();
    }

    retry.addEventListener("click", loadChoices);

    // The autocomplete (select2) reports changes through jQuery, not a native event.
    django.jQuery(project).on("change", showProject);
});
