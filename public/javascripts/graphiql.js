window.addEventListener('graphiql.rendered', function(e) {

  // Add jQuery
  var script = document.createElement('script');
  script.type = 'text/javascript';
  document.getElementsByTagName('HEAD')[0].appendChild(script);
  script.src = '//code.jquery.com/jquery-3.0.0.min.js';
  script.onload = function() { jqueryLoaded(); };

  // Social links
  var linkTemplate = '<a href="/api/users/auth/{{provider}}?destination=/graphiql" id="{{provider}}-login" style="margin: 6px; float: left;">' +
                     '<img src="/images/{{provider}}.png" alt="{{provider}}" title="Login with {{provider}}" /></a>',
      twitterLink = linkTemplate.replace(/{{provider}}/g, 'twitter'),
      facebookLink = linkTemplate.replace(/{{provider}}/g, 'facebook'),
      logoutLink = '<a href="/api/users/logout?destination=/graphiql" id="logout-link" class="toolbar-button" style="float: left; margin-top: 9px;">Logout</a>';
  document.getElementsByClassName('toolbar')[0].innerHTML = twitterLink + facebookLink + logoutLink;

  // Check login
  window.jqueryLoaded = function() {
    script = document.createElement('script');
    script.innerHTML = 'jQuery.noConflict();';
    document.getElementsByTagName('HEAD')[0].appendChild(script);

    var s       = 'display: inline-block; border: 1px solid #ccc; padding: 2px; background: #fff; width: 100px; margin-right: 5px;',
        $form   = jQuery('<form action="/api/users/sign_in" method="post" id="cd-form" style="margin-top: 7px; margin-left: 10px; float: left;"></form>'),
        $email  = jQuery('<input name="api_user[email]" placeholder="E-mail" id="cd-email" style="' + s + '" value="" />'),
        $pass   = jQuery('<input name="api_user[password]" type="password" placeholder="Password" id="cd-pw" style="' + s + '" />'),
        $button = jQuery('<button class="toolbar-button">OK</button>');
    $form.append($email);
    $form.append($pass);
    $form.append($button);

    $form.submit(function(event) {
      var formData = { name: jQuery('#cd-email').val(), email: jQuery('#cd-pw').val() };
      jQuery.ajax({
        type: 'POST',
        url: '/api/users/sign_in',
        data: formData,
        dataType: 'json',
        encode: true
      })
      .done(function(data) {
        var message = '';
        if (data && data.type === 'user') {
          message = '<p class="toolbar-button" style="margin-top: 2px;">Logged in as ' + data.data.name + '</p>';
        }
        else {
          message = '<p style="color: #a00; margin-top: 2px;" class="toolbar-button">Could not login</p>';
        }
        jQuery('#cd-form').html(message);
      });
      event.preventDefault();
    });

    $form.insertBefore(jQuery('#logout-link'));
  }
}, false);
