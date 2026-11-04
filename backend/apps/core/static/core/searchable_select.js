// Turns every select marked with the class "searchable-select" into a select2 box with a
// search field. The select inside the admin's "empty form" template of an inline is skipped
// and set up when the row is added.
(function () {
  "use strict";
  const $ = django.jQuery;

  function setUp(root) {
    $(root)
      .find("select.searchable-select")
      .not("[name*='__prefix__']")
      .each(function () {
        if (!$(this).data("select2")) {
          $(this).select2({ width: "20em" });
        }
      });
  }

  $(function () {
    setUp(document);
  });
  $(document).on("formset:added", function (event) {
    setUp(event.target);
  });
})();
