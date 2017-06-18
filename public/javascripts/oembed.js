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
  strings[i].innerHTML = translations[locale][strings[i].innerHTML];
}

// Use jquery.timeago for relative timestamps

jQuery.getScript(host + '/javascripts/timeago/locales/jquery.timeago.' + locale + '.js', function() {
  jQuery(document).ready(function() {
    $('time.timeago').timeago();
  });
});

// Use hand cursor only on texts that are really expandable
jQuery(document).ready(function() {
  jQuery('.oembed__verification-task-answer, .oembed__note span').each(function() {
    var element = jQuery(this);
    if (element[0].offsetWidth < element[0].scrollWidth) {
      element.addClass('oembed__clickable');
    }
  });
});

// Expand tasks

jQuery(document).ready(function() {
  jQuery('#oembed__tasks-expand-all').click(function() {
    jQuery('#oembed__verification-tasks .oembed__collapsable-text').removeClass('oembed__collapsed-text');
    jQuery('#oembed__tasks-expand-all').hide();
    jQuery('#oembed__tasks-collapse-all').show();
  });
  jQuery('#oembed__tasks-collapse-all').click(function() {
    jQuery('#oembed__verification-tasks .oembed__collapsable-text').addClass('oembed__collapsed-text');
    jQuery('#oembed__tasks-collapse-all').hide();
    jQuery('#oembed__tasks-expand-all').show();
  });
  jQuery('.oembed__verification-task-answer').click(function() {
    jQuery(this).toggleClass('oembed__collapsed-text');
  });
});

// Expand notes

jQuery(document).ready(function() {
  jQuery('#oembed__notes-expand-all').click(function() {
    jQuery('#oembed__notes .oembed__collapsable-text').removeClass('oembed__collapsed-text');
    jQuery('#oembed__notes-expand-all').hide();
    jQuery('#oembed__notes-collapse-all').show();
  });
  jQuery('#oembed__notes-collapse-all').click(function() {
    jQuery('#oembed__notes .oembed__collapsable-text').addClass('oembed__collapsed-text');
    jQuery('#oembed__notes-collapse-all').hide();
    jQuery('#oembed__notes-expand-all').show();
  });
  jQuery('.oembed__note span').click(function() {
    jQuery(this).toggleClass('oembed__collapsed-text');
  });
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

jQuery(document).ready(function() {
  if (rtlLanguages.indexOf(locale) > -1) {
    jQuery('body, html').addClass('rtl');
    jQuery('.fa-quote-right, .fa-quote-left').toggleClass('fa-quote-right fa-quote-left');
  }
  jQuery('html').attr('lang', locale);
  jQuery('#oembed__meta-content-language').attr('content', locale);
});
