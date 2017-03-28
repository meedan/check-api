jQuery(function(){
  $(document).ready(function() {
    var logoutLink = $("a[href='/api/users/sign_out']")
    if(logoutLink.length > 0) {
      logoutLink.attr("href", "/api/users/sign_out?destination=/")
    }

    $(".settings-example i").click(function() {
      $( this ).siblings("pre").toggleClass("open");
    });
  })
})
