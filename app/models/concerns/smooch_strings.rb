
# Please update this file using the script at scripts/convert-smooch-strings-from-airtable.rb
require 'active_support/concern'

module SmoochStrings
  extend ActiveSupport::Concern

  module ClassMethods
    def get_string(key, language)
      string = {
        "privacy_statement": {
          "en": "Privacy statement",
          "pt": "Política de privacidade"
        },
        "languages": {
          "en": "Languages",
          "pt": "Idiomas"
        },
        "languages_and_privacy_title": {
          "en": "Languages and Privacy",
          "pt": "Idiomas e Privacidade"
        },
        "add_more_details_state_button_label": {
          "en": "Add more",
          "id": "Tambah lebih banyak",
          "be": "আরও তথ্য যোগ করুন",
          "de": "Mehr hinzufügen",
          "es": "Añadir más ",
          "pt": "Adicionar mais",
          "ur": "مزید معلومات شامل کریں"
        },
        "main_menu": {
          "en": "Main menu",
          "id": "Menu utama",
          "be": "মুখ্য মেনু",
          "fr": "Menu principal",
          "de": "Hauptmenü",
          "hi": "मुख्य मेन्यू",
          "kn": "ಮೆನುವಿಗೆ_ಮರಳಿ_ಬಟನ್",
          "mr": "मुख्य मेन्यू",
          "pt": "Menu principal",
          "pa": "ਮੁੱਖ ਮੀਨੂ",
          "es": "Menú principal",
          "ta": "மெயின் மெனு",
          "te": "మెనుకి_వెళ్ళండి_బటన్",
          "ur": "مین مینو"
        },
        "main_state_button_label": {
          "en": "Cancel",
          "id": "Batalkan",
          "be": "বাতিল করুন",
          "fr": "Annuler",
          "de": "Abbrechen",
          "hi": "रद्द करें\n",
          "kn": "ರದ್ದು_ಬಟನ್",
          "mr": "रद्द करा",
          "pt": "Cancelar",
          "pa": "ਰੱਦ ਕਰੋ\n",
          "es": "Cancelar",
          "ta": "ரத்து செய்",
          "te": "రద్దు_బటన్",
          "ur": "منسوخ"
        },
        "invalid_format": {
          "en": "Sorry, the file you submitted is not supported format. "
        },
        "confirm_preferred_language": {
          "en": "Please confirm your preferred language",
          "id": "Silakan konfirmasi bahasa pilihan Anda",
          "be": "অনুগ্রহ করে আপনার পছন্দেসই ভাষা নিশ্চিত করুন",
          "fr": "Veuillez confirmer votre préférence de langue",
          "de": "Bitte bestätigen Sie Ihre bevorzugte Sprache.",
          "hi": "कृपया अपनी पसंद की भाषा की पुष्टि करें",
          "kn": "ಭಾಷೆ_ದೃಢೀಕರಣ",
          "mr": "कृपया आपल्या पसंतीच्या भाषेची खात्री करा",
          "pt": "Por favor, confirme seu idioma de preferência",
          "pa": "ਕਿਰਪਾ ਆਪਣੀ ਪਸੰਦ ਦੀ ਭਾਸ਼ਾ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ",
          "es": "Por favor confirma tu idioma de preferencia",
          "ta": "உங்கள் விருப்ப மொழியை உறுதி செய்யவும்",
          "te": "భాష_నిర్ధారణ",
          "ur": "براہ کرم اپنی پسندیدہ زبان کی تصدیق کریں۔"
        },
        "search_result_is_not_relevant_button_label": {
          "en": "No",
          "id": "Tidak",
          "be": "না",
          "fr": "Non",
          "de": "Nein",
          "hi": "नहीं",
          "kn": "ಇಲ್ಲ_ಬಟನ್",
          "mr": "नाही",
          "pt": "Não",
          "pa": "ਨਹੀਂ\n",
          "es": "No",
          "ta": "இல்லை",
          "te": "లేదు_బటన్",
          "ur": "نہیں"
        },
        "option_not_available": {
          "en": "I'm sorry, I didn't understand your message."
        },
        "report_updated": {
          "en": "The following fact-check has been *updated* with new information:"
        },
        "search_state_button_label": {
          "en": "Submit ",
          "id": "Serahkan",
          "be": "জমা করুন",
          "fr": "Envoyer",
          "de": "Absenden",
          "hi": "जमा करें",
          "kn": "ಸಬ್ಮಿಟ್_ಬಟನ್",
          "mr": "सबमिट करा",
          "pt": "Enviar",
          "pa": "ਜਮ੍ਹਾ ਕਰੋ\n",
          "es": "Enviar",
          "ta": "சமர்ப்பி",
          "te": "సబ్మిట్-బటన్",
          "ur": "جمع کرائیں"
        },
        "subscribe_button_label": {
          "en": "Subscribe",
          "id": "Berlangganan",
          "be": "সাবস্ক্রাইব করুন",
          "fr": "M’abonner",
          "de": "Abonnieren",
          "hi": "सब्स्क्राइब करें",
          "kn": "ಸಬ್‌ಸ್ಕ್ರೈಬ್_ಬಟನ್",
          "mr": "सबस्क्राइब करा",
          "pt": "Inscrever-se",
          "pa": "ਸਬਸਕ੍ਰਾਈਬ ਕਰੋ",
          "es": "Suscribirse",
          "ta": "பதிவு செய்",
          "te": "సబ్‌స్క్రైబ్_బటన్",
          "ur": "سبسکرائب"
        },
        "unsubscribed": {
          "en": "You are currently unsubscribed to our newsletter.",
          "id": "Anda saat ini sedang tidak berlangganan ke buletin kami.",
          "be": "আপনি বর্তমানে আমাদের নিউজলেটারে আনসাবস্ক্রাইব করেছেন।",
          "fr": "Vous n'êtes actuellement pas abonné(e) à notre newsletter.",
          "de": "Sie haben unseren Newsletter derzeit nicht abonniert.",
          "hi": "आपने इस समय हमारे न्यूज़लेटर को अनसब्स्क्राइब किया हुआ है।\n",
          "kn": "ಸಬ್‍ಸ್ಕ್ರಿಪ್ಷನ್_ಸ್ಟೆಟಸ್_ನೆಗೆಟೀವ್",
          "mr": "आपण सध्या आमचे वृत्तपत्र सबस्क्राइब केले नाही",
          "pt": "Atualmente, você não está inscrito(a) em nosso boletim informativo.",
          "pa": "ਤੁਸੀਂ ਇਸ ਸਮੇਂ ਸਾਡੇ ਨਿਊਜ਼ਲੈਟਰ ਨੂੰ ਅਨਸਬਸਕ੍ਰਾਈਬ ਕੀਤਾ ਹੋਇਆ ਹੈ",
          "es": "Actualmente no estás suscrita(o) a nuestro boletín.",
          "ta": "தற்சமயம் நீங்கள் எங்கள் செய்தி மடலைப் பெறும் வசதியை ரத்து செய்து இருக்கிறீர்கள் ",
          "te": "సబ్‌స్క్రిప్షన్_స్టేటస్_వ్యతిరేకం",
          "ur": "آپ فی الحال ہمارے نیوز لیٹر کی رکنیت ختم کر چکے ہیں۔"
        },
        "subscribed": {
          "en": "You are currently subscribed to our newsletter.",
          "id": "Anda saat ini sedang berlangganan ke buletin kami.",
          "be": "আপনি বর্তমানে আমাদের নিউজলেটারে সাবস্ক্রাইব করেছেন।",
          "fr": "Vous êtes actuellement abonné(e) à notre newsletter.",
          "de": "Sie haben unseren Newsletter derzeit abonniert.",
          "hi": "आपने इस समय हमारे न्यूज़लेटर को सब्स्क्राइब किया हुआ है।\n",
          "kn": "ಸಬ್‌ಸ್ಕ್ರಿಪ್ಷನ್_ಸ್ಟೇಟಸ್_ಧನಾತ್ಮಕ",
          "mr": "आपण सध्या आमचे वृत्तपत्र सबस्क्राइब केले आहे.",
          "pt": "Atualmente, você está inscrito(a) em nosso boletim informativo.",
          "pa": "ਤੁਸੀਂ ਇਸ ਸਮੇਂ ਸਾਡੇ ਨਿਊਜ਼ਲੈਟਰ ਨੂੰ ਸਬਸਕ੍ਰਾਈਬ ਕੀਤਾ ਹੋਇਆ ਹੈ",
          "es": "Actualmente estás suscrita(o) a nuestro boletín.",
          "ta": "தற்சமயம் நீங்கள் எங்கள் செய்தி மடலைப் பெறுவதற்குப் பதிவு செய்திருக்கிறீர்கள்",
          "te": "సబ్‌స్క్రిప్షన్_స్టేటస్_ధనాత్మకం",
          "ur": "آپ فی الحال ہمارے نیوز لیٹر کو سبسکرائب کر چکے ہیں۔"
        },
        "unsubscribe_button_label": {
          "en": "Unsubscribe",
          "id": "Brhenti brlangganan",
          "be": "আনসাবস্ক্রাইব করুন",
          "fr": "Me désabonner",
          "de": "Abbestellen",
          "hi": "अनसब्स्क्राइब करें",
          "kn": "ಅನ್ಸಬ್‌ಸ್ಕ್ರೈಬ್_ಬಟನ್",
          "mr": "अनसबस्क्राइब करा",
          "pt": "Desinscrever-se",
          "pa": "ਅਨਸਬਸਕ੍ਰਾਈਬ ਕਰੋ\n",
          "es": "Cancelar suscripción",
          "ta": "பதிவை ரத்து செய்",
          "ur": "رکنیت ختم کریں۔"
        },
        "search_result_is_relevant_button_label": {
          "en": "Yes",
          "id": "Ya",
          "be": "হ্যাঁ",
          "fr": "Oui",
          "de": "Ja",
          "hi": "हाँ",
          "kn": "ಹೌದು_ಬಟನ್",
          "mr": "होय",
          "pt": "Sim",
          "pa": "ਹਾਂ",
          "es": "Si",
          "ta": "ஆம் ",
          "te": "అవును_బటన్",
          "ur": "جی ہاں"
        }
      }[key.to_sym]
      language = language.gsub(/[-_].*$/, '').to_sym
      string ? (string[language] || string[:en]) : string
    end
  end
end
