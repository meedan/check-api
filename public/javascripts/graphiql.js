window.addEventListener('graphiql.rendered', function(e) {
  // Add jQuery
  var script = document.createElement('script');
  script.type = 'text/javascript';
  document.getElementsByTagName('HEAD')[0].appendChild(script);
  script.src = '//code.jquery.com/jquery-3.0.0.min.js';
  script.onload = function() { jqueryLoaded(); };

  window.jqueryLoaded = function() {
    script = document.createElement('script');
    script.innerHTML = 'jQuery.noConflict();';
    document.getElementsByTagName('HEAD')[0].appendChild(script);

    // Authenticate with an API key
    var $form   = jQuery('<form action="/graphiql" id="api_key" method="get"></form>'),
        $key    = jQuery('<input name="api_key" placeholder="API Key" value="" />'),
        $button = jQuery('<a class="toolbar-button" title="Set API Key" onclick="document.getElementById(\'api_key\').submit();">Set API Key</a>');
    $form.append($key);
    $form.append($button);
    $form.insertAfter(jQuery('.toolbar-button').last());

    // Insert META tag to avoid CF CAPTCHA.
    jQuery('HEAD').append('<meta name="referrer" content="no-referrer">');
  }
}, false);
