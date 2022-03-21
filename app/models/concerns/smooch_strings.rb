
# Please update this file using the script at scripts/convert-smooch-strings-from-airtable.rb
require 'active_support/concern'

module SmoochStrings
  extend ActiveSupport::Concern

  module ClassMethods
    def get_string(key, language)
      string = {
        "add_more_details_state_button_label": {
          "en": "Add more",
          "id": "Tambah lebih banyak",
          "be": "আরও তথ্য যোগ করুন",
          "fr": "En ajouter",
          "de": "Mehr hinzufügen",
          "hi": "अधिक जानकारी जोड़ें",
          "kn": "ಹೆಚ್ಚು ಸೇರಿಸಿ",
          "mr": "अधिक माहिती जोडा",
          "pt": "Adicionar mais",
          "pa": "ਵਧੇਰੀ ਜਾਣਕਾਰੀ ਜੋੜੋ",
          "es": "Añadir más",
          "ta": "கூடுதல் தகவல்ககள்",
          "te": "ఇంకా_చేర్ఛండి",
          "ur": "مزید شامل کریں"
        },
        "ask_if_ready_state_button_label": {
          "en": "Cancel",
          "id": "Batalkan",
          "be": "বাতিল করুন",
          "fr": "Annuler",
          "de": "Abbrechen",
          "hi": "रद्द करें",
          "kn": "ರದ್ದು",
          "mr": "रद्द करा",
          "pt": "Cancelar",
          "pa": "ਰੱਦ ਕਰੋ",
          "es": "Cancelar",
          "ta": "ரத்து செய்",
          "te": "రద్దు",
          "ur": "منسوخ"
        },
        "confirm_preferred_language": {
          "en": "Please confirm your preferred language",
          "id": "Silakan konfirmasi bahasa pilihan Anda",
          "be": "অনুগ্রহ করে আপনার পছন্দেসই ভাষা নিশ্চিত করুন",
          "fr": "Veuillez confirmer votre préférence de langue",
          "de": "Bitte bestätigen Sie Ihre bevorzugte Sprache.",
          "hi": "कृपया अपनी भाषा चुनें",
          "kn": "ನಿಮ್ಮ ಆಯ್ಕೆಯ ಭಾಷೆಯನ್ನು ಖಚಿತಪಡಿಸಿ",
          "mr": "कृपया आपल्या पसंतीच्या भाषेची खात्री करा",
          "pt": "Por favor, confirme seu idioma de preferência",
          "pa": "ਕਿਰਪਾ ਆਪਣੀ ਪਸੰਦ ਦੀ ਭਾਸ਼ਾ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ",
          "es": "Por favor confirma tu idioma de preferencia",
          "ta": "உங்கள் விருப்ப மொழியை உறுதி செய்யவும்",
          "te": "మీరు ఎంచుకున్న భాషను కన్ఫర్మ్ చెయండి",
          "ur": "براہ کرم اپنی پسندیدہ زبان کی تصدیق کریں۔"
        },
        "invalid_format": {
          "en": "Sorry, the file you submitted is not supported format.",
          "id": "Maaf, format berkas yang Anda kirimkan tidak didukung.",
          "be": "দুঃখিত, আপনার জমা দেওয়া ফাইলটি সমর্থিত ফর্মেটে নয়।",
          "fr": "Désolé, le fichier que vous avez envoyé n’est pas à un format en charge.",
          "de": "Verzeihung, dieses Dateiformat wird nicht unterstützt.",
          "hi": "क्षमा करें, आपके द्वारा जमा की गई फाइल समर्थित प्रारूप नहीं है।",
          "kn": "ಕ್ಷಮಿಸಿ, ನೀವು ಸಲ್ಲಿಸಿರುವ ಫೈಲ್ ಫಾರ್ಮ್ಯಾಟ್ ಅನ್ನು ಬೆಂಬಲಿಸಲಾಗುವುದಿಲ್ಲ.",
          "mr": "माफ करा, आपण सबमिट केलेली फाईल समर्थित स्वरुपात नाही.",
          "pt": "Desculpe, o formato do arquivo que você enviou não é compatível.",
          "pa": "ਮੁਆਫ ਕਰੋ, ਤੁਹਾਡੇ ਵੱਲੋਂ ਜਮ੍ਹਾ ਕੀਤੀ ਗਈ ਫਾਈਲ ਸਮਰਥਿਤ ਫਾਰਮੈਟ ਨਹੀਂ ਹੈ।",
          "es": "Lo sentimos, el archivo que has enviado está en un formato no admitido",
          "ta": "மன்னிக்கவும், நீங்கள் சமர்ப்பித்த கோப்பின் வடிவம் ஆதரிக்கப்படவில்லை.",
          "te": "క్షమించండి, మీరు సమర్పించిన ఫైల్ ఫార్మాట్‌కు మద్దతు లేదు.",
          "ur": "معذرت، آپ کی جمع کرائی گئی فائل سپورٹ فارمیٹ نہیں ہے۔"
        },
        "keep_subscription_button_label": {
          "es": "Mantener suscripción",
          "be": "সাবস্ক্রিপশন করে রাখুন",
          "hi": "सबस्क्रिप्शन कायम रखें",
          "kn": "ಚಂದಾದಾರಿಕೆ ಇಟ್ಟುಕೊಳ್ಳಿ",
          "mr": "सबस्क्रिप्शन कायम ठेवा",
          "pt": "Manter inscrição",
          "pa": "ਸਬਸਕ੍ਰਿਪਸ਼ਨ ਕਾਇਮ ਰੱਖੋ",
          "ta": "சந்தாவை தொடர்",
          "te": "చందా ఉంచుకోండి",
          "en": "Keep subscription"
        },
        "languages": {
          "en": "Languages",
          "id": "Bahasa",
          "be": "ভাষাগুলো",
          "fr": "Langues",
          "de": "Sprachen",
          "hi": "भाषाएँ",
          "kn": "ಭಾಷೆಗಳು",
          "mr": "भाषा",
          "pt": "Idiomas",
          "pa": "ਭਾਸ਼ਾਵਾਂ",
          "es": "Idiomas",
          "ta": "மொழிகள்",
          "te": "భాషలు",
          "ur": "زبانیں"
        },
        "languages_and_privacy_title": {
          "en": "Languages and Privacy",
          "id": "Bahasa dan Privasi",
          "be": "ভাষা ও গোপনীয়তা",
          "fr": "Langues, confidentialité",
          "de": "Sprachen und Datenschutz",
          "hi": "भाषाएँ एवं गोपनीयता",
          "kn": "ಭಾಷೆಗಳು ಹಾಗು ಗೌಪ್ಯತೆ",
          "mr": "भाषा आणि गोपनीयता",
          "pt": "Idiomas e privacidade",
          "pa": "ਭਾਸ਼ਾਵਾਂ ਅਤੇ ਗੋਪਨੀਅਤਾ",
          "es": "Idiomas y Privacidad",
          "ta": "மொழிகள் & தனியுரிமை",
          "te": "భాష మరియు గౌప్యత",
          "ur": "زبانیں اور رازداری"
        },
        "main_menu": {
          "en": "Main menu",
          "id": "Menu utama",
          "be": "মুখ্য মেনু",
          "fr": "Menu principal",
          "de": "Hauptmenü",
          "hi": "मेन मेन्यू",
          "kn": "ಮುಖ್ಯ ಮೆನು",
          "mr": "मुख्य मेन्यू",
          "pt": "Menu principal",
          "pa": "ਮੁੱਖ ਮੀਨੂ",
          "es": "Menú principal",
          "ta": "மெயின் மெனு",
          "te": "ప్రధాన మెను",
          "ur": "مین مینو"
        },
        "main_state_button_label": {
          "en": "Cancel",
          "id": "Batalkan",
          "be": "বাতিল করুন",
          "fr": "Annuler",
          "de": "Abbrechen",
          "hi": "रद्द करें",
          "kn": "ರದ್ದು",
          "mr": "रद्द करा",
          "pt": "Cancelar",
          "pa": "ਰੱਦ ਕਰੋ",
          "es": "Cancelar",
          "ta": "ரத்து செய்",
          "te": "రద్దు",
          "ur": "منسوخ"
        },
        "navigation_button": {
          "en": "Use the buttons to navigate",
          "id": "Gunakan tombol untuk mendapatkan navigasi",
          "be": "নেভিগেট করতে বোতামগুলি ব্যবহার করুন",
          "fr": "Utilisez les boutons pour naviguer",
          "de": "Verwenden Sie die Schaltflächen zum Navigieren",
          "hi": "नेविगेट करने के लिए बटनों का उपयोग करें",
          "kn": "ನ್ಯಾವಿಗೇಟ್ ಮಾಡಲು ಬಟನ್‌ಗಳನ್ನು ಬಳಸಿ",
          "mr": "नेव्हिगेट करण्यासाठी बटने वापरा",
          "pt": "Use os botões para navegar",
          "pa": "ਨੈਵੀਗੇਟ ਕਰਨ ਲਈ ਬਟਨਾਂ ਦੀ ਵਰਤੋਂ ਕਰੋ",
          "es": "Usa el menú para ver más opciones",
          "ta": "நேவிகேட் செய்வதற்கு பட்டன்களை பயனபடுதவும்",
          "te": "న్యావిగేట్ చెయడానికి బటన్‍లను వాడండి",
          "ur": "نیویگیٹ کرنے کے لیے بٹنوں کا استعمال کریں۔"
        },
        "privacy_statement": {
          "en": "Privacy statement",
          "id": "Pernyataan privasi",
          "be": "গোপনীয়তা বিবৃতি",
          "fr": "Avis de confidentialité",
          "de": "Datenschutzhinweis",
          "hi": "गोपनीयता कथन",
          "kn": "ಗೌಪ್ಯತಾ ಹೇಳಿಕೆ",
          "mr": "गोपनीयता विधान",
          "pt": "Política de privacidade",
          "pa": "ਪਰਦੇਦਾਰੀ ਕਥਨ",
          "es": "Política de privacidad",
          "ta": "தனியுரிமை அறிக்கை",
          "te": "గౌప్యతా ప్రతిపాదన",
          "ur": "رازداری کا بیان"
        },
        "privacy_title": {
          "en": "Privacy",
          "id": "Privasi",
          "be": "গোপনীয়তা",
          "fr": "Confidentialité",
          "de": "Datenschutz",
          "hi": "गोपनीयता",
          "kn": "ಗೌಪ್ಯತೆ",
          "mr": "गोपनीयता",
          "pt": "Privacidade",
          "pa": "ਗੋਪਨੀਅਤਾ",
          "ta": "தனியுரிமை",
          "te": "గౌప్యత",
          "ur": "رازداری",
          "es": "Privacidad"
        },
        "report_updated": {
          "en": "The following fact-check has been *updated* with new information:",
          "id": "Pengecekan fakta berikut telah *diperbarui* dengan informasi baru:",
          "be": "নিম্নলিখিত ফ্যাক্ট-চেকটি নতুন তথ্যের সাথে *আপডেট* করা হয়েছে:",
          "fr": "La vérification de faits suivante a été *mise à jour* avec de nouveaux renseignements :",
          "de": "Der folgende Faktencheck enthält eine *Aktualisierung*  mit neuen Informationen:",
          "hi": "निम्नलिखित तथ्य-जाँच को नई जानकारी के साथ *अपडेट* किया गया है:",
          "kn": "ಈ ಕೆಳಗಿನ ಫ್ಯಾಕ್ಟ್-ಚೆಕ್ ಅನ್ನು ಹೊಸ ಮಾಹಿತಿಯೊಂದಿಗೆ \"ಅಪ್ಡೇಟ್\" ಮಾಡಲಾಗಿದೆ",
          "mr": "खालील तथ्य-तपासणी नवीन माहितीसोबत *अपडेट* करण्यात आली आहे.",
          "pt": "A verificação de fatos a seguir foi *atualizada* com novas informações:",
          "pa": "ਹੇਠ ਲਿਖੀ ਤੱਥ-ਜਾਂਚ ਨੂੰ ਨਵੀਂ ਜਾਣਕਾਰੀ ਦੇ ਨਾਲ *ਅਪਡੇਟ* ਕੀਤਾ ਗਿਆ ਹੈ:",
          "es": "La siguiente verificación de hechos ha sido *actualizada* con nueva información:",
          "ta": "பின்வரும் தகவல் சரிபார்ப்பு புதிய தகவல்களுடன் *புதுப்பிக்கப்பட்டுள்ளது*.",
          "te": "కింది వాస్తవ తనిఖీ కొత్త సమాచారంతో \"నవీకరించబడింది\"",
          "ur": "درج ذیل حقائق کی جانچ کو نئی معلومات کے ساتھ *اپ ڈیٹ* کر دیا گیا ہے۔"
        },
        "search_result_is_not_relevant_button_label": {
          "en": "No",
          "id": "Tidak",
          "be": "না",
          "fr": "Non",
          "de": "Nein",
          "hi": "नहीं",
          "kn": "ಇಲ್ಲ",
          "mr": "नाही",
          "pt": "Não",
          "pa": "ਨਹੀਂ",
          "es": "No",
          "ta": "இல்லை",
          "te": "లేదు",
          "ur": "نہیں"
        },
        "search_result_is_relevant_button_label": {
          "en": "Yes",
          "id": "Ya",
          "be": "হ্যাঁ",
          "fr": "Oui",
          "de": "Ja",
          "hi": "हाँ",
          "kn": "ಹೌದು",
          "mr": "होय",
          "pt": "Sim",
          "pa": "ਹਾਂ",
          "es": "Si",
          "ta": "ஆம்",
          "te": "అవును",
          "ur": "جی ہاں"
        },
        "search_state_button_label": {
          "en": "Submit",
          "id": "Serahkan",
          "be": "জমা করুন",
          "fr": "Envoyer",
          "de": "Absenden",
          "hi": "जमा करें",
          "kn": "ಸಲ್ಲಿಸಿ",
          "mr": "सबमिट करा",
          "pt": "Enviar",
          "pa": "ਜਮ੍ਹਾ ਕਰੋ",
          "es": "Enviar",
          "ta": "சமர்ப்பி",
          "te": "సమర్పించండి",
          "ur": "جمع کرائیں"
        },
        "subscribe_button_label": {
          "en": "Subscribe",
          "id": "Berlangganan",
          "be": "সাবস্ক্রাইব করুন",
          "fr": "M’abonner",
          "de": "Abonnieren",
          "hi": "सब्स्क्राइब करें",
          "kn": "ಸಬ್‌ಸ್ಕ್ರೈಬ್",
          "mr": "सबस्क्राइब करा",
          "pt": "Inscrever-se",
          "pa": "ਸਬਸਕ੍ਰਾਈਬ ਕਰੋ",
          "es": "Suscribirse",
          "ta": "பதிவு செய்",
          "te": "సబ్‌స్క్రైబ్",
          "ur": "سبسکرائب"
        },
        "subscribed": {
          "en": "You are currently subscribed to our newsletter.",
          "id": "Anda saat ini sedang berlangganan ke buletin kami.",
          "be": "আপনি বর্তমানে আমাদের নিউজলেটারে সাবস্ক্রাইব করেছেন।",
          "fr": "Vous êtes actuellement abonné à notre lettre d’information.",
          "de": "Sie haben unseren Newsletter derzeit abonniert.",
          "hi": "आपने इस समय हमारे न्यूज़लेटर को सब्स्क्राइब किया हुआ है।",
          "kn": "ನೀವು ಈಗ ನಮ್ಮ ನ್ಯೂಸ್ ಲೆಟರ್‌ಗೆ ಸಬ್‌ಸ್ಕ್ರೈಬ್ ಆಗಿರುತ್ತೀರಿ",
          "mr": "आपण सध्या आमचे वृत्तपत्र सबस्क्राइब केले आहे.",
          "pt": "Atualmente, você estás inscrito(a) em nosso boletim informativo.",
          "pa": "ਤੁਸੀਂ ਇਸ ਸਮੇਂ ਸਾਡੇ ਨਿਊਜ਼ਲੈਟਰ ਨੂੰ ਸਬਸਕ੍ਰਾਈਬ ਕੀਤਾ ਹੋਇਆ ਹੈ",
          "es": "Actualmente estás suscrita(o) a nuestro boletín.",
          "ta": "தற்சமயம் நீங்கள் எங்கள் செய்தி மடலைப் பெறுவதற்குப் பதிவு செய்திருக்கிறீர்கள்",
          "te": "మీరు ఇప్పుడు మా వార్తాలేఖకు సభ్యత్వాన్ని పొంది ఉన్నారు.",
          "ur": "آپ فی الحال ہمارے نیوز لیٹر کو سبسکرائب کر چکے ہیں۔"
        },
        "unsubscribe_button_label": {
          "en": "Unsubscribe",
          "id": "Brhenti brlangganan",
          "be": "আনসাবস্ক্রাইব করুন",
          "fr": "Me désabonner",
          "de": "Abbestellen",
          "hi": "अनसब्स्क्राइब करें",
          "kn": "ಅನ್ಸಬ್‌ಸ್ಕ್ರೈಬ್",
          "mr": "अनसबस्क्राइब करा",
          "pt": "Desinscrever-se",
          "pa": "ਅਨਸਬਸਕ੍ਰਾਈਬ ਕਰੋ",
          "es": "Cancelar suscripción",
          "ta": "பதிவை ரத்து செய்",
          "te": "అన్‌సబ్‌స్క్రైబ్",
          "ur": "رکنیت ختم کریں۔"
        },
        "unsubscribed": {
          "en": "You are currently not subscribed to our newsletter.",
          "id": "Saat ini Anda tidak berlangganan buletin kami.",
          "be": "আপনি বর্তমানে আমাদের নিউজলেটার সদস্যতা নেই.",
          "fr": "Vous n’êtes actuellement pas abonné à notre lettre d’information.",
          "de": "Sie haben unseren Newsletter derzeit nicht abonniert.",
          "hi": "आपने वर्तमान में हमारे न्यूज़लेटर की सदस्यता नहीं ली है।",
          "kn": "ನೀವು ಪ್ರಸ್ತುತ ನಮ್ಮ ಸುದ್ದಿಪತ್ರಕ್ಕೆ ಚಂದಾದಾರರಾಗಿಲ್ಲ.",
          "mr": "तुम्ही सध्या आमच्या वृत्तपत्राचे सदस्यत्व घेतलेले नाही.",
          "pt": "Atualmente, você não está inscrito(a) em nosso boletim informativo.",
          "pa": "ਤੁਸੀਂ ਵਰਤਮਾਨ ਵਿੱਚ ਸਾਡੇ ਨਿਊਜ਼ਲੈਟਰ ਦੀ ਗਾਹਕੀ ਨਹੀਂ ਲਈ ਹੈ।",
          "es": "Actualmente no está suscrita(o) a nuestro boletín.",
          "ta": "தற்சமயம் நீங்கள் எங்கள் செய்தி மடலைப் பெறும் வசதியை ரத்து செய்து இருக்கிறீர்கள்",
          "te": "మీరు ప్రస్తుతం మా వార్తాలేఖకు సభ్యత్వం పొందలేదు.",
          "ur": "آپ نے فی الحال ہمارے نیوز لیٹر کو سبسکرائب نہیں کیا ہے۔"
        }
      }[key.to_sym]
      language = language.gsub(/[-_].*$/, '').to_sym
      string ? (string[language] || string[:en]) : string
    end
  end
end
