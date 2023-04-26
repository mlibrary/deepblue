//# hyrax-orcid
var hyraxOrcidDashboardOnLoad = function() {
  // Prevent JS being loaded twice
  if ($("body").attr("data-hyrax-orcid-dashboard-js-loaded") === "true") {
    return false
  }

  $("body").on("click", ".js-orcid-sync-work-toggle", function(){
    let attr = $(this).prop("checked") ? "on" : "off"

    $.ajax({
      dataType: "json",
      url: $(this).data(`toggle-${attr}`),
    });
  });

  $("body").attr("data-hyrax-orcid-dashboard-js-loaded", "true")
}

// Ensure that page load (via turbolinks) and page refresh (via browser request) both load JS
$(document).ready(hyraxOrcidDashboardOnLoad)
$(document).on("turbolinks:load", hyraxOrcidDashboardOnLoad)

