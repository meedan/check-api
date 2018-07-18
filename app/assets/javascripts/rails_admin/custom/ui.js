//= require ./jsoneditor.min.js
//= require rails_admin/themes/material/ui.js

jQuery(function(){
  $(document).ready(function() {
    var logoutLink = $("a[href='/api/users/sign_out']")
    if(logoutLink.length > 0) {
      logoutLink.attr("href", "/api/users/sign_out?destination=/")
    }

    $(".settings-example i").click(function() {
      $( this ).siblings("pre").toggleClass("open");
    });
    $("#team_raw_checklist_field label").click(function(e) {
      e.preventDefault();
      $( this ).siblings('.controls').toggle();
    });
  })
})
