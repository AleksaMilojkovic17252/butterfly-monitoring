// Change reason dialog for HistoryAdmin change forms (T018).
// Saving an edited object first opens the dialog; "Save" in the dialog submits the form with
// the button the admin originally clicked (Save / Save and continue / Save and add another).
"use strict";
{
    const dialog = document.getElementById("change-reason-dialog");
    const form = dialog && dialog.closest("form");

    if (form) {
        let submitter = null;
        let confirmed = false;

        form.addEventListener("submit", (event) => {
            if (confirmed) {
                return; // second pass, after the dialog: let the form submit
            }
            event.preventDefault();
            submitter = event.submitter;
            dialog.showModal();
            dialog.querySelector("textarea").focus();
        });

        dialog.querySelector("[data-action=save]").addEventListener("click", () => {
            confirmed = true;
            dialog.close();
            form.requestSubmit(submitter);
        });

        dialog.querySelector("[data-action=cancel]").addEventListener("click", () => {
            dialog.close();
        });
    }
}
