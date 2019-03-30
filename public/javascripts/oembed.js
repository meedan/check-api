// Get the current locale

var locale = navigator.languages || navigator.language || navigator.userLanguage || 'en';
if (locale.constructor === Array) {
  locale = locale[0];
}
locale = locale.replace(/[-_].*$/, '');
if (locales.indexOf(locale) === -1) {
  locale = 'en';
}

// Localize all strings to the current locale

var strings = document.getElementsByClassName('l');
for (var i = 0; i < strings.length; i++) {
  strings[i].innerHTML = translations[locale][strings[i].innerHTML] || '';
}

// Use jquery.timeago for relative timestamps

jQuery.getScript(host + '/javascripts/timeago/locales/jquery.timeago.' + locale + '.js', function() {
  jQuery(document).ready(function() {
    $('time.timeago').timeago();
  });
});

// Use hand cursor only on texts that are really expandable
// and hide "Expand/collapse" if there is nothing truncated

jQuery(document).ready(function() {
  var hasCollapsableText = false;
  jQuery('.oembed__task-answer').each(function() {
    var element = jQuery(this);
    if (element[0].offsetWidth < element[0].scrollWidth) {
      element.addClass('oembed__clickable');
      hasCollapsableText = true;
    }
  });
  if (hasCollapsableText) {
    jQuery('#oembed__tasks-info').show();
  }
  else {
    jQuery('#oembed__tasks-info').hide();
  }
});

// Expand tasks

jQuery(document).ready(function() {
  jQuery('#oembed__tasks-expand-all').click(function() {
    jQuery('.oembed__collapsable-text').removeClass('oembed__collapsed-text');
    jQuery('#oembed__tasks-expand-all').hide();
    jQuery('#oembed__tasks-collapse-all').show();
  });
  jQuery('#oembed__tasks-collapse-all').click(function() {
    jQuery('.oembed__collapsable-text').addClass('oembed__collapsed-text');
    jQuery('#oembed__tasks-collapse-all').hide();
    jQuery('#oembed__tasks-expand-all').show();
  });
  jQuery('.oembed__task-answer').click(function() {
    jQuery(this).toggleClass('oembed__collapsed-text');
  });
});

// Linkify

jQuery(document).ready(function() {
  jQuery('.oembed__linkify').linkify({ target: '_blank' });
});

// Define if language is RTL
// Reference: https://github.com/shadiabuhilal/rtl-detect/blob/master/lib/rtl-detect.js

var rtlLanguages = [
  'ar', /* 'العربية', Arabic */
  'arc', /* Aramaic */
  'bcc', /* 'بلوچی مکرانی', Southern Balochi */
  'bqi', /* 'بختياري', Bakthiari */
  'ckb', /* 'Soranî / کوردی', Sorani */
  'dv', /* Dhivehi */
  'fa', /* 'فارسی', Persian */
  'glk', /* 'گیلکی', Gilaki */
  'he', /* 'עברית', Hebrew */
  'ku', /* 'Kurdî / كوردی', Kurdish */
  'mzn', /* 'مازِرونی', Mazanderani */
  'pnb', /* 'پنجابی', Western Punjabi */
  'ps', /* 'پښتو', Pashto, */
  'sd', /* 'سنڌي', Sindhi */
  'ug', /* 'Uyghurche / ئۇيغۇرچە', Uyghur */
  'ur', /* 'اردو', Urdu */
  'yi', /* 'ייִדיש', Yiddish */
];

var htmlHeight = 0;
var checkHTMLHeight = function() {
  var height = document.getElementsByTagName('HTML')[0].scrollHeight;
  if (height !== htmlHeight) {
    htmlHeight = height;
    // Let the parent document know about the height
    // http://docs.embed.ly/v1.0/docs/provider-height-resizing
    window.parent.postMessage(JSON.stringify({ 
      src: window.location.toString(), 
      context: 'iframe.resize', 
      height: height
    }), '*');
    document.getElementsByTagName('BODY')[0].style.height = height + 'px';
  }
  setTimeout(checkHTMLHeight, 500);
};

jQuery(document).ready(function() {
  if (rtlLanguages.indexOf(locale) > -1) {
    jQuery('body, html').addClass('rtl');
  }
  jQuery('html').attr('lang', locale);
  jQuery('#oembed__meta-content-language').attr('content', locale);
  checkHTMLHeight();
});
