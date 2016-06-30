window.addEventListener('graphiql.rendered', function(e) {
  var linkTemplate = '<a href="/api/users/auth/{{provider}}?destination=/graphiql" id="{{provider}}-login" style="margin: 6px; float: left;">' +
                     '<img src="/images/{{provider}}.png" alt="{{provider}}" title="Login with {{provider}}" /></a>',
      twitterLink = linkTemplate.replace(/{{provider}}/g, 'twitter'),
      facebookLink = linkTemplate.replace(/{{provider}}/g, 'facebook'),
      logoutLink = '<a href="/api/users/logout?destination=/graphiql" class="toolbar-button" style="float: left; margin-top: 9px;">Logout</a>';
  document.getElementsByClassName('toolbar')[0].innerHTML = twitterLink + facebookLink + logoutLink;
}, false);
