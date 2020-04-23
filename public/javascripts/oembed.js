// Get the current locale

var locale = navigator.languages || navigator.language || navigator.userLanguage || 'en';
if (locale.constructor === Array) {
  locale = locale[0];
}
locale = locale.replace(/[-_].*$/, '');
if (locales.indexOf(locale) === -1) {
  locale = 'en';
}

// Linkify

jQuery(document).ready(function() {
  jQuery('.linkify').linkify({ target: '_blank' });
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
  checkHTMLHeight();
});
